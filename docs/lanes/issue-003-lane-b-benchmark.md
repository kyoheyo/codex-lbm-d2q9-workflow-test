# Lane: issue-003-lane-b-benchmark

## Identity

Issue: #3
Lane ID: lane-b-benchmark
Version: 1
Lane Type: validation
Status: accepted
Owner: Codex

## Goal

Add a fail-closed PowerShell benchmark that compares baseline and candidate CPU LBM executables.

## Out Of Scope

- C++, CUDA, existing validation script, tests, workflow, or documentation changes.

## Builder

- Agent: bailian-opencode-builder
- Provider: OpenCode with Bailian endpoint
- Model: `bailian/qwen-plus`
- Fallback: none before Codex inspection

## Branch And Worktree

- Branch: `builder/bailian-issue-3-benchmark`
- Worktree: sibling workflow test worktree directory
- Runtime state: isolated

## Allowed Files

- `scripts/benchmark_cpu.ps1`

## Forbidden And Protected Files

- Every other repository file
- `docs/gates/**`
- Credentials and authentication state

## Dependencies

- Approved Issue #3 benchmark contract
- Committed planning baseline

## Shared File Policy

- Overlap Level: none
- Merge Owner: Codex Supervisor
- Merge Order: before CPU optimization lane

## Gate

- `docs/gates/issue-003-lane-b-benchmark.md`

## Required Return

- candidate/partial/blocked/inconclusive status
- branch, head SHA, commits, changed files, commands, negative-path evidence, risks, and remaining work
- no claim of final verification
