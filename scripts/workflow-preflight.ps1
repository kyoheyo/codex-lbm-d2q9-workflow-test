$ErrorActionPreference = 'Stop'

$root = Resolve-Path (Join-Path $PSScriptRoot '..')
Push-Location $root
try {
    git rev-parse --is-inside-work-tree | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Not a Git repository. Run git init and create a baseline commit before Workflow Mode dispatch.' }

    $head = git rev-parse --verify HEAD 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $head) { throw 'No baseline commit found. Commit workflow planning files before builder dispatch.' }

    $status = git status --porcelain
    if ($status) {
        Write-Host 'WARN: worktree has uncommitted changes. Commit or intentionally isolate them before dispatch.'
        $status
    }

    $required = @(
        'AGENTS.md',
        '.codex-agent-workflow.yml',
        'config/builders.yml',
        'docs/gates',
        'docs/lanes',
        'scripts/builders'
    )
    foreach ($path in $required) {
        if (-not (Test-Path -LiteralPath (Join-Path $root $path))) {
            throw "Missing workflow path: $path"
        }
    }

    $builders = @(
        'scripts/builders/claude-deepseek-builder.ps1',
        'scripts/builders/bailian-opencode-builder.ps1',
        'scripts/builders/codex-botcf-builder.ps1'
    )
    foreach ($builder in $builders) {
        $path = Join-Path $root $builder
        if (Test-Path -LiteralPath $path) {
            Write-Host "OK builder wrapper: $builder"
        } else {
            Write-Host "WARN missing builder wrapper: $builder"
        }
    }

    git worktree list
    Write-Host 'WORKFLOW_PREFLIGHT_OK'
} finally {
    Pop-Location
}

