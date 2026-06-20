# Architecture Brief: issue-000

## Identity

Issue: #000
Mode: Workflow
Target Completion Level: local-complete | pr-complete | merge-complete | delivery-complete
Repository:
Baseline SHA:
Remote Delivery Required: yes | no
Merge Authorized: yes | no

## Problem

What problem should this task solve, and what observable behavior is currently missing or incorrect?

## Scope

Included:

-

Out Of Scope:

-

## Proposed Design

Describe the intended design, responsibility boundaries, data or control flow, and why it fits the project.

## Contracts

| Contract | Owner | Version Or SHA | Consumers | Compatibility Rule |
|---|---|---|---|---|
| | contract lane or Codex | | | |

Dependent lanes must not invent or change an unapproved public contract.

## Alternatives Considered

| Option | Benefits | Costs Or Risks | Decision |
|---|---|---|---|
| | | | |

## Acceptance Criteria

- [ ] AC-1:
- [ ] AC-2:

## Gate Plan

| Gate | Type | Acceptance Criteria | Behavior Proven |
|---|---|---|---|
| `docs/gates/issue-000-lane-a.md` | lane | AC-1 | |
| `docs/gates/issue-000-integration.md` | integration | AC-1, AC-2 | |

## Lane Dependency Graph

```text
contract -> core/adapter/boundary -> tests -> validation -> integration
```

The graph must be acyclic. Remove lane types that the issue does not need.

## Lanes

| Lane | Type | Goal | Allowed Files | Depends On | Overlap | Preferred Builder | Preferred Model | Gate |
|---|---|---|---|---|---|---|---|---|
| lane-a | contract | | `src/**` | none | none | capability match | selected at dispatch | `docs/gates/issue-000-lane-a.md` |
| lane-b | core | | `src/**`, `tests/**` | lane-a | none | capability match | selected at dispatch | `docs/gates/issue-000-lane-b.md` |

## Lane Split Exceptions

Use one section for every lane that combines otherwise separable responsibilities.

### Exception: none

Lane:
Reason It Cannot Be Split:
Shared Invariants:
Why Sequencing Does Not Help:
Selected Builder:
Risk Controls:
Additional Review:

## Overlap Plan

| Shared File | Overlap Level | Authoritative Lane | Merge Owner | Merge Order | Conflict Strategy | Post-Merge Validation |
|---|---|---|---|---|---|---|
| none | none | | Codex Supervisor | lane graph order | | |

Semantic overlap is sequenced unless its exception and integration test are approved here.

## Integration Plan

Integration Required: yes | no
Integration Branch Or Merge Queue:
Integration Owner: Codex Supervisor
Baseline SHA:
Accepted Lane Head Record:
Integration Gate:
Codex Integration Fix Policy:

## Builder Selection Plan

| Lane | Required Capabilities | Candidate Builders | Preferred | Fallback | Selection Evidence |
|---|---|---|---|---|---|
| | | | | | dispatch record |

The actual builder, provider, model, health evidence, and fallback are recorded per dispatch.

## Implementation Sequence

1. Approve contracts and gates.
2. Dispatch lanes according to the dependency graph.
3. Inspect every builder result and independently run lane gates.
4. Integrate accepted branches and run the integration gate when required.
5. Complete remote delivery stages required by the selected completion level.

## Remote Delivery And Merge Boundary

Issue Relationship: closes | relates
Draft PR Required: yes | no
Required Actions:
Required Artifacts:
Required Human Review:
Merge Method:
Post-Merge Validation:
Issue Closure Expected: yes | no

Ready for review does not authorize merge, release, or deployment.

## Failure And Recovery

Expected External Blockers:

- none

Allowed Automatic Retry:

- confirmed transient failure, at most once

Repair Lane Strategy:

- narrower than source lane

Resume Checkpoints:

- affected preflight, lane gate, integration SHA, or remote head

## Risk And Security

Known Risks:

-

Fallback Paths:

- none

Credential Or Permission Changes:

- none

Protected Files And Ownership Boundaries:

- `docs/gates/**`
- credentials and authentication state

## Review Readiness

| Check | Result | Evidence |
|---|---|---|
| Scope and out of scope are clear | | |
| Acceptance criteria map to gates | | |
| Lane graph and contracts are defined | | |
| Lane size and exceptions are justified | | |
| Overlap and integration ownership are defined | | |
| Builder selection is capability based | | |
| Completion level and remote boundary are defined | | |
| Reviewer can verify behavior from diff, gates, CI, and artifacts as applicable | | |
