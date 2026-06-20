---
name: Agent Task
about: Task for GitHub + Codex + architect-loop workflow
title: "[Agent Task]: "
labels: ["agent:todo"]
assignees: []
---

## Workflow Control

Mode: Workflow
Target Completion Level: local-complete | pr-complete | merge-complete | delivery-complete
Remote Delivery Required: yes | no
Merge Authorized: yes | no
Issue Closure Expected: yes | no

## Goal

What observable result should be achieved?

## Context

Relevant background, constraints, links, existing behavior, and known user changes.

## Scope

What is included in this task?

## Out Of Scope

What must not be changed or delivered by this task?

## Acceptance Criteria

- [ ] AC-1:
- [ ] AC-2:
- [ ] Every criterion has a defined validation path.

## Architecture Brief

Path or link:

Required: yes | no

## Gates

| Gate | Type | Behavior Proven |
|---|---|---|
| `docs/gates/issue-000-lane-a.md` | lane | |

## Lane Dependency Graph

```text
contract -> implementation -> tests -> validation -> integration
```

## Lanes

| Lane | Type | Goal | Allowed Files | Depends On | Overlap | Preferred Builder | Preferred Model | Gate |
|---|---|---|---|---|---|---|---|---|
| lane-a | core | | `src/**`, `tests/**` | none | none | capability match | selected at dispatch | `docs/gates/issue-000-lane-a.md` |

## Overlap And Integration

Shared Files:

- none

Authoritative Lane:

Merge Owner: Codex Supervisor

Merge Order:

- lane graph order

Integration Required: yes | no

Integration Branch Or Merge Queue:

Integration Gate:

## Builder Agent And Model

User-requested builder, if any:

- Builder agent:
- Model:

If unspecified, Codex selects a healthy builder per lane by capability and records the actual provider and model in each dispatch. External `codex-builder` is not the default for ordinary implementation.

## Risk And Security

Known Risks:

-

Fallbacks:

- none

Credential Or Permission Changes Required:

- none

## Suggested Files

- `path/to/file`

## Agent Instructions

- Read `AGENTS.md` before working.
- Do not expand scope or invent missing contracts.
- Do not edit `docs/gates/` unless this issue explicitly assigns a gate change.
- Modify only lane allowed files and respect protected files.
- Produce traceable scoped commits.
- Open a lane PR only when the dispatch or project policy requires it.
- Do not fabricate runtime, CI, artifact, or review evidence.
- Do not expose credential values.
