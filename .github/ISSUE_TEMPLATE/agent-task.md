---
name: Agent Task
about: Task for GitHub + Codex + architect-loop workflow
title: "[Agent Task]: "
labels: ["agent:todo"]
assignees: []
---

## Goal

What should be achieved?

## Context

Relevant background, constraints, links, and existing behavior.

## Scope

What is included in this task?

## Out of Scope

What must not be changed in this task?

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Validation path is clear

## Gates

List commands or checks Codex Reviewer must rerun or confirm.

```text
# Example
npm test
npm run typecheck
```

## Lanes

Use lanes for complex or parallel work.

| Lane | Goal | Allowed Files | Preferred Builder | Preferred Model | Gate |
|---|---|---|---|---|---|
| lane-a | ... | src/foo/**, tests/foo/** | codex-builder | gpt-5-codex | docs/gates/issue-000-lane-a.md |

## Suggested Files

- `path/to/file`

## Builder Agent And Model

User-requested builder, if any:

- Builder agent:
- Model:

If unspecified, Codex selects by `.codex-agent-workflow.yml` capability match and states the selected agent/model before dispatch.

## Agent Instructions

- Read AGENTS.md before working.
- Do not expand scope.
- Do not edit `docs/gates/` unless this issue explicitly requests it.
- Modify only lane allowed files.
- Open a PR using the project PR template.
