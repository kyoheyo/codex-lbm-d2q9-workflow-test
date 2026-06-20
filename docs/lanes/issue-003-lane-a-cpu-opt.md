# Lane: issue-003-lane-a-cpu-opt

## Identity

Issue: #3
Lane ID: lane-a-cpu-opt
Version: 1
Lane Type: core/refactor
Status: accepted-after-reassignment
Owner: Codex

## Goal

Remove the unused periodic CPU macroscopic-field sweep and directly exposed redundant traversal work without changing observable solver behavior, row-major order, boundary logic, or floating-point expressions.

## Out Of Scope

- Public API, CUDA, CLI, boundary-condition, numerical-model, test, script, or documentation changes.

## Builder

- Agent: claude-builder
- Provider: claude-code with DeepSeek-compatible endpoint
- Model: configured DeepSeek model through the `opus` alias
- Fallback: none before Codex inspection

Final assignment note: `claude-builder` was stopped after repeated scope and evidence violations. The accepted repair branch used `bailian-opencode-builder` with `bailian/qwen-plus`; Codex retained merge and gate ownership.

## Branch And Worktree

- Branch: `builder/bailian-issue-3-cpu-repair` (accepted); `builder/claude-issue-3-cpu-opt` (rejected evidence retained)
- Worktree: sibling workflow test worktree directory
- Runtime state: isolated

## Allowed Files

- `src/lbm_cpu.cpp`

## Forbidden And Protected Files

- Every other repository file
- `docs/gates/**`
- Credentials and authentication state

## Dependencies

- Approved Issue #3 Architecture Brief
- Committed planning baseline

## Shared File Policy

- Overlap Level: none
- Merge Owner: Codex Supervisor
- Merge Order: after benchmark lane

## Gate

- `docs/gates/issue-003-lane-a-cpu-opt.md`

## Required Return

- candidate/partial/blocked/inconclusive status
- branch, head SHA, commits, changed files, commands, skips, risks, and remaining work
- no claim of final verification
