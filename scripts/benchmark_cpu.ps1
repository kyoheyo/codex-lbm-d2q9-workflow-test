#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Fail-closed CPU LBM benchmark harness.

.DESCRIPTION
    Compares baseline and candidate CPU executables for performance and numerical correctness.
    Requires both executables to produce identical CSV output and LBM_VALIDATION_OK.
    Exits with code 1 on any failure.

.PARAMETER BaselineExe
    Path to the baseline executable.

.PARAMETER CandidateExe
    Path to the candidate executable.

.PARAMETER Iterations
    Number of LBM iterations to run (default: 600).

.PARAMETER WarmupRuns
    Number of warmup runs before timing (default: 1).

.PARAMETER MeasuredRuns
    Number of timed runs used to compute median wall time (default: 7).

.PARAMETER MinimumImprovementPercent
    Minimum required performance improvement (default: 3.0).

.PARAMETER NumericTolerance
    Maximum allowed absolute difference between corresponding rho/ux/uy values (default: 1e-12).
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({Test-Path -LiteralPath $_ -PathType Leaf})]
    [string]$BaselineExe,

    [Parameter(Mandatory)]
    [ValidateScript({Test-Path -LiteralPath $_ -PathType Leaf})]
    [string]$CandidateExe,

    [Parameter()]
    [ValidateRange(1, [int]::MaxValue)]
    [int]$Iterations = 600,

    [Parameter()]
    [ValidateRange(0, [int]::MaxValue)]
    [int]$WarmupRuns = 1,

    [Parameter()]
    [ValidateRange(1, [int]::MaxValue)]
    [int]$MeasuredRuns = 7,

    [Parameter()]
    [ValidateRange(0.0, [double]::MaxValue)]
    [double]$MinimumImprovementPercent = 3.0,

    [Parameter()]
    [ValidateRange(0.0, [double]::MaxValue)]
    [double]$NumericTolerance = 1e-12
)

$ErrorActionPreference = 'Stop'

function Get-Median {
    param([double[]]$Values)
    if ($Values.Count -eq 0) { throw "Empty array" }
    $sorted = $Values | Sort-Object
    $mid = [Math]::Floor($sorted.Count / 2)
    if ($sorted.Count % 2 -eq 0) {
        return ($sorted[$mid - 1] + $sorted[$mid]) / 2.0
    } else {
        return $sorted[$mid]
    }
}

function Invoke-Executable {
    param(
        [string]$ExePath,
        [string]$WorkingDir,
        [int]$Iters,
        [int]$RunNumber
    )

    $outDir = Join-Path $WorkingDir "out"
    if (Test-Path -LiteralPath $outDir) {
        Remove-Item -Recurse -Force -LiteralPath $outDir
    }
    New-Item -ItemType Directory -Path $outDir | Out-Null

    $csvPath = Join-Path $outDir "cylinder_wake.csv"
    $logPath = Join-Path $WorkingDir "run_${RunNumber}.log"

    # Use System.Diagnostics.Process for precise timing without console overhead
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo.FileName = $ExePath
    $process.StartInfo.Arguments = "$Iters"
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.CreateNoWindow = $true
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.RedirectStandardError = $true
    $process.StartInfo.WorkingDirectory = $WorkingDir

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $process.Start() | Out-Null
    $process.WaitForExit()
    $stopwatch.Stop()

    $exitCode = $process.ExitCode
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $logContent = $stdout + $stderr

    # Save captured output to log file after timing stops
    Set-Content -LiteralPath $logPath -Value $logContent

    # Parse console output for density, mass, velocity
    # Exact patterns: "Density range: [min, max]", "Mass: value", "Sample velocity (center): (ux, uy)"
    $densityMatch = $logContent | Select-String -Pattern "Density range:\s*\[([\d.eE+-]+),\s*([\d.eE+-]+)\]" | ForEach-Object { $_.Matches.Groups[1].Value, $_.Matches.Groups[2].Value }
    $massMatch = $logContent | Select-String -Pattern "Mass:\s*([\d.eE+-]+)" | ForEach-Object { $_.Matches.Groups[1].Value }
    $velMatch = $logContent | Select-String -Pattern "Sample velocity \(center\):\s*\(([\d.eE+-]+),\s*([\d.eE+-]+)\)" | ForEach-Object { $_.Matches.Groups[1].Value, $_.Matches.Groups[2].Value }

    [PSCustomObject]@{
        ExitCode = $exitCode
        WallTimeMs = $stopwatch.Elapsed.TotalMilliseconds
        LogContent = $logContent
        DensityMin = if ($densityMatch) { [double]$densityMatch[0] } else { $null }
        DensityMax = if ($densityMatch) { [double]$densityMatch[1] } else { $null }
        Mass = if ($massMatch) { [double]$massMatch[0] } else { $null }
        SampleUx = if ($velMatch) { [double]$velMatch[0] } else { $null }
        SampleUy = if ($velMatch) { [double]$velMatch[1] } else { $null }
        CsvPath = $csvPath
    }
}

function Compare-NumericArrays {
    param(
        [double[]]$A,
        [double[]]$B,
        [double]$Tolerance
    )
    if ($A.Length -ne $B.Length) { return $false }
    for ($i = 0; $i -lt $A.Length; $i++) {
        if ([Math]::Abs($A[$i] - $B[$i]) -gt $Tolerance) {
            return $false
        }
    }
    return $true
}

# Validate executables exist and are readable
if (-not (Test-Path -LiteralPath $BaselineExe -PathType Leaf)) {
    Write-Error "Baseline executable not found: $BaselineExe"
    exit 1
}
if (-not (Test-Path -LiteralPath $CandidateExe -PathType Leaf)) {
    Write-Error "Candidate executable not found: $CandidateExe"
    exit 1
}

# Ensure executables are readable
try {
    Get-Content -LiteralPath $BaselineExe -TotalCount 1 | Out-Null
} catch {
    Write-Error "Baseline executable not readable: $BaselineExe"
    exit 1
}
try {
    Get-Content -LiteralPath $CandidateExe -TotalCount 1 | Out-Null
} catch {
    Write-Error "Candidate executable not readable: $CandidateExe"
    exit 1
}

# Create isolated working directories
$baselineWorkDir = Join-Path $PWD "baseline_work_$(Get-Random)"
$candidateWorkDir = Join-Path $PWD "candidate_work_$(Get-Random)"

try {
    New-Item -ItemType Directory -Path $baselineWorkDir | Out-Null
    New-Item -ItemType Directory -Path $candidateWorkDir | Out-Null

    # Warmup runs
    for ($i = 0; $i -lt $WarmupRuns; $i++) {
        Write-Verbose "Baseline warmup run $i"
        $baselineWarmup = Invoke-Executable -ExePath $BaselineExe -WorkingDir $baselineWorkDir -Iters $Iterations -RunNumber $i
        if ($baselineWarmup.ExitCode -ne 0 -or $baselineWarmup.LogContent -notmatch "LBM_VALIDATION_OK") {
            Write-Error "Baseline warmup run $i failed: exit code $($baselineWarmup.ExitCode), missing LBM_VALIDATION_OK"
            exit 1
        }

        Write-Verbose "Candidate warmup run $i"
        $candidateWarmup = Invoke-Executable -ExePath $CandidateExe -WorkingDir $candidateWorkDir -Iters $Iterations -RunNumber $i
        if ($candidateWarmup.ExitCode -ne 0 -or $candidateWarmup.LogContent -notmatch "LBM_VALIDATION_OK") {
            Write-Error "Candidate warmup run $i failed: exit code $($candidateWarmup.ExitCode), missing LBM_VALIDATION_OK"
            exit 1
        }
    }

    # Measured runs
    $baselineTimes = @()
    $candidateTimes = @()

    for ($i = 0; $i -lt $MeasuredRuns; $i++) {
        Write-Verbose "Baseline measured run $i"
        $baselineRun = Invoke-Executable -ExePath $BaselineExe -WorkingDir $baselineWorkDir -Iters $Iterations -RunNumber $i
        if ($baselineRun.ExitCode -ne 0 -or $baselineRun.LogContent -notmatch "LBM_VALIDATION_OK") {
            Write-Error "Baseline measured run $i failed: exit code $($baselineRun.ExitCode), missing LBM_VALIDATION_OK"
            exit 1
        }
        $baselineTimes += $baselineRun.WallTimeMs

        Write-Verbose "Candidate measured run $i"
        $candidateRun = Invoke-Executable -ExePath $CandidateExe -WorkingDir $candidateWorkDir -Iters $Iterations -RunNumber $i
        if ($candidateRun.ExitCode -ne 0 -or $candidateRun.LogContent -notmatch "LBM_VALIDATION_OK") {
            Write-Error "Candidate measured run $i failed: exit code $($candidateRun.ExitCode), missing LBM_VALIDATION_OK"
            exit 1
        }
        $candidateTimes += $candidateRun.WallTimeMs
    }

    # Compute medians
    $baselineMedian = Get-Median -Values $baselineTimes
    $candidateMedian = Get-Median -Values $candidateTimes

    # Calculate improvement
    $improvement = ($baselineMedian - $candidateMedian) / $baselineMedian * 100

    # Load and compare CSV files
    if (-not (Test-Path -LiteralPath $baselineRun.CsvPath)) {
        Write-Error "Baseline CSV not generated: $($baselineRun.CsvPath)"
        exit 1
    }
    if (-not (Test-Path -LiteralPath $candidateRun.CsvPath)) {
        Write-Error "Candidate CSV not generated: $($candidateRun.CsvPath)"
        exit 1
    }

    $baselineCsv = Import-Csv -LiteralPath $baselineRun.CsvPath
    $candidateCsv = Import-Csv -LiteralPath $candidateRun.CsvPath

    if ($baselineCsv.Count -ne $candidateCsv.Count) {
        Write-Error "CSV row count mismatch: baseline $($baselineCsv.Count), candidate $($candidateCsv.Count)"
        exit 1
    }

    # Extract columns
    $baselineRho = $baselineCsv | ForEach-Object { [double]$_.rho }
    $baselineUx = $baselineCsv | ForEach-Object { [double]$_.ux }
    $baselineUy = $baselineCsv | ForEach-Object { [double]$_.uy }

    $candidateRho = $candidateCsv | ForEach-Object { [double]$_.rho }
    $candidateUx = $candidateCsv | ForEach-Object { [double]$_.ux }
    $candidateUy = $candidateCsv | ForEach-Object { [double]$_.uy }

    if (-not (Compare-NumericArrays -A $baselineRho -B $candidateRho -Tolerance $NumericTolerance)) {
        Write-Error "rho CSV comparison failed"
        exit 1
    }
    if (-not (Compare-NumericArrays -A $baselineUx -B $candidateUx -Tolerance $NumericTolerance)) {
        Write-Error "ux CSV comparison failed"
        exit 1
    }
    if (-not (Compare-NumericArrays -A $baselineUy -B $candidateUy -Tolerance $NumericTolerance)) {
        Write-Error "uy CSV comparison failed"
        exit 1
    }

    # Final check: same density/mass/velocity
    if ($null -eq $baselineRun.DensityMin -or $null -eq $candidateRun.DensityMin -or
        [Math]::Abs($baselineRun.DensityMin - $candidateRun.DensityMin) -gt $NumericTolerance -or
        [Math]::Abs($baselineRun.DensityMax - $candidateRun.DensityMax) -gt $NumericTolerance -or
        [Math]::Abs($baselineRun.Mass - $candidateRun.Mass) -gt $NumericTolerance -or
        $null -eq $baselineRun.SampleUx -or $null -eq $candidateRun.SampleUx -or
        [Math]::Abs($baselineRun.SampleUx - $candidateRun.SampleUx) -gt $NumericTolerance -or
        $null -eq $baselineRun.SampleUy -or $null -eq $candidateRun.SampleUy -or
        [Math]::Abs($baselineRun.SampleUy - $candidateRun.SampleUy) -gt $NumericTolerance) {
        Write-Error "Console output numeric mismatch"
        exit 1
    }

    # Check improvement threshold
    if ($improvement -lt $MinimumImprovementPercent) {
        Write-Error "Insufficient performance improvement: $improvement% < $($MinimumImprovementPercent)%"
        exit 1
    }

    # Success
    Write-Host "Baseline median wall time: $baselineMedian ms"
    Write-Host "Candidate median wall time: $candidateMedian ms"
    Write-Host "Performance improvement: ${improvement}%"
    Write-Host "Numerical correctness: PASS"
    Write-Host "LBM_BENCHMARK_OK"

} finally {
    # Cleanup
    if (Test-Path -LiteralPath $baselineWorkDir) { Remove-Item -Recurse -Force -LiteralPath $baselineWorkDir }
    if (Test-Path -LiteralPath $candidateWorkDir) { Remove-Item -Recurse -Force -LiteralPath $candidateWorkDir }
}