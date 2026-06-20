## Issue And Completion Target

Issue: #

Mode: Workflow | Supervisor follow-up

Relationship: closes | relates

Use `Closes #...` only when merge should close the issue. Otherwise use `Relates to #...`.

Target Completion Level: pr-complete | merge-complete | delivery-complete

Merge Authorized: yes | no

## Git Identity

Base:
Head:
Baseline SHA:
Current Head SHA:
Integration SHA: not-applicable

## Control Documents

| Document | Path Or URL | Version Or SHA |
|---|---|---|
| Issue | | |
| Architecture Brief | | |
| Lane | | |
| Gate | | |
| Dispatch | | |

## Summary

What changed and which observable behavior does it deliver?

## Out Of Scope

-

## Builder Deliveries

| Dispatch | Lane | Builder And Model | Branch | Head SHA | Observed State |
|---|---|---|---|---|---|
| | | | | | candidate |

Builder completion messages are claims. `Observed State` is recorded after Codex inspects the branch, diff, commits, scope, and gates.

## Scope

| Lane | Allowed Files | Actual Changed Files | Result |
|---|---|---|---|
| | | | |

Files Changed Outside Allowed Scope:

- none

Protected Files Changed:

- none

Unrelated Refactors:

- none

## Integration

Integration Required: yes | no

Integration Branch: not-applicable

Merge Owner: Codex Supervisor

Merge Order:

- not-applicable

Shared Files:

- none

Conflict Resolution:

- none

Codex Integration Fixes:

- none

Integration Gate:

- not-applicable

Use `not-applicable` for a single accepted builder branch. Multi-builder PRs must identify the final integration SHA in Git Identity.

## Local Validation

| Source | Command | Working Directory | Tested SHA | Exit | Markers | Result |
|---|---|---|---|---|---|---|
| builder claim | | | | | | |
| Codex verification | | | | | | |

Semantic Checks:

-

Fallbacks:

- none

Skipped Validation:

- none

Warnings:

- none

Local Artifacts:

| Artifact | Tested SHA | Size | Format Or Content Check | Result |
|---|---|---|---|---|
| | | | | |

## Remote Validation

Status: pending | verified | failed | stale

Actions Runs:

| Workflow | Run ID | Head SHA | Required Jobs | Result |
|---|---|---|---|---|
| | | | | pending |

Remote Artifacts:

| Artifact | Run ID | Head SHA | Size | Digest | Result |
|---|---|---|---|---|---|
| | | | | | pending |

When the issue and gates require no remote artifact, record `artifacts-not-required` in the Result column.

Do not record predicted run IDs, conclusions, artifact values, or review decisions. A new head makes older final-approval evidence stale.

## Documentation And Security

- [ ] Example output is explicitly labeled as an example.
- [ ] Completion evidence contains no unmarked placeholders or fabricated values.
- [ ] No credential, token, authorization header, authentication file, or complete secret value is included.
- [ ] Repository configuration contains only non-secret values and credential-source references.
- [ ] No unrelated runtime directory, cache, or generated secret is included.

These are author assertions and still require independent Supervisor verification.

## Risk

Known Limitations:

-

Fallback Paths:

- none

Remaining Untested Paths:

- none

Follow-Up Issues:

- none

## Ready For Review Evidence

Final Head SHA:
CI:
Artifacts:
Required Lane Gates:
Integration Gate: not-applicable
Supervisor Check:
Stale Evidence: none

Fill this section only with observed evidence, or link the final-head Supervisor Check that contains it.

## Merge Boundary

Authorization Source: Issue | project policy | explicit user instruction | none
Merge Method:
Required Human Review:
Post-Merge Validation:
Issue Closure Expected: yes | no

Ready for review does not authorize merge, release, or deployment.

## Notes For Codex Reviewer

List behavior, risk, contract, integration, or platform details that require focused review.
