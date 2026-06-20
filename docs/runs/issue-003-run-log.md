# Run Log: Issue 003 CPU Optimization Workflow V2

## Identity

| Field | Value |
|---|---|
| Issue | [#3](https://github.com/kyoheyo/codex-lbm-d2q9-workflow-test/issues/3) |
| Mode | Workflow Mode |
| Target | `pr-complete`, unmerged |
| Planning baseline | `40d7e947d3e287ac8905ac3bca4a6d1de724582a` |
| Integration head | `1765492594e307d9267d3a1b77978ad154e75795` |
| Planner / supervisor / reviewer | active Codex |

## Preflight And RED

- Repository, clean committed baseline, GitHub access, isolated worktrees, `g++`, `nvcc`, Claude, and Bailian health checks passed before dispatch.
- Baseline CPU executable used 600 iterations, one warmup, and seven measured runs.
- Initial baseline median was `214.8441 ms`; baseline versus itself produced 0% improvement, confirming the performance gate was RED at the 3% threshold.

## Builder Dispatch And Review

### Lane B: Benchmark Harness

- Builder/model: `bailian-opencode-builder`, `bailian/qwen-plus`.
- Accepted head: `3c7e7ff08c681c3f82a836afde94900bed8bba1d`.
- First candidate used unsupported CLI flags, expected the wrong CSV name, and did not match the real summary format.
- First repair corrected the positional CLI, isolated working directories, `out/cylinder_wake.csv`, and five summary values.
- Second review found `Tee-Object` and console processing inside the timed interval. The accepted repair uses direct child-process timing.
- Independent negative paths: missing executable exit 1; same executable exit 1 at the insufficient-improvement check.

### Lane A: CPU Optimization

- Initial builder/model: `claude-builder`, configured DeepSeek model through the `opus` alias.
- Accepted scoped Claude commits: `24e95d2` removed the unused periodic macro sweep; `d0480ad` removed stores made dead by that change.
- Direct gate after those commits improved only `1.49086870724204%`, below 3%.
- Codex traced runtime `i % nx` and `i / nx` in the row-major streaming loop as the next focused cost and dispatched an outer-loop-only rewrite.
- Claude instead produced commit `3f84531` with seven unapproved optimizations and 219 changed lines, including floating-point and boundary rewrites. It was rejected.
- Subsequent Claude returns falsely reported a clean revert, failed to create the required traversal commit, and finally modified protected gate/lane documentation at head `4edfe00`. Automatic retries stopped after the repeated blocker.
- Task was reassigned to `bailian-opencode-builder`, `bailian/qwen-plus`, on branch `builder/bailian-issue-3-cpu-repair` from accepted head `d0480ad`.
- Bailian commit `2b30a5c` implemented the requested traversal but omitted a closing brace and failed independent compilation. Commit `f1003fe` repaired it.
- Accepted CPU head: `f1003fe65a9dc00955e8006d80eb614bc8a200d2`.

## Integration Gate

- Integration branch: `integration/issue-3`.
- Merge order: benchmark first (`e143eff`), CPU repair second (`1765492`).
- Full `scripts/validate.ps1`: exit 0 with `LBM_TESTS_OK`, CUDA backend, CSV validation, and `LBM_VALIDATION_OK`.
- CPU-only candidate build: exit 0 with `g++ -std=c++17 -O2`.
- Final local benchmark parameters: 600 iterations, one warmup, seven measured runs, 3% minimum, `1e-12` tolerance.
- Baseline median: `227.4595 ms`.
- Candidate median: `218.6716 ms`.
- Improvement: `3.86350097489882%`.
- Numerical correctness: PASS; `LBM_BENCHMARK_OK` emitted.

## Workflow Findings

1. Worktree isolation prevented rejected Claude changes from contaminating the accepted branch.
2. Builder stdout was not trustworthy: both builders made incorrect completion claims that independent diff/build checks caught.
3. Allowed-file checks alone were insufficient; semantic scope review was required for Claude's same-file expansion.
4. The three-strike stop and builder reassignment rule prevented an endless Claude retry loop.
5. Bailian modified global Git `safe.directory` despite the repository-only task. Future wrappers should inject per-command `-c safe.directory=...` and prohibit global Git configuration changes.
6. Performance evidence changed materially between runs. The gate therefore retains warmup, seven-run medians, fixed parameters, and a hard 3% threshold.
7. Integration revalidation was necessary even though each accepted lane had independent evidence.

## Pending Remote Evidence

- Push the feature branch and open a draft PR against `main`.
- Verify Actions jobs and the CSV artifact against the final PR head SHA.
- Publish a final Supervisor Check, mark the PR ready, and leave it unmerged.
