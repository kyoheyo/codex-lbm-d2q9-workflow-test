# Agent Roles

## Codex Planner

Responsibilities:

- Convert user intent into issue scope.
- Write Architecture Brief for non-trivial work.
- Define acceptance criteria.
- Define gates before implementation.
- Split complex work into lanes.
- Produce a lane dependency graph before parallel dispatch.
- Split large work by contracts, implementation area, tests, docs, validation, and integration rather than assigning one oversized lane.
- Select or confirm builder agent/model.
- Prefer non-Codex external builders for implementation unless the user explicitly requests Codex CLI or the lane requires it.

## Codex Supervisor

Responsibilities:

- Track issue, lane, and builder status, plus PR and CI status when remote delivery applies.
- Ensure builder scope stays within lane allowed files.
- Treat builder stdout as advisory and verify status from git diff, file state, and gate output.
- Manage integration branches and merge conflicts across accepted builder branches.
- Detect blockers and ask for human decisions when required.
- Produce Supervisor Check reports.

## Codex Reviewer

Responsibilities:

- Review the PR or local candidate diff against issue, gate, lane, and acceptance criteria.
- Rerun or confirm gates.
- Check that `docs/gates/` was not modified by builder.
- Check changed files against lane allowed files.
- Check declared overlap policy and actual merge conflicts.
- Run final integration gates after merging multiple builder branches.
- Decide approve, changes-requested, blocked, or follow-up issue.

## Builder Agent

Responsibilities:

- Read AGENTS.md, the issue, lane, and gate.
- Implement only the assigned lane.
- Use the selected model unless user or Codex changes assignment.
- Work in an isolated branch or worktree.
- Run required gates when possible.
- Produce traceable scoped commits. Open a lane PR only when the dispatch or project policy requires it.
- Keep partial work in the branch if the builder times out or cannot finish, so Codex can inspect and decide whether to continue, fix, or discard.

Builder agents must not:

- Expand scope without Codex approval.
- Modify `docs/gates/` unless the issue explicitly requests it.
- Mix unrelated refactors into the branch, PR, or delivery candidate.
- Claim completion without evidence.

## Researcher Agent

Responsibilities:

- Investigate external docs, tradeoffs, libraries, or architecture options.
- Produce cited findings when web or external source evidence is used.
- Feed findings to Codex Planner.

Researchers do not make final implementation or merge decisions.
