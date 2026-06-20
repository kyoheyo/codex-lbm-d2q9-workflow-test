# Codex Supervisor Review Checklist

Use this checklist for final Workflow Mode review and read-only Supervisor Mode inspection. Every check records `pass`, `fail`, `not-applicable`, or `inconclusive` and cites evidence. A checked box without evidence is not a review result.

In Supervisor Mode, report missing workflow records as findings or `inconclusive`. Do not create lanes, change code, or mutate the PR unless the user explicitly requests implementation or switches modes.

## Identity

Issue:
PR:
Mode: Workflow | Supervisor
Target Completion Level: local-complete | pr-complete | merge-complete | delivery-complete
Base:
Head:
Head SHA:
Baseline SHA:
Integration SHA:
Review Time:
Reviewer: Codex
Preflight Record:
Existing Changes Classification: clean | identified-unrelated | task-related | ambiguous

## Review Scope

Reviewed Diff:

Included Lanes:

-

Excluded Work:

- none

Previous Review:

New Commits Since Previous Review:

- none

Control Documents Reviewed:

| Document | Version Or SHA |
|---|---|
| Lane | |
| Gate | |
| Dispatch | |

## Preflight And Task Definition

| Check | Result | Evidence |
|---|---|---|
| Requested mode is correct | | |
| Repository and committed baseline are identified | | |
| Target completion level is defined | | |
| Issue contains goal, scope, out of scope, and acceptance criteria | | |
| Architecture Brief exists when required | | |
| Gates and lane graph exist when required | | |
| Builder selection and health were recorded | | |
| Required remote and permissions match the delivery target | | |
| Existing user changes were classified and ambiguous changes blocked dispatch | | |
| Preflight decision and evidence record are traceable | | |

## Builder Result Evidence

| Lane | Builder And Model | Reported State | Observed State | Commit SHA | Evidence Level |
|---|---|---|---|---|---|
| | | | | | |

| Check | Result | Evidence |
|---|---|---|
| Every assigned worktree and branch was inspected | | |
| Timeout, empty output, and non-zero exits were treated as inconclusive until inspection | | |
| Staged, unstaged, untracked, and committed changes are accounted for | | |
| Builder claims are separated from Codex observations | | |
| No builder self-declared final verification or integration was accepted | | |

## Scope And Contracts

| Check | Result | Evidence |
|---|---|---|
| PR or candidate changes match issue scope | | |
| Changed files are within lane allowed files | | |
| Forbidden and protected files are unchanged or explicitly approved | | |
| No unrelated refactor or generated noise is included | | |
| Public contracts were approved before dependent implementation | | |
| Dependent lanes used the actual approved contract and upstream SHA | | |
| Repair lanes remained narrower than their source lanes | | |
| Lane size is appropriate or an approved Lane Split Exception exists | | |
| Dispatches did not recombine separately owned responsibilities into oversized work | | |

## Gates And Behavior

| Check | Result | Evidence |
|---|---|---|
| Every acceptance criterion maps to passing evidence | | |
| Codex independently executed or confirmed the required gates | | |
| Command, working directory, exit code, and tested SHA are recorded | | |
| Required semantic and domain-invariant checks pass | | |
| Important success, edge, and exceptional paths are covered | | |
| Fallbacks, skips, warnings, and untested paths are explained | | |
| Local artifacts pass required size, format, and content checks | | |
| Builder did not weaken or modify gates without approval | | |
| Gate corrections and implementation fixes are recorded separately | | |

## Worktrees And Integration

Use `not-applicable` for integration-only checks when one builder branch is accepted.

| Check | Result | Evidence |
|---|---|---|
| Each parallel lane used its assigned branch, worktree, and runtime directory | | |
| Shared and semantic overlap was declared before parallel dispatch | | |
| Authoritative lane, merge owner, order, and conflict strategy were followed | | |
| Integration branch or equivalent merge queue started from the intended baseline | | |
| Accepted builder heads and merge order are recorded | | |
| Mechanical, contract, behavioral, test, and documentation conflicts were classified | | |
| Codex integration fixes are identified separately from builder work | | |
| Final integration SHA passed the complete required integration gate | | |
| Every builder worktree has a recorded retain, merged, rejected, abandoned, or approved-cleanup disposition | | |

## Failure And Recovery Evidence

| Failure ID | Stage | Retry Count | Repair Lane | Resume Checkpoint | Result |
|---|---|---:|---|---|---|
| none | | 0 | none | | |

| Check | Result | Evidence |
|---|---|---|
| Automatic retries were limited to confirmed transient failures and at most once | | |
| Repeated blockers were diagnosed and stopped after the third occurrence | | |
| Worktrees were preserved until changes and disposition were recorded | | |
| Repair scope and resume checkpoint match the diagnosed failure | | |

## Remote Evidence

Use `not-applicable` when the target completion level is `local-complete`.

Actions Runs:

| Workflow | Run ID | Head SHA | Required Jobs | Result |
|---|---|---|---|---|
| | | | | |

Remote Artifacts:

| Artifact | Run ID | Head SHA | Size | Digest | Result |
|---|---|---|---|---|---|
| | | | | | |

| Check | Result | Evidence |
|---|---|---|
| Local and remote head SHAs match | | |
| PR links the correct issue and uses the intended base and head | | |
| Actions run belongs to the current PR head SHA | | |
| Required jobs and key steps completed successfully | | |
| Skipped, neutral, allowed-failure, and rerun results are explained | | |
| Required artifacts belong to the current run and head | | |
| Artifacts are non-empty, valid, unexpired, and traceable to their producing job | | |
| Final Supervisor Check reviews the current head | | |
| Draft, ready, mergeable, merged, and issue states match the selected completion level | | |

## Documentation And Security

| Check | Result | Evidence |
|---|---|---|
| Documentation contains no unmarked placeholders or fabricated evidence | | |
| Example output is explicitly labeled as an example | | |
| Runtime values, URLs, SHAs, artifacts, and review decisions are traceable | | |
| Branch names, commands, and configuration descriptions match the final implementation | | |
| No API key, token, authorization header, or complete secret value is retained | | |
| Repository configuration contains only non-secret values and credential-source references | | |
| No unrelated cache, runtime state, authentication file, or generated secret is included | | |

## Residual Risk

Known Limitations:

-

Fallback Paths:

-

Skipped Validation:

- none

Follow-Up Issues:

- none

Unresolved Questions:

- none

## Decision

Result: approve | changes-requested | blocked | follow-up

Completion Level Reached: none | local-complete | pr-complete | merge-complete | delivery-complete

Required Fixes:

1.

Evidence Summary:

-

Stale Evidence:

- none

Next Checkpoint:

## Decision Rules

- `approve`: all mandatory checks for the target completion level pass, no evidence is stale, no blocker remains, and residual risks are accepted.
- `changes-requested`: implementation, test, scope, documentation, or artifact defects are diagnosed and repairable.
- `blocked`: permission, dependency, security containment, external state, or a user decision prevents progress.
- `follow-up`: the current acceptance criteria can pass, but an independent non-blocking issue must be recorded.

`approve` is a Codex workflow conclusion and is not necessarily a native GitHub approval. Do not misrepresent the platform review state when GitHub prevents self-approval or requires another reviewer.

## Remote Supervisor Check Summary

```md
## Remote Supervisor Check

Issue:
PR:
Base:
Head:
Head SHA:
CI Run:
Required Jobs:
Artifacts:
Integration SHA:
Review Scope:

Decision:
approve | changes-requested | blocked | follow-up

Completion Level Reached:

Evidence:
-

Required Fixes:
-

Stale Evidence:
- none
```
