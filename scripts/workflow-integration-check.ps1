param(
    [Parameter(Mandatory = $true)]
    [string[]]$Branches,

    [string]$BaseBranch = 'main',

    [string]$IntegrationBranch = 'integration/workflow-check',

    [string]$GateCommand = 'powershell -ExecutionPolicy Bypass -File scripts\\validate.ps1'
)

$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
Push-Location $root
try {
    git rev-parse --is-inside-work-tree | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Not a Git repository.' }

    git checkout $BaseBranch
    if ($LASTEXITCODE -ne 0) { throw "Failed to checkout base branch $BaseBranch" }

    $existing = git branch --list $IntegrationBranch
    if ($existing) {
        throw "Integration branch already exists: $IntegrationBranch. Rename it or delete it intentionally."
    }

    git checkout -b $IntegrationBranch
    if ($LASTEXITCODE -ne 0) { throw "Failed to create integration branch $IntegrationBranch" }

    foreach ($branch in $Branches) {
        Write-Host "MERGE $branch"
        git merge --no-ff $branch -m "Merge $branch into $IntegrationBranch"
        if ($LASTEXITCODE -ne 0) {
            git status --short
            throw "Merge conflict or merge failure while merging $branch"
        }
    }

    Write-Host 'RUN GATE'
    Invoke-Expression $GateCommand
    if ($LASTEXITCODE -ne 0) { throw "Gate failed: $GateCommand" }

    git status --short --branch
    Write-Host 'WORKFLOW_INTEGRATION_CHECK_OK'
} finally {
    Pop-Location
}

