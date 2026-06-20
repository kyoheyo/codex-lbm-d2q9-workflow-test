# Architecture Brief: issue-003

## Identity

Issue: [#3](https://github.com/kyoheyo/codex-lbm-d2q9-workflow-test/issues/3)
Mode: Workflow
Target Completion Level: pr-complete
Repository: kyoheyo/codex-lbm-d2q9-workflow-test
Baseline SHA: recorded after this planning set is committed
Remote Delivery Required: yes
Merge Authorized: no

## Problem

The CPU solver recomputes the complete macroscopic field every ten iterations even though no intermediate summary is printed or consumed. The same field is recomputed after the final iteration for the returned field and summary. This creates avoidable work in a compact validation solver.

The task must also prove that the corrected workflow rules reliably handle committed planning baselines, per-lane builder selection, isolated worktrees, evidence inspection, integration gates, performance evidence, final-head CI, and artifacts.

## Scope

Included:

- Remove only the unused periodic CPU macroscopic sweep.
- Preserve the final macroscopic field, summary, CSV, public API, and numerical boundary behavior.
- Add a CPU-only benchmark harness that compares prebuilt baseline and candidate executables.
- Validate local CPU performance, existing tests, local CUDA behavior, remote CPU fallback, and artifact output.

Out Of Scope:

- CUDA optimization or kernel changes.
- Public API and CLI changes.
- Boundary-condition or numerical-model changes.
- Automatic merge of the Issue #3 PR.

## Proposed Design

Lane A makes a minimal refactor in `src/lbm_cpu.cpp`: remove the periodic summary block inside the time-stepping loop and retain the existing final macroscopic and summary calculation. Lane B adds a PowerShell benchmark harness that runs two CPU-only executables with one warmup and seven measured runs, parses their summaries, compares CSV output, computes median wall time, and emits structured markers.

The lanes edit disjoint files and depend only on this approved contract. Codex owns baseline measurement, builder inspection, integration, correctness comparison, performance judgment, remote delivery, and final review.

## Contracts

| Contract | Owner | Version | Consumers | Compatibility Rule |
|---|---|---|---|---|
| `lbm::runCpu` behavior | Codex | existing API at planning baseline | lane-a, integration | No signature or numerical behavior change |
| CLI `main.exe <iterations>` | Codex | existing CLI | lane-b, integration | Exit 0 and existing summary markers |
| Benchmark output | Codex | v1 | integration/review | Emit baseline median, candidate median, improvement percent, correctness result, and `LBM_BENCHMARK_OK` |

## Acceptance Criteria

- AC-1: Existing unit tests and validation pass.
- AC-2: Baseline and candidate summaries and CSV values are equivalent within `1e-12`.
- AC-3: Candidate median CPU runtime improves by at least 3% using 600 iterations, one warmup, and seven measured runs on the same machine.
- AC-4: Local CUDA validation remains successful.
- AC-5: Builder changes remain within declared file scopes.
- AC-6: Final-head GitHub Actions and CSV artifact pass.
- AC-7: The PR reaches ready/pr-complete and remains unmerged.

## Lane Dependency Graph

```text
planning/performance RED baseline
  |-> lane-a-cpu-opt
  |-> lane-b-benchmark
  \-> Codex integration -> local gates -> draft PR -> remote gates -> ready
```

## Lanes

| Lane | Type | Goal | Allowed Files | Depends On | Overlap | Builder | Gate |
|---|---|---|---|---|---|---|---|
| lane-a-cpu-opt | core/refactor | Remove unused periodic CPU macro sweeps | `src/lbm_cpu.cpp` | planning baseline | none | claude-builder / DeepSeek | issue-003-lane-a |
| lane-b-benchmark | validation | Add CPU comparison benchmark | `scripts/benchmark_cpu.ps1` | planning baseline | none | bailian-opencode-builder / Qwen Plus | issue-003-lane-b |
| integration | integration | Merge and independently validate | workflow evidence only | lanes A and B | none | active Codex | issue-003-integration |

## Integration Plan

Integration Required: yes
Integration Branch: `integration/issue-3`
Integration Owner: Codex Supervisor
Merge Order: lane-b benchmark, then lane-a optimization
Integration Gate: `docs/gates/issue-003-integration.md`

The benchmark lane is merged first so the performance test exists before the production optimization is accepted into integration.

## Risk And Recovery

- Timing noise: use warmup, seven runs, median, same compiler, same machine, and same iteration count.
- Performance threshold failure: request one focused repair; do not lower 3%.
- Numerical mismatch: reject or repair the optimization before remote delivery.
- Builder timeout/empty output: inspect the worktree and commits before retry or reassignment.
- CUDA regression: changes-requested; CUDA files are outside builder scope.

## Remote Boundary

Create a draft PR against `main`, verify current-head Actions jobs and CSV artifact, publish a final-head Supervisor Check, mark ready, and leave the PR unmerged.
