param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$PromptArgs
)

$ErrorActionPreference = 'Stop'

$workspace = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$configFile = Join-Path $workspace 'config\builders.yml'
$apiKeyFile = 'C:\Users\1\Desktop\api.txt'
function Get-ApiKeys {
  param([Parameter(Mandatory = $true)] [string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    throw "API key file not found: $Path"
  }

  $keys = @()
  $lines = Get-Content -LiteralPath $Path
  foreach ($line in $lines) {
    $candidate = $line.Trim().Trim('"').Trim("'")
    if (-not $candidate -or $candidate -match '^#') { continue }
    if ($candidate -match '[：:]$') { continue }
    if ($candidate -match '^(sk-|[A-Za-z0-9_-]{32,})') {
      $keys += $candidate
    }
  }
  return $keys
}

function Get-BuilderConfig {
  param(
    [Parameter(Mandatory = $true)] [string]$Path,
    [Parameter(Mandatory = $true)] [string]$BuilderId
  )
  if (-not (Test-Path -LiteralPath $Path)) {
    throw "Builder config file not found: $Path"
  }

  $lines = Get-Content -LiteralPath $Path
  $inBuilder = $false
  $inEnv = $false
  $result = @{
    env = @{}
  }

  foreach ($rawLine in $lines) {
    $line = $rawLine.TrimEnd()
    if ($line -match '^  ([A-Za-z0-9_-]+):\s*$') {
      $inBuilder = ($Matches[1] -eq $BuilderId)
      $inEnv = $false
      continue
    }

    if (-not $inBuilder) { continue }
    if ($line -match '^  [A-Za-z0-9_-]+:\s*$') { break }

    $trim = $line.Trim()
    if (-not $trim -or $trim -match '^#') { continue }

    if ($trim -eq 'env:') {
      $inEnv = $true
      continue
    }

    if ($inEnv -and $line -match '^\s{6}([A-Za-z0-9_]+):\s*(.+?)\s*$') {
      $result.env[$Matches[1]] = $Matches[2].Trim().Trim('"').Trim("'")
      continue
    }

    if ($line -match '^\s{4}([A-Za-z0-9_]+):\s*(.+?)\s*$') {
      $inEnv = $false
      $key = $Matches[1]
      $value = $Matches[2].Trim().Trim('"').Trim("'")
      $result[$key] = $value
    }
  }

  if (-not $result.ContainsKey('key_index')) {
    throw "Missing key_index for builder $BuilderId in $Path"
  }
  if (-not $result.ContainsKey('base_url')) {
    throw "Missing base_url for builder $BuilderId in $Path"
  }
  if (-not $result.ContainsKey('model')) {
    throw "Missing model for builder $BuilderId in $Path"
  }

  return $result
}
$config = Get-BuilderConfig -Path $configFile -BuilderId 'codex-builder'
$keys = Get-ApiKeys -Path $apiKeyFile
$keyIndex = [int]$config.key_index
if ($keys.Count -le $keyIndex) {
  throw "Missing API key index $keyIndex for codex-builder in $apiKeyFile"
}

$env:CODEX_HOME = $config.codex_home
$env:BOTCF_API_KEY = $keys[$keyIndex]

$prompt = ($PromptArgs -join ' ')
if (-not $prompt) {
  $prompt = 'Read AGENTS.md and respond with OK.'
}

& codex exec --skip-git-repo-check --dangerously-bypass-approvals-and-sandbox --model $config.model --cd $workspace $prompt
