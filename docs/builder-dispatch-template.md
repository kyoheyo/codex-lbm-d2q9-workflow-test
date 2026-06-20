# Builder Dispatch Template

Use one dispatch record for each actual builder invocation. A repair or reassignment creates a new dispatch record and does not overwrite the original lane definition.

```md
## Builder Dispatch

Dispatch ID:
Time:
Mode: Workflow
Issue:
Lane:
Gate:
Lane Version Or SHA:
Gate Version Or SHA:
Target Completion Level:
Preflight Decision: ready | ready-with-warnings
Preflight Record:

Warnings Accepted By Codex:
- none

## Selected Builder

Agent:
Provider:
Model:
Health: available | degraded
Health Check Time:
Builder Health Evidence:
Selection Reason:
Fallback Builder:

## Runtime Configuration

CLI Or Wrapper:
Working Directory:
Runtime Directory:
Configuration Path:
Credential Source:
Base URL:

Credential Source records only an environment variable name, authentication-file type, or secret-store reference. Never put a real secret value in this dispatch.

## Git Assignment

Repository:
Baseline SHA:
Branch:
Worktree:
Expected Head Ownership: this lane only

The builder works only in the assigned worktree and does not switch to another lane branch or modify the main worktree.

## Scope

Goal:

Out Of Scope:
-

Allowed Files:
-

Forbidden Files:
- Files outside Allowed Files

Protected Files:
- `docs/gates/**`
- Credentials and secret-bearing configuration

This dispatch may narrow the lane scope but must not expand it.

## Dependencies And Contracts

Approved Contract:
Contract Version Or SHA:

Required Upstream Lanes:
- none

Required Upstream SHAs:
- none

Shared Files:
- none

Authoritative Lane:
Merge Owner: Codex Supervisor
Overlap Policy Reference:
Merge Order:
Conflict Strategy:
Post-Merge Validation:

If a required dependency or contract is absent, stop and report it rather than inventing an interface.

## Required Work

Acceptance Criteria Covered:
- AC-1

1. State one bounded file, behavior, or acceptance-criterion task.
2. State the next bounded task when needed.

Do not use unbounded instructions such as "finish everything" or "add appropriate handling."

## Validation

### Command 1

Working Directory:
Command:
Expected Exit Code: 0

Expected Markers:
-

Forbidden Markers:
-

Semantic Checks:
-

Required Artifacts:
- none

Allowed Fallbacks:
- none

Forbidden Skips:
-

Builder validation is a claim until Codex independently checks the resulting scope and gate.

## Delivery Destination

Commit Required: yes
Push Required: yes | no
Lane PR Required: yes | no
Final Integration PR Owner: Codex | human

A builder opens a lane PR only when this dispatch explicitly requires it. Multi-builder work may instead deliver scoped branches for Codex integration.

## Required Return

Status: candidate | partial | blocked | inconclusive
Summary:
Branch:
Head SHA:

Commits:
-

Changed Files:
-

Uncommitted Changes:
- none

Commands Run:
-

Exit Codes:
-

Observed Markers:
-

Skips Or Fallbacks:
- none

Artifacts:
- none

Risks:
-

Remaining Work:
- none

The builder must not report `verified`, `complete`, or final approval as an authoritative workflow state.

## Failure Behavior

On Timeout Or Empty Output:
- Leave the worktree inspectable.
- Do not clean, reset, or discard changes.

On Missing Dependency:
- Stop and report the exact missing contract, file, service, or upstream SHA.

On Gate Failure:
- Preserve the command and output evidence.
- Do not edit or weaken the gate.

On Scope Insufficiency:
- Stop and request Codex approval before modifying additional files or behavior.

## Prohibited Actions

1. Do not modify files outside the assigned scope.
2. Do not edit protected gate files unless this dispatch explicitly assigns a gate change.
3. Do not merge another builder branch or claim final integration.
4. Do not read, print, commit, or retain real credential values.
5. Do not fabricate issue, PR, CI, artifact, runtime, or review evidence.
6. Do not perform global cleanup or destructive filesystem operations.
7. Do not change public contracts owned by another lane.
8. Do not claim final workflow approval.

## Builder Instructions

1. Read `AGENTS.md`, the issue, the lane file, approved contracts, and the gate.
2. Confirm the assigned branch, worktree, baseline SHA, and runtime directory before editing.
3. Perform only Required Work within Allowed Files.
4. Run the listed validation where possible and preserve exact evidence.
5. Commit traceable work with the lane ID when Commit Required is `yes`.
6. Return the Required Return fields even when work is partial or blocked.
```
