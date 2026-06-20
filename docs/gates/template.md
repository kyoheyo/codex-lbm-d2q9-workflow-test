# Gate: issue-000-lane-a

## Identity

Issue: #000
Lane: lane-a
Gate Type: lane | integration | remote
Owner: Codex
Version: 1
Baseline SHA:
Target Completion Level: local-complete | pr-complete | merge-complete | delivery-complete

## Goal

State the behavior this gate must prove. Describe the result, not only the command that will run.

## Acceptance Criteria Mapping

| Criterion | Evidence | Command Or Check |
|---|---|---|
| AC-1 | | |

Every acceptance criterion must map to at least one independently verifiable result.

## Environment And Capabilities

Required:

- OS:
- Runtime:
- Compiler:
- Services:

Optional:

- Hardware:
- External provider:

Capability Detection:

- Command:
- Expected result:

Fallback Policy:

- Allowed: yes | no
- Trigger:
- Required evidence marker:

Skip Policy:

- Allowed skips:
- Forbidden skips:

Detect actual capabilities instead of inferring them only from the operating-system name.

## Clean Setup

Working Directory:

Generated Directories To Recreate:

-

Required Fixtures:

-

Prohibited Preexisting Artifacts:

-

Describe the required clean state without adding an unsafe or unscoped deletion command.

## Commands

### Command 1: Unit Or Component Tests

Working Directory:

```text
npm test
```

Expected Exit Code: 0

Expected Markers:

-

Forbidden Markers:

-

Timeout:

Produces:

-

### Command 2: Build Or Validation

Working Directory:

```text
npm run typecheck
```

Expected Exit Code: 0

Expected Markers:

-

Forbidden Markers:

-

Timeout:

Produces:

-

Add or remove command sections to match the issue. Each required command must state how success is recognized.

## Semantic Checks

| Check | Method | Pass Condition |
|---|---|---|
| Output validity | parser, test, or inspection | Project-defined semantic condition |

Semantic checks should prove domain behavior and invariants rather than only confirming that a file or object exists.

## Artifact Checks

| Artifact | Required | Validation | Pass Condition |
|---|---|---|---|
| path or remote name | yes | size, format, and content | Non-empty and project-valid |

For remote artifacts, also record the workflow run ID, head SHA, size, expiration state, producing job, and digest when available.

## Scope Checks

Allowed Files Source:

Forbidden Files:

- Files outside the lane's allowed files

Protected Files:

- `docs/gates/**`

Gate Modification Policy:

- Builder changes are prohibited unless the issue scope explicitly approves a gate change.
- A suspected gate defect is reported to Codex rather than fixed by weakening the gate.

## Integration Checks

Complete this section when `Gate Type` is `integration`.

Accepted Lanes:

| Lane | Branch | Head SHA | Evidence Level |
|---|---|---|---|
| | | | |

Integration Branch:

Required Cross-Lane Contracts:

-

Required Full Test Set:

-

Conflict Marker Check:

-

Documentation Consistency Check:

-

## Manual Checks

- [ ] Complete only the checks that cannot be automated.
- [ ] Record the observation and evidence rather than marking an unexplained checkbox.

## Pass Criteria

- All required commands exit with their expected codes.
- Required markers appear and forbidden markers do not.
- Every acceptance criterion has passing evidence.
- Required semantic and artifact checks pass.
- Required execution paths are not silently skipped.
- Fallbacks and allowed skips are recorded.
- Lane scope and protected-file checks pass.
- Integration checks pass when applicable.

## Gate Evidence

Store actual execution evidence in the PR, run log, or Supervisor Check. Builders must not rewrite this gate to record a passing result.

Evidence Record Location:

Commit SHA:
Executed By:
Execution Time:
Environment:

Commands And Exit Codes:

-

Observed Markers:

-

Skips Or Fallbacks:

-

Artifacts:

-

Result: pass | fail | inconclusive

Failure Classification: implementation | test | gate | environment | security | none

Notes:

## Gate Change Control

- Gate changes require Codex approval before builder implementation or repair continues.
- Record a gate correction separately from an implementation fix.
- Re-evaluate affected acceptance criteria after a gate change.
- Do not lower a threshold solely to make the current implementation pass.
