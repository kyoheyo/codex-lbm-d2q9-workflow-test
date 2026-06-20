# Lane: issue-003-lane-a-cpu-opt

## Identity

Issue: #3
Lane ID: lane-a-cpu-opt
Version: 1
Lane Type: core/refactor
Status: pending
Owner: Codex

## Goal

Remove the unused periodic CPU macroscopic-field sweep without changing observable solver behavior.

## Out Of Scope

- Public API, CUDA, CLI, boundary-condition, numerical-model, test, script, or documentation changes.

## Builder

- Agent: claude-builder
- Provider: claude-code with DeepSeek-compatible endpoint
- Model: configured DeepSeek model through the `opus` alias
- Fallback: none before Codex inspection

## Branch And Worktree

- Branch: `builder/claude-issue-3-cpu-opt`
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
