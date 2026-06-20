# GitHub + Codex + architect-loop Workflow

This project supports an opt-in engineering collaboration workflow.

## Modes

| Mode | When to use | Result |
|---|---|---|
| Normal Mode | Default for questions, investigation, quick fixes, and small edits | No issue/gate/lane required |
| Workflow Mode | User explicitly asks to use the workflow or create issue/gates/lanes/builder tasks | Full planning and builder supervision, with remote PR/CI stages when required by the selected completion level |
| Supervisor Mode | User asks to review existing PR, CI, builder output, or agent result | Supervisor Check only |

## Workflow Mode Lifecycle

```text
User opts in
  -> Codex verifies the repository, recorded committed baseline, existing changes, and configured builders
  -> Codex drafts or creates GitHub issue
  -> Codex writes Architecture Brief
  -> Codex writes gates
  -> Codex writes lane dependency graph and lanes if needed
  -> Codex selects or confirms builder agent/model
  -> Builder works in isolated branch or worktree
  -> Builder delivers traceable scoped commits
  -> If remote delivery is required: open draft PR and run CI
  -> Codex reruns or confirms gates
  -> Codex reviews diff against issue, gates, and lanes
  -> Codex performs integration merge/gate when multiple builder branches exist
  -> approve / changes-requested / blocked
```

## Workflow Mode Preflight

Run preflight before dispatching any builder. Checks are layered so a task only runs the levels required by its delivery mode and execution plan.

```text
Level 1: Local Git
  -> Level 2: Project Workflow
  -> Level 3: Builder
  -> Level 4: GitHub Remote
  -> Level 5: Parallel Execution
  -> Ready to dispatch
```

### Level 1: Local Git

Required for every Workflow Mode task:

- Confirm the current directory is inside a Git repository and locate its root.
- Record the current branch and baseline commit.
- Confirm at least one baseline commit exists.
- Record staged, unstaged, and untracked changes without reverting user work.
- Classify a dirty worktree as unrelated, task-related, or ambiguous. Ambiguous changes block dispatch.
- Confirm Git can perform the operations required by the task.
- Detect ownership or path-mapping failures such as `safe.directory` before implementation begins. Do not apply an unscoped global configuration change automatically.

Blocking reasons:

```text
preflight-blocked: git-repository
preflight-blocked: baseline-missing
preflight-blocked: ambiguous-dirty-worktree
preflight-blocked: git-write-unavailable
```

### Level 2: Project Workflow

Required for every Workflow Mode task:

- Read `AGENTS.md` and parse `.codex-agent-workflow.yml` when present.
- Confirm the project has not disabled Workflow Mode.
- For non-trivial work, confirm that the planning phase will provide an issue or issue draft, Architecture Brief, acceptance criteria, gates, and a lane graph.
- Confirm the configured gate, lane, dispatch, and PR template paths are available or will be created by Codex before dispatch.
- Treat configuration as non-secret. Do not search for, print, or copy credential values into workflow records.

Blocking reasons:

```text
preflight-blocked: workflow-disabled
preflight-blocked: invalid-workflow-config
preflight-blocked: required-control-file-missing
```

A missing file that Codex is explicitly about to create during planning is not a blocker.

### Level 3: Builder Health

Required when an external builder will be used. For every candidate builder:

- Confirm the builder is enabled and not deprecated.
- Confirm its CLI and wrapper are executable.
- Resolve the provider, model, base URL, configuration path, and credential source without displaying credential contents.
- Assign an isolated runtime, cache, and authentication directory when the tool maintains mutable state.
- Run the smallest practical read-only health check.
- Record the check time and one of: `available`, `degraded`, `unavailable`, or `not-checked`.

Only `available` builders are selected by default. A `degraded` builder may be used with an explicit risk note. An `unavailable` or `not-checked` builder must not be assumed usable. Failure of one builder does not block the task when another capable builder is available.

### Level 4: GitHub Remote

Required when the task promises a remote issue, PR, Actions run, artifact, or other GitHub delivery:

- Confirm the authenticated GitHub identity and required permissions.
- Confirm the repository, remote URL, default base branch, and expected destination all match.
- Confirm issue and PR access; confirm write access when push or mutation is required.
- Confirm required workflow files, checks, and artifact expectations are defined.
- Prefer read-only permission and metadata checks. Do not create a disposable branch solely to test access.

Blocking reasons:

```text
preflight-blocked: github-auth
preflight-blocked: remote-mismatch
preflight-blocked: base-branch-missing
preflight-blocked: insufficient-permission
```

### Level 5: Parallel Execution

Required when two or more builder lanes will run:

- Confirm the lane dependency graph is acyclic and every lane has a unique ID.
- Confirm every lane declares allowed files, forbidden files, dependencies, and a branch or worktree name.
- Classify all overlapping files before dispatch.
- Sequence semantic source overlap unless the Architecture Brief justifies parallel execution.
- Assign a merge owner, merge order, and conflict strategy for every shared file.
- Confirm worktree destinations do not collide with existing worktrees or directories.
- Define the integration branch or merge queue and the integration gate.

Blocking reasons:

```text
preflight-blocked: invalid-lane-graph
preflight-blocked: undeclared-overlap
preflight-blocked: missing-merge-owner
preflight-blocked: integration-plan-missing
```

### Preflight Report

Use this format before builder dispatch:

```md
## Workflow Preflight

Mode: Workflow
Repository:
Branch:
Baseline Commit:
Worktree Status:
Remote Required: yes | no
Parallel Builders: yes | no

Checks:
- [pass] Local Git
- [pass] Workflow configuration
- [pass] Builder: claude-builder
- [degraded] Builder: bailian-opencode-builder
- [pass] GitHub remote
- [pass] Lane graph and integration plan

Selected Builder:
Provider:
Model:

Warnings:
-

Blockers:
-

Decision:
ready | ready-with-warnings | preflight-blocked
```

`ready` permits planning completion and builder dispatch. `ready-with-warnings` permits dispatch only after Codex records the risk; warnings about credentials, scope, or the Git baseline cannot be waived this way. `preflight-blocked` prohibits dispatch until the blocking level is corrected and rerun.

Builder health, implementation correctness, test coverage, CI results, artifact validity, mergeability, and final review are separate checks. Preflight must not claim those later stages have passed.

## Natural-Language Activation

Users can choose the mode naturally:

- Workflow Mode: "走完整流程", "启用工程协作流程", "创建 issue / gates / lanes".
- Normal Mode: "普通处理", "直接回答", "不用创建 issue", "快速修一下".
- Supervisor Mode: "只审查", "检查这个 PR", "看一下 CI 为什么失败".

If the task appears risky but the user did not opt in, ask which mode to use before starting Workflow Mode.

## Builder Agent And Model Selection

Users may specify builder and model directly. Example:

```text
用 claude-builder 和 opus 实现
builder 选 claude-builder，模型用 claude-sonnet
这个任务用 bailian-opencode-builder 和 bailian/qwen-plus
```

If unspecified, Codex selects from `.codex-agent-workflow.yml` for each lane rather than selecting one builder for the whole issue. Capability and an `available` health result are hard requirements; cost or latency must not override an unsuitable capability match.

Evaluate candidates using:

- capability for the language, framework, and lane type;
- builder health and model availability;
- context and language fit;
- required CLI, compiler, and runtime access;
- authentication, configuration, and runtime isolation;
- cost and latency after quality requirements are met;
- prior evidence from comparable lanes in the same project.

Default role mapping:

| Work | Default Owner |
|---|---|
| Planning, contract approval, supervision, integration, and review | Active Codex |
| Architecture drafts, complex refactors, systems code, and documentation | `claude-builder` |
| Ordinary implementation, small modules, tests, and Chinese-context tasks | `bailian-opencode-builder` |
| Codex CLI-specific behavior or an explicit user request | `codex-builder` |

The mapping is a default, not a fixed binding. Preflight health and lane requirements decide the actual selection. In phase one, `cursor-builder` is deprecated.

`codex-builder` is an external builder with an isolated `CODEX_HOME`, provider configuration, and login state. It is distinct from active Codex. Prefer it only when the user explicitly requests Codex CLI, the lane tests Codex CLI-specific behavior, capable non-Codex builders are unavailable, or project evidence shows it is the best fit. Do not select it merely because the supervisor is Codex.

For parallel work, distribute independent responsibility areas when doing so improves delivery. Do not split a small task merely to demonstrate multiple agents, and do not place every critical-path lane with one builder. Active Codex remains an independent review and integration owner.

Record the selection before dispatch:

```md
## Builder Selection

Lane:
Required Capabilities:

| Builder | Health | Capability Fit | Risks | Decision |
|---|---|---|---|---|
| claude-builder | available | strong | higher latency | selected |
| bailian-opencode-builder | available | medium | limited systems context | fallback |
| codex-builder | available | strong | reserved by policy | not selected |

Selected:
Provider:
Model:
Reason:
Fallback:
```

## Lane Decomposition Rules

Classify the task before writing lanes:

| Size | Typical Shape | Default Plan |
|---|---|---|
| small | One responsibility, few files, one gate, no cross-module contract | One lane |
| medium | Multiple responsibilities with explicit dependencies | Two to four lanes |
| large | New subsystem, cross-module contracts, multiple platforms, high risk, or multiple independent deliverables | Split issues first, then split each issue into lanes |

A task must not be placed in one oversized lane when any of these apply:

- it combines public contracts, core implementation, tests, and documentation;
- it spans independent modules, platforms, or backends;
- the allowed files cross unrelated responsibility areas;
- one builder failure would block the entire core implementation;
- two or more independently verifiable outcomes can be defined;
- the builder prompt cannot be expressed as a bounded file and command list.

Split independent deliverables into issues. Within each issue, define execution responsibility as lanes and produce an acyclic dependency graph before dispatching non-trivial work:

```text
contract/API lane -> implementation lanes -> test lanes -> docs/release notes
                                      \\-> validation/integration lane
```

Use only the lane types needed by the issue:

| Lane Type | Responsibility |
|---|---|
| contract | Public API, schema, CLI, file format, and error semantics |
| core | Core business logic or algorithm |
| adapter | Platform, provider, database, or external-system integration |
| boundary | Input validation, exceptional paths, and edge behavior |
| tests | Black-box acceptance, unit, or integration tests |
| docs | User documentation, migration notes, and runbooks |
| validation | CI, validation scripts, and artifact checks |
| integration | Merge ownership, conflict resolution, full gates, and final evidence |

Active Codex owns the integration lane. A contract lane must be approved before dependent builders invent or consume its interfaces.

Rules:

- Start with a contract/API lane when later lanes need stable function names, schemas, CLI shape, or file layout.
- Run test lanes after the relevant API contract exists unless tests are explicitly written as black-box acceptance tests.
- Do not let documentation builders record runtime, CI, artifact, or review evidence before it exists.
- Split a lane again when it owns three or more major responsibilities, crosses unrelated directories, defines a contract and all consumers, or lacks one clear completion criterion.
- Keep documentation away from shared README or changelog files during parallel implementation unless the overlap is declared and Codex owns the merge.

When a lane genuinely cannot be split, record the exception in the Architecture Brief:

```md
## Lane Split Exception

Lane:
Reason It Cannot Be Split:
Shared Invariants:
Why Sequencing Does Not Help:
Selected Builder:
Risk Controls:
Additional Review:
```

### Builder Failure And Reassignment

Use this decision sequence instead of immediately replacing a builder:

```text
unavailable before dispatch
  -> select a capable fallback

timeout or empty output
  -> mark inconclusive
  -> inspect worktree, diff, and commits
  -> usable partial work?
       yes -> review it or create a focused repair lane
       no  -> redispatch in a clean, explicitly selected worktree

gate failure
  -> local implementation defect? -> repair lane or same builder repair
  -> contract defect? -> stop dependent lanes and return to Codex planning
```

Do not hand an existing worktree to a different builder until Codex has inspected and recorded its current changes.

## Evidence Trust Model

Builder statements are claims. Repository state and independently verified results are evidence. A builder's completion message, stdout, or test summary may guide inspection but cannot independently support approval.

### Evidence Levels

| Level | Evidence | Supported Decision |
|---|---|---|
| E0 | Builder statement, stdout, or summary text | Investigation lead only |
| E1 | Worktree files, `git diff`, and uncommitted changes | Proves that work was produced |
| E2 | Commit, changed-file list, and commit SHA | Proves a traceable delivery candidate |
| E3 | Gate, build, or test independently run by Codex | Proves local behavior for that SHA |
| E4 | Remote head SHA, CI jobs and steps, and artifacts | Proves remote automated validation |
| E5 | Final Codex review, plus an integration gate when multiple branches are accepted | Supports final workflow approval |

- Accepting a builder lane requires at least E1.
- Marking a builder lane complete requires E2 and E3.
- A task that promises remote delivery requires E4.
- Every completion decision requires a final Codex review. Multi-builder integration additionally requires the integration-gate part of E5, and remote approval must review the final PR head.
- Higher-level evidence does not excuse scope violations or missing semantic checks at a lower level.
- A successful CI run does not prove behavior that its tests and gates do not cover.

### Builder Result States

| State | Meaning |
|---|---|
| `reported` | The builder returned a claim that has not been inspected |
| `inconclusive` | Output or command status is insufficient to determine the work state |
| `partial` | Useful changes exist, but lane completion criteria are not met |
| `candidate` | A complete traceable change is waiting for independent validation |
| `verified` | Scope and independent gates passed for the lane |
| `rejected` | The change violates scope, gates, or security requirements |
| `blocked` | An external requirement prevents further progress |

Do not move directly from `reported` to `verified`.

```text
builder returns
  -> reported
  -> inspect repository
       no usable changes -> inconclusive | rejected
       usable incomplete changes -> partial
       complete traceable change -> candidate
  -> check scope and rerun gates
       pass -> verified
       implementation defect -> changes-requested
       external dependency missing -> blocked
```

### Builder Result Inspection

After every builder return, including a timeout, non-zero exit, or empty stdout, Codex must inspect:

1. the assigned branch and worktree;
2. staged, unstaged, and untracked files;
3. commits created by the builder and their SHAs;
4. the complete diff from the recorded baseline;
5. changed files against lane allowed and forbidden files;
6. whether the builder modified gate or ownership files;
7. generated files, caches, credentials, or unrelated changes;
8. whether claimed commands have reproducible evidence;
9. the required gates rerun independently by Codex;
10. the resulting accept, repair, reject, or block decision.

Record claims separately from observations:

```md
## Builder Result Inspection

Lane:
Builder:
Model:
Branch/Worktree:
Baseline Commit:
Reported Status:
Observed Status:

Repository Evidence:
- Commit:
- Changed files:
- Uncommitted changes:
- Forbidden changes:

Builder Claims:
- Tests:
- Build:
- Artifacts:

Independent Verification:
- Command:
- Working directory:
- Commit SHA:
- Exit code:
- Required markers:
- Skips or fallbacks:
- Artifact checks:

Decision:
verified | partial | changes-requested | rejected | blocked

Required Follow-up:
-
```

### Test And Artifact Evidence

A successful test record includes the actual command, working directory, exit code, relevant pass markers or test count, commit SHA, skipped checks or fallback paths, and artifact checks when applicable. A statement such as `tests passed` or `implementation complete` is E0 only.

For generated artifacts, record the path or remote name, non-empty size, required format or content checks, and digest when the delivery system provides one. Long logs may be summarized, but the summary must preserve failure counts, skips, fallbacks, and material warnings.

### Documentation And Remote Claims

Builders may write instructions, configuration-field descriptions, example commands, and output explicitly marked as an example. They must not present unobserved values as facts, including:

- issue, PR, review, or Actions URLs that do not yet exist;
- predicted commit SHAs or workflow results;
- fabricated performance or numerical results;
- artifact IDs, sizes, or digests that have not been observed;
- review decisions that Codex has not made.

Codex or trusted automation fills in execution evidence after it exists and records the corresponding SHA, run ID, or review ID.

For remote evidence, verify the workflow is associated with the expected final head SHA and PR, required jobs and key steps actually ran, skips and allowed failures are understood, required artifacts exist, and review state corresponds to the final head. The remote completion state machine is defined separately from this evidence model.

### Credential And Sensitive Output Handling

Do not place API keys, bearer tokens, authorization headers, complete secret environment values, credential-bearing configuration, or authentication debug logs in diffs, prompts, workflow records, or review comments.

Workflow evidence may record environment variable names, credential source type, provider, non-secret base URL, authenticated identity, and a permission summary. If a credential appears in a diff or retained log, mark the result `rejected` or `blocked` and begin credential containment. Removing the visible file alone is not sufficient evidence that exposure has been resolved.

## Worktree Lifecycle

An isolated worktree provides execution isolation, not merge safety. A passing builder branch does not prove that the integrated result passes, and an automatic merge does not prove semantic compatibility.

Each builder lane should have a unique lane ID, branch, worktree, runtime directory, and recorded baseline SHA. A small single-builder task may use only an isolated branch when Codex has recorded how it relates to existing user changes.

### Before Creation

- Confirm the lane, allowed files, gate, dependencies, and builder have been approved.
- Record the baseline SHA.
- Confirm the branch and worktree names are unique.
- Confirm the destination does not collide with an existing worktree or directory.
- Confirm the builder health check passed.

Recommended naming:

```text
branch: agent/issue-<id>/<lane-id>-<short-name>
worktree: ../<repo>-worktrees/issue-<id>-<lane-id>
```

### During Execution

- The builder works only in its assigned worktree and does not switch to another lane branch.
- The builder does not modify the main worktree or reuse another builder's mutable runtime directory.
- The builder does not perform global cleanup or destructive filesystem operations.
- When the assigned scope is insufficient, the builder stops and requests a Codex scope decision instead of expanding it.

### After Builder Return

Record the branch, worktree, baseline SHA, head SHA, commits, uncommitted changes, changed files, gate result, and whether the worktree must be retained for repair.

### Cleanup

Clean a worktree only after its content is merged, rejected, or explicitly abandoned; all changes and integration evidence are recorded; and no repair is pending. Verify the absolute cleanup target before removal. Test worktrees are retained by default unless the user or a separate approved cleanup step requests removal.

## Overlap Policy

Independent worktrees make overlapping edits technically possible, but they do not make conflicts free.

Overlap levels:

| Level | Meaning | Default Action |
|---|---|---|
| none | Lanes edit disjoint files | Safe for parallel dispatch |
| declared-shared | Lanes edit shared docs, scripts, tests, or generated integration files | Parallel allowed if Codex is merge owner |
| semantic-overlap | Lanes edit the same source file, public API, schema, or test file | Prefer sequencing or require explicit merge plan |
| forbidden-overlap | Lanes edit gates, workflow config, secrets, or ownership boundaries outside scope | Reject or require new Codex approval |

Every lane that allows overlap must declare shared files or patterns, expected overlap type, merge owner, merge order, and conflict resolution rule.

For `declared-shared` overlap, record:

```md
Shared Files:
Overlap Reason:
Expected Contributions:
Merge Owner:
Merge Order:
Authoritative Lane:
Conflict Strategy:
Post-Merge Validation:
```

The authoritative lane owns the base structure of a shared file. Other lanes provide candidate changes for the merge owner to evaluate.

Allow parallel `semantic-overlap` only when the Architecture Brief explains the benefit, each lane has independently defined behavior, an authoritative implementation and explicit merge strategy exist, the integration owner has relevant context, and integration tests cover the combined behavior. Otherwise, sequence the lanes. Builders must not merge each other's overlapping branches and declare the result final.

## Integration Ownership

Active Codex is the merge owner for multi-builder work unless the user explicitly assigns a human maintainer. The merge owner determines merge order, checks evidence and lane scope, rejects unverified changes, resolves allowed conflicts, records integration fixes, runs the integration gate, and decides whether a repair lane is required.

Default merge order is:

```text
contract
  -> core
  -> adapters and boundaries
  -> tests
  -> validation
  -> docs
  -> final evidence updates
```

The approved lane graph overrides this default. Documentation containing runtime or remote evidence is updated after the relevant implementation and verification so it does not capture an obsolete SHA or run.

## Integration Branch

When two or more builder branches are accepted, use an independent integration branch or a merge queue with equivalent combined validation. The recommended branch is `integration/issue-<id>`.

Create the integration branch from the recorded baseline or intended base branch, not from an arbitrary builder branch. Record every accepted merge:

```md
## Integration Merge Record

Issue:
Integration Branch:
Baseline SHA:

| Order | Lane | Builder Branch | Builder Head | Evidence | Result |
|---|---|---|---|---|---|
| 1 | contract | | | E3 | merged |
| 2 | core | | | E3 | merged |

Conflict Resolution:
-

Integration Fixes:
-

Final Integration SHA:
```

### Conflict Classification

| Conflict Type | Required Action |
|---|---|
| mechanical | Codex may resolve independent formatting, imports, or non-semantic line conflicts |
| contract | Stop dependent lanes and return the decision to the contract owner |
| behavioral | Use acceptance criteria and domain gates or create a repair lane; merge success is insufficient |
| test | Resolve against the approved contract and acceptance criteria |
| documentation | Rewrite against final implementation and observed evidence |
| security or ownership | Exclude the change until scope is explicitly approved |

Non-mechanical integration fixes made by Codex must list the files and reason, run the affected gates, and appear separately in the Integration Merge Record. Do not attribute those fixes to a builder.

## Integration Gate

After all accepted builder branches are combined, run an integration gate that covers:

- the complete relevant build and test set;
- cross-lane contracts and interfaces;
- required target platforms or explicitly recorded fallback paths;
- artifact generation, format, and content;
- lane scope and protected gate files;
- unresolved conflict markers;
- documentation consistency with final behavior.

```text
integration gate fails
  -> integration-blocked
  -> classify failure
       lane-local defect -> focused repair lane
       contract mismatch -> reopen contract decision
       merge defect -> recorded Codex integration fix
       environment issue -> blocked with evidence
  -> rerun the complete affected gate set
```

Individual builder branches passing their own gates never removes the integration-gate requirement.

## Remote Delivery Lifecycle

Local success does not prove remote delivery. A successful workflow does not prove that all required jobs, steps, and artifacts were verified. Review of an older head does not approve a newer head.

Select the target completion level in the issue or Architecture Brief before remote work begins:

| Level | Completion Condition |
|---|---|
| `local-complete` | Local implementation and gates pass |
| `pr-complete` | PR is ready and final-head CI, required artifacts, and Supervisor Check pass |
| `merge-complete` | PR is merged and the issue state matches the plan |
| `delivery-complete` | Required post-merge build, release, or deployment is verified |

```text
remote-required
  -> issue-created
  -> branch-pushed
  -> draft-pr-open
  -> ci-running
  -> ci-verified
  -> artifacts-verified | artifacts-not-required
  -> supervisor-reviewed
  -> ready-for-review
  -> optional human approval
  -> optional merge
  -> optional post-merge verification
  -> remote-complete
```

A new PR commit makes prior `ci-verified`, `artifacts-verified`, and `supervisor-reviewed` evidence stale until the new head is checked.

### Issue Record

The remote issue contains or links the goal, scope and out-of-scope items, acceptance criteria, risks, gates, lane graph, target completion level, and whether automatic merge is allowed.

Record the issue URL, number, creator, initial state, and acceptance-criteria version from GitHub's response. Do not infer the final title, number, labels, or URL from a template.

### Push Verification

After pushing, compare the local and remote head SHA and confirm the remote URL and branch are the intended destination. Record whether history was rewritten. A mismatch produces `remote-blocked: head-mismatch`.

Force-push is disabled by default for builder and integration branches. It requires explicit user approval and invalidates prior remote evidence.

```md
Branch:
Local Head:
Remote Head:
Remote:
Push Result:
History Rewritten: no
```

### Pull Request Verification

Open remote workflow PRs as drafts by default unless the project defines another policy. Confirm the linked issue, base, head branch, head SHA, title, scope, builder/model/lane record, gates, risks, and fallback information.

Do not insert unobserved CI, artifact, review, or merge evidence into the PR description.

```text
draft-pr-open
pr-blocked: wrong-base
pr-blocked: wrong-head
pr-blocked: missing-issue
pr-blocked: incomplete-description
```

### GitHub Actions Verification

Do not rely only on a workflow run's top-level conclusion. Verify:

1. repository, event, and target PR;
2. current PR head SHA;
3. workflow and run attempt;
4. all required jobs and their conclusions;
5. key steps actually executed;
6. skipped, neutral, or allowed-failure results are understood;
7. test, build, and validation evidence matches the gates;
8. reruns are recorded and the latest valid attempt is used.

Use `ci-running`, `ci-verified`, `ci-failed`, `ci-inconclusive`, or `ci-stale`. A head change makes an older run `ci-stale` for final approval.

### Artifact Verification

When the issue or gate requires an artifact, verify its name, run ID, head SHA, non-empty size, expiration state, required format or contents, producing job, download or platform reference, and digest when available.

Use `artifacts-verified`, `artifacts-missing`, `artifacts-invalid`, or `artifacts-stale`. When no artifact is required, record `artifacts-not-required` rather than claiming verification.

### Final-Head Supervisor Review

Review the final PR diff against the issue, acceptance criteria, gates, lanes, integration record, CI jobs and steps, artifacts, and known fallback paths.

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

Evidence:
-

Required Fixes:
-
```

`approve` is a Codex workflow decision and is not necessarily a native GitHub approval. GitHub may prevent a PR author from approving their own PR; do not misrepresent the platform review state.

After any new commit, inspect the incremental diff, rerun affected local and integration gates, wait for CI on the new head, verify required artifacts for that head, and publish a new final-head Supervisor Check. Documentation-only changes may reduce the local gate scope, but old CI must not be attributed to the new head.

### Draft To Ready

Move a draft PR to ready only when:

- the expected final head SHA is confirmed;
- required CI and artifacts are verified for that head;
- the integration gate, lane scope, and protected-file checks pass;
- a final-head Supervisor Check exists;
- no blocker or unmarked placeholder and fabricated evidence remains.

Read the PR again after the transition and confirm it is open, `draft=false`, has the expected head, and is mergeable or in a project-accepted pending mergeability state. Wait when GitHub reports mergeability as unknown.

### Merge Boundary

Do not merge by default. Merge only when the user explicitly requests it or project configuration authorizes it, branch protection and required reviews are satisfied, final-head evidence is current, the merge method is known, review threads are resolved, issue closure behavior is understood, and required post-merge checks are defined.

After merge, verify the merged state, merge commit SHA, base branch contents, issue state, and required post-merge workflow, release, or deployment. A task targeting `pr-complete` stops at a ready PR and does not silently advance to `merge-complete`.

### Remote Completion Record

```md
## Remote Completion Record

Target Completion Level:
Repository:
Issue:
PR:
Base:
Head:
Final Head SHA:
Push Verified:
CI Run:
CI Conclusion:
Required Jobs:
Artifacts:
Supervisor Check:
PR State:
Mergeable:
Merged:
Merge Commit:
Issue State:
Post-Merge Run:

Decision:
local-complete | pr-complete | merge-complete | delivery-complete | blocked
```

## Failure And Recovery State Machine

Classify a failure by stage before choosing a recovery action. Preflight, builder invocation, implementation, lane gates, integration, remote delivery, security, and human decisions have different recovery paths.

### Unified States

| State | Meaning | Terminal Scope |
|---|---|---|
| `pending` | Work has not started | no |
| `running` | Work is executing | no |
| `reported` | Builder returned; inspection is pending | no |
| `inconclusive` | Current evidence cannot determine the result | no |
| `partial` | Useful work exists but is incomplete | no |
| `candidate` | Traceable work awaits independent validation | no |
| `verified` | Current lane passed scope and gates | lane terminal |
| `changes-requested` | A diagnosed defect requires repair | no |
| `preflight-blocked` | A dispatch prerequisite is missing | no |
| `integration-blocked` | Combined work failed integration validation | no |
| `remote-blocked` | GitHub delivery cannot currently continue | no |
| `security-blocked` | Credentials or security boundaries may be compromised | no |
| `rejected` | The current candidate is unacceptable | candidate terminal |
| `cancelled` | The user or project explicitly cancelled the task | task terminal |
| `complete` | The selected completion level was reached | task terminal |

A blocked state is recoverable by default. Resume from an explicit checkpoint after its condition is corrected.

### Preflight Failure

On a Git, baseline, ambiguous-worktree, builder-health, remote-permission, or lane-graph failure, do not dispatch. Correct the blocking item, rerun its preflight level, and rerun later levels when the underlying state changed. Baseline, credential, scope, and gate blockers cannot be waived as warnings.

### Builder Invocation Failure

For a CLI startup failure, provider outage, timeout, empty stdout, or wrapper error:

1. mark the result `inconclusive`;
2. inspect the worktree, diff, and commits;
3. promote usable work to `partial` or `candidate`;
4. return configuration defects to preflight;
5. retry transient failures only within the retry policy;
6. choose a capable fallback when no usable work exists.

Never clear or reuse a worktree before recording its state.

### Implementation Failure

Use the original builder for a small defect within the approved lane. Create a focused repair lane when the original builder is unavailable or independent repair is safer. Replan dependencies when the defect crosses lanes, and stop dependent lanes when the approved contract is wrong.

When the failure reveals missing scope, update the issue, lane, and gate and obtain approval before implementation continues. Builders must not expand scope as an incidental repair.

### Gate Failure

Diagnose whether the cause is implementation, test, gate, environment, or test instability. Builders must not weaken a gate to make their implementation pass. A genuine gate defect requires a separately recorded Codex approval. Record flaky failures rather than rerunning until green.

After repair, rerun the affected gates. Rerun the complete relevant gate set when public contracts, integration behavior, or shared validation changes.

### Integration Failure

```text
integration-blocked
  -> preserve integration SHA and failure evidence
  -> classify lane-local | contract | merge | environment | undeclared-overlap
  -> create a repair lane or a recorded Codex integration fix
  -> rerun the complete affected integration gate
```

Do not rewrite verified builder branch history or attribute an integration repair to the original builder.

### Remote Failure

Use `remote-blocked` for authentication, permission, remote, base, or head mismatches. Use `inconclusive` while CI or GitHub mergeability is still being computed. A confirmed code-related CI failure becomes `changes-requested`; a run on an old head becomes `ci-stale`; missing or invalid artifacts retain their artifact-specific failure state.

Retry only transient network or platform faults. Code, configuration, scope, and contract failures require diagnosis and repair.

### Security Failure

Enter `security-blocked` when credentials enter a diff, commit, retained log, or PR; the wrong identity accesses the remote; a builder receives excessive permissions; an unknown script requests sensitive information; or a supply-chain compromise is suspected.

1. Stop builders and publication.
2. Preserve event evidence without retaining the secret value.
3. Determine the exposure scope and notify the user.
4. Revoke or rotate affected credentials.
5. Obtain separate approval before rewriting history or remote records.
6. Establish and verify a new security baseline before resuming.

Deleting a visible local file is not sufficient proof of containment.

### Retry Policy

Automatically retry at most once for a transient network error, provider rate limit, pending GitHub computation, or CLI startup failure confirmed to have produced no changes. Record the reason and outcome.

Do not automatically retry compilation or test failures, scope violations, contract mismatches, credential exposure, incorrect identity, destructive-operation risk, or a repeated identical failure.

```text
first occurrence -> diagnose and apply targeted recovery
second same occurrence -> reassess root cause and recovery design
third same occurrence -> stop automatic retries and request user or external-state change
```

Changing builders does not remove the requirement to diagnose a repeated root cause.

### Repair Lane

```md
## Repair Lane

Source Lane:
Failure Evidence:
Root Cause:
Repair Scope:
Allowed Files:
Forbidden Files:
Builder:
Dependencies:
Required Gates:
Integration Point:
```

A repair lane should be narrower than its source lane. A broader repair indicates that Codex should replan the task.

### Resume Checkpoints

| Blocked Stage | Resume Checkpoint |
|---|---|
| preflight | affected preflight level |
| builder invocation | builder health or existing worktree inspection |
| lane gate | repair commit and lane gate |
| integration | preserved integration SHA and complete affected gate |
| remote | current remote head SHA |
| security | new security baseline after user-confirmed containment |

Do not reuse stale CI, artifact, or review evidence after recovery.

### Workflow Failure Record

```md
## Workflow Failure Record

Failure ID:
Time:
Stage:
Issue:
Lane:
Builder:
Branch/Worktree:
Baseline SHA:
Observed Head SHA:
Status:

Symptom:
Evidence:
Root Cause:
Affected Scope:

Recovery Decision:
Retry Count:
Repair Lane:
Required User Action:
Resume Checkpoint:

Final Resolution:
```

Ask the user before creating or repairing a repository, deciding ownership of ambiguous user changes, changing scope or acceptance criteria, force-pushing or rewriting history, rotating credentials, expanding builder permissions, merging or deploying, choosing among behavior-changing alternatives, or continuing after the same blocker occurs three times.

## Dispatch Block

Use the canonical dispatch template at `docs/builder-dispatch-template.md`. Each invocation records the actual builder, provider, model, health evidence, baseline, lane/gate versions, branch/worktree, scope, validation, delivery destination, and required return. A lane PR is required only when that dispatch or project policy says so.

## Source Of Truth

- GitHub issue: task scope and acceptance criteria.
- `docs/gates/`: validation commands and pass criteria.
- `docs/lanes/`: builder scope and allowed files.
- PR: remote integration and review artifact when the selected completion level requires one.
- CI: remote deterministic validation signal when required.
- Codex review: final workflow decision.
- Integration branch: combined proof when two or more builder branches are accepted.

