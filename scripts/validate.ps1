# PowerShell validation script for LBM workflow
# Cross-platform: Windows and Linux (via PowerShell Core)

$ErrorActionPreference = "Stop"

# Resolve repo root
$repoRoot = Split-Path -Parent $PSScriptRoot

# Create build and out directories
if (-not (Test-Path "$repoRoot/build")) {
    New-Item -ItemType Directory -Path "$repoRoot/build" | Out-Null
}
if (-not (Test-Path "$repoRoot/out")) {
    New-Item -ItemType Directory -Path "$repoRoot/out" | Out-Null
}

# --- Compiler detection ---
$gpp = Get-Command g++ -ErrorAction SilentlyContinue
if (-not $gpp) {
    Write-Error "g++ not found. Please install g++ or add to PATH."
    exit 1
}

# Check for nvcc regardless of OS (CUDA may be available on other platforms)
$nvcc = Get-Command nvcc -ErrorAction SilentlyContinue
$useCuda = $false
if ($nvcc) {
    $useCuda = $true
}

# --- Build tests ---
echo "Building unit tests..."
& $gpp -std=c++17 -O2 -I"$repoRoot/src" "$repoRoot/tests/lbm_tests.cpp" "$repoRoot/src/lbm_cpu.cpp" -o "$repoRoot/build/lbm_tests.exe"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# --- Run tests ---
echo "Running unit tests..."
& "$repoRoot/build/lbm_tests.exe"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# --- Build main executable ---
echo "Building main executable..."
if ($useCuda) {
    & $nvcc -std=c++17 -O2 -I"$repoRoot/src" -DLBM_WITH_CUDA "$repoRoot/src/main.cpp" "$repoRoot/src/lbm_cpu.cpp" "$repoRoot/src/lbm_cuda.cu" -o "$repoRoot/build/main.exe"
} else {
    & $gpp -std=c++17 -O2 -I"$repoRoot/src" "$repoRoot/src/main.cpp" "$repoRoot/src/lbm_cpu.cpp" -o "$repoRoot/build/main.exe"
}
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# --- Run simulation ---
echo "Running LBM simulation..."
& "$repoRoot/build/main.exe" 180
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# --- Validate CSV output ---
echo "Validating CSV output..."
if (-not (Test-Path "$repoRoot/out/cylinder_wake.csv")) {
    Write-Error "$repoRoot/out/cylinder_wake.csv not generated."
    exit 1
}

$content = Get-Content "$repoRoot/out/cylinder_wake.csv"
if ($content.Count -lt 2) {
    Write-Error "$repoRoot/out/cylinder_wake.csv is empty or malformed."
    exit 1
}

# Ensure both LBM_TESTS_OK and LBM_VALIDATION_OK are printed
Write-Host "LBM_TESTS_OK" -ForegroundColor Green
Write-Host "LBM_VALIDATION_OK" -ForegroundColor Green