# Agent Workflow Rules

## Plugin / Skill Usage Reporting

Before every response or task action, explicitly state whether this turn used any plugin or skill.

If a plugin or skill was used, list its name and one-sentence reason.

If no specialized plugin or skill was used, write: 未使用专门插件或 skill。

Do not enable plugins or skills only for display; report only actual usage.

## Workflow Activation

The full GitHub + Codex + architect-loop workflow is opt-in by default.

Use Normal Mode unless the user explicitly selects Workflow Mode or Supervisor Mode.

### Normal Mode

Use Normal Mode for explanation, discussion, local investigation, quick fixes, small edits, test runs, and general project questions.

Natural-language examples:

- 普通处理
- 直接回答
- 快速修一下
- 不用创建 issue
- 不用 gates/lanes
- 只解释，不实现
- 先别开 workflow

Normal Mode does not create GitHub issues, gates, lanes, builder dispatches, or PR review records unless the user explicitly asks for them.

### Workflow Mode

Use Workflow Mode only when the user explicitly asks to use the engineering collaboration workflow.

Natural-language examples:

- 使用工程协作流程实现这个需求
- 走 agent workflow
- 按 GitHub + Codex + architect-loop 流程处理
- 为这个任务创建 issue / gates / lanes
- 启用多 agent 协作流程
- 让 Codex 做 planner/reviewer，builder 实现

Workflow Mode requires:

- GitHub issue or issue draft.
- Architecture Brief for non-trivial work.
- Acceptance criteria.
- Gate file under `docs/gates/`.
- Lane file under `docs/lanes/` when work is complex or parallelizable.
- Builder dispatch block that states the selected builder agent and model.
- Gate review before done.
- PR using `.github/pull_request_template.md` and CI verification when the selected completion level requires remote delivery.

### Supervisor Mode

Use Supervisor Mode when the user asks Codex to inspect existing work instead of implementing new work.

Natural-language examples:

- 只审查这个 PR
- 检查这个 builder 的结果
- 看一下 CI 为什么失败
- 按 supervisor 模式检查
- 不要改代码，只给 review

Supervisor Mode reads existing issue, PR, diff, CI output, gates, lanes, or builder logs and produces a Supervisor Check.

If a task appears high-risk but the user did not explicitly opt in, ask: 这个任务要走完整工程协作流程，还是先按普通 Codex 任务处理？

## Workflow Preflight

- Complete Workflow Preflight before dispatching any builder.
- Verify the Git repository and committed baseline, project workflow configuration, selected builder health, and any GitHub access required by the target completion level.
- Do not dispatch while the decision is `preflight-blocked`.
- Record existing staged, unstaged, and untracked changes without reverting user work.
- If ownership of dirty-worktree changes is ambiguous, stop and ask the user before isolating, committing, or dispatching work.
- External builders must be confirmed available and use isolated mutable runtime, cache, and authentication state where supported.

## Role Boundaries

- Codex is the default planner, supervisor, and reviewer.
- Builder agents implement scoped lanes and produce traceable commits on assigned branches. They open PRs only when the lane dispatch or project policy requires it.
- Builder agents must not expand scope without Codex approval.
- Builder agents must not modify `docs/gates/` unless the issue explicitly requires gate changes.
- Reviewer decisions must be based on diff, CI, gates, lanes, and acceptance criteria, not builder claims alone.
- Builder stdout is not authoritative. If a builder times out, returns no text, or claims completion, Codex must inspect git diff, files, and gate output before deciding status.
- Workflow Mode must start from a real Git repository with a recorded committed baseline SHA. Identified unrelated user changes may remain isolated; ambiguous or conflicting changes block dispatch. If the repository or committed baseline is missing, stop and initialize or ask for confirmation before dispatching builders.
- After every builder return, including timeout or non-zero exit, Codex must inspect the assigned worktree, commits, complete baseline diff, changed files, protected files, and required gates.
- A lane is verified only after its scope and independently executed gates pass.
- Builder-authored documentation must not present unobserved URLs, SHAs, runtime values, CI results, artifacts, or review decisions as facts.

## Builder Agent And Model Selection

The user may specify the builder agent and model in natural language. Honor explicit user choices unless they are unavailable or unsafe.

Natural-language examples:

- 用 claude-builder 和 opus 实现
- builder 选 claude-builder，模型用 claude-sonnet
- 这个任务用 bailian-opencode-builder 和 bailian/qwen-plus
- researcher 用 gemini-researcher

Do not select deprecated or disabled builders unless the user explicitly re-enables them. In phase one, `cursor-builder` is deprecated. `codex-builder` is enabled only as an external builder with isolated `CODEX_HOME`; it is distinct from the active Codex planner/supervisor/reviewer.

Builder selection policy:

- Active Codex remains planner, supervisor, and reviewer.
- Prefer non-Codex external builders for implementation lanes when they are capable: `claude-builder` for architecture/refactor/review/docs-heavy work and `bailian-opencode-builder` for code/test/Chinese-context lanes.
- Use `codex-builder` only when the user explicitly requests Codex CLI, when non-Codex builders are unavailable, or when a lane needs Codex CLI-specific behavior.
- Do not assign an entire large core implementation to one builder unless the Architecture Brief justifies why it cannot be split.
- Select builders per lane by capability and verified health, not once for the entire issue.

If the user does not specify a builder, select one from `.codex-agent-workflow.yml` by capability match and state the selected agent and model before dispatch.

Every Workflow Mode builder dispatch must include:

- Builder agent id.
- Provider.
- Model.
- Branch or worktree name.
- Lane file.
- Gate file.
- Allowed files.
- Validation commands.

## Gates And Lanes

- Define gates before builder implementation starts.
- Define lanes before parallel builder work starts.
- Each lane must include allowed files and forbidden files.
- Complex tasks must include a lane dependency graph. Codex should split work by API/contract, implementation area, tests, docs, validation, and integration when possible.
- Prefer small lanes with clear contracts. If a lane touches many modules, creates a new subsystem, or is likely to produce a long-running builder prompt, Codex should split it before dispatch.
- Do not use an oversized lane that combines contracts, core implementation, tests, and documentation without a documented Lane Split Exception.
- Approve cross-lane public contracts before dependent builders implement against them.
- Different lanes should prefer non-overlapping files. Overlap is allowed only when the lane explicitly declares shared files, merge owner, and conflict strategy.
- If overlapping edits affect the same source or test file semantics, Codex should usually sequence the lanes instead of running them in parallel.
- If overlapping edits are documentation, changelog, validation script, or generated integration files, parallel work is acceptable when Codex owns the final merge review.
- Parallel lanes must use isolated branches/worktrees and mutable runtime directories.
- Shared-file parallel work must declare an authoritative lane, merge owner, merge order, conflict strategy, and post-merge validation.
- Builder agents must not merge other builder branches and claim final integration.
- Codex must check changed files against lane allowed files before approving.
- Active Codex owns integration unless the user explicitly assigns a human maintainer.
- Two or more accepted builder branches require an integration branch or equivalent merge queue and a final integration gate, because branches can pass individually and fail together.

## Remote Completion

- Select `local-complete`, `pr-complete`, `merge-complete`, or `delivery-complete` before remote execution.
- Evaluate CI, artifacts, and review against the current PR head SHA. A new commit makes prior final-approval evidence stale.
- Do not rely only on a workflow's top-level conclusion; inspect required jobs, key steps, skips, fallbacks, and required artifacts.
- Move a draft PR to ready only after final-head CI, required artifacts, required lane gates, any required multi-branch integration gate, scope checks, and a Supervisor Check pass.
- Do not merge, release, deploy, force-push, or rewrite history without explicit user instruction or project authorization.

## Security And Recovery

- Never write API keys, tokens, authorization headers, or complete secret values to repository files, prompts, workflow records, retained logs, or review comments.
- Credential exposure sets `security-blocked` and stops builder dispatch and publication until the user confirms containment and a new security baseline is verified.
- Automatically retry only a confirmed transient failure and at most once.
- Do not automatically retry code, gate, scope, contract, identity, or security failures.
- After the same blocker occurs three times, stop automatic recovery and request user input or an external-state change.
- Do not clear, reuse, or remove a builder worktree until its changes and disposition are recorded. Verify absolute paths before approved cleanup.

## Completion Rule

Do not mark Workflow Mode work done until issue scope, acceptance criteria, gates, lane scope, PR diff, integration evidence, and the evidence required by the selected completion level all support completion.

