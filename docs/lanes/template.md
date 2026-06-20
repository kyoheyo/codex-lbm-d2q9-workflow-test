# Lane: issue-000-lane-a

## Identity

Issue: #000
Lane ID: lane-a
Version: 1
Lane Type: contract | core | adapter | boundary | tests | docs | validation | repair | integration
Status: pending
Owner: Codex
Baseline SHA:
Target Branch:

Only Codex may mark a lane `verified`. An integration lane remains owned by Codex or an explicitly assigned human maintainer.

## Goal

Describe one independently verifiable behavior this lane must deliver.

## Out Of Scope

-

The builder stops and requests a scope decision instead of implementing an out-of-scope dependency.

## Decomposition

Why This Is One Lane:

Why It Is Not Combined With Adjacent Lanes:

Lane Split Exception: none | Architecture Brief section

If this lane combines contracts, core implementation, tests, and documentation, link an approved Lane Split Exception.

## Inputs

Approved Contracts:

-

Required Files:

-

Required Upstream Evidence:

-

The builder must not invent a missing public contract or incompatible upstream behavior.

## Outputs

Expected Behavior:

Expected Files:

-

Public Interfaces Changed:

- none

Artifacts:

- none

## Acceptance Criteria

| Criterion | Lane Responsibility | Gate Evidence |
|---|---|---|
| AC-1 | full | |

Lane Responsibility: `full` | `partial` | `not-owned`

## Builder Requirements

Required Capabilities:

-

Preferred Builder:

- Agent: claude-builder
- Model: opus

Fallback Builder:

- Agent: bailian-opencode-builder
- Model: bailian/qwen-plus

Builder Selection Record:

- Link or section:

The final dispatch uses a builder that passed health checks and records the actual provider and model.

## Branch And Worktree

Branch:

```text
agent/issue-000/lane-a-short-name
```

Worktree:

```text
../repo-worktrees/issue-000-lane-a
```

Runtime Directory:

Baseline SHA:

Expected Head Ownership: this lane only

Retain For Repair: yes

- The builder works only in this worktree.
- The builder does not switch to another lane branch or modify the main worktree.
- Mutable runtime, cache, and authentication state must not be shared with another concurrent builder.

## Allowed Files

- `src/example/**`
- `tests/example/**`

## Forbidden Files

- Files outside Allowed Files

## Protected Files

- `docs/gates/**`
- Credentials, authentication files, and secret-bearing configuration

Optional operation-level restrictions:

| Path | Create | Modify | Delete |
|---|---|---|---|
| | yes | yes | no |

## Dependencies

Must Run After:

- none

Can Run With:

- none

Blocks:

- none

Approved Contract Version:

Required Upstream SHAs:

- none

## Shared File Policy

Overlap Level: none | declared-shared | semantic-overlap | forbidden-overlap

Shared Files:

- none

Overlap Reason:

Expected Contributions:

Authoritative Lane:

Merge Owner: Codex Supervisor

Merge Order:

Conflict Strategy:

Post-Merge Validation:

For parallel semantic overlap:

- Architecture Brief Justification:
- Integration Test:

Semantic overlap is sequenced unless all exception fields are approved before dispatch.

## Gate

Gate File: `docs/gates/issue-000-lane-a.md`

Gate Type: lane | integration | remote

Required Commands:

-

Required Semantic Checks:

-

Required Artifacts:

- none

The gate is read-only for builders unless the issue explicitly assigns a gate change.

## Delivery Evidence

Builder Must Provide:

- branch and worktree;
- commit SHA or explicit uncommitted-state report;
- changed-file list;
- commands claimed to have run;
- skips, fallbacks, risks, and incomplete work;
- artifact paths when required.

Codex Must Observe:

- complete diff from the recorded baseline;
- allowed, forbidden, and protected-file result;
- independent gate result;
- final lane state.

Builder claims and stdout do not set the lane to `verified`.

## Failure And Repair

On Timeout Or Empty Output:

- Preserve the worktree and let Codex inspect diff and commits before retry or reassignment.

On Partial Work:

- Record usable changes and remaining scope; do not claim completion.

On Gate Failure:

- Report the failure and evidence. Do not weaken or edit the gate without Codex approval.

Repair Lane Policy:

- A repair lane must be narrower than this lane or trigger task replanning.

Resume Checkpoint:

- Builder result inspection and the affected lane gate.

## Builder Instructions

1. Read `AGENTS.md`, the issue, this lane, its approved contracts, and its gate.
2. Modify only allowed files and respect operation-level restrictions.
3. Do not modify protected files or expand scope without Codex approval.
4. Work only in the assigned branch, worktree, and runtime directory.
5. Run required validation where possible and report exact commands, skips, and fallbacks.
6. Do not read, print, or commit secret values.
7. Do not fabricate issue, PR, CI, artifact, runtime, or review evidence.
8. Do not merge another builder branch or claim final integration.
9. When a dependency or contract is missing, stop and report it instead of inventing one.
10. Leave the branch or worktree inspectable and include the lane ID in commits or delivery notes.
