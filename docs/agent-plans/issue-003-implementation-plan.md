# LBM CPU Efficiency Workflow V2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove redundant CPU LBM work, prove at least 3% median improvement without numerical change, and complete the corrected pr-complete workflow.

**Architecture:** Codex commits the contract and gates first. A benchmark lane and a one-file CPU optimization lane execute in isolated worktrees, then Codex integrates benchmark first, optimization second, and independently verifies local and remote evidence.

**Tech Stack:** C++17, CUDA, PowerShell 7, Git worktrees, GitHub Issues/PR/Actions, Claude Code builder, OpenCode builder.

---

### Task 1: Commit Planning Baseline

**Files:**
- Create: `docs/agent-plans/issue-003.md`
- Create: `docs/gates/issue-003-*.md`
- Create: `docs/lanes/issue-003-*.md`
- Sync: corrected workflow rules and templates

- [ ] Record Issue #3 and target `pr-complete`.
- [ ] Commit all control files before builder dispatch.
- [ ] Record the resulting planning baseline SHA.
- [ ] Run Workflow Preflight against that SHA.

### Task 2: Establish Performance RED Baseline

**Files:**
- Generated only: `build/perf-baseline/**`, `out/perf-baseline/**`

- [ ] Build a CPU-only baseline executable with `g++ -std=c++17 -O2`.
- [ ] Run one warmup and seven measured 600-iteration runs.
- [ ] Record all durations and their median.
- [ ] Confirm the unoptimized baseline cannot satisfy a 3% improvement against itself; this is the performance RED condition.
- [ ] Preserve baseline executable and CSV for later candidate comparison.

### Task 3: Benchmark Harness Lane

**Files:**
- Create: `scripts/benchmark_cpu.ps1`

- [ ] Implement parameters for baseline executable, candidate executable, iterations, warmup count, measured runs, tolerance, and minimum improvement.
- [ ] Run each executable in isolated output directories.
- [ ] Parse summary fields and CSV data.
- [ ] Fail on numerical mismatch, malformed output, non-zero exit, or insufficient improvement.
- [ ] Emit `LBM_BENCHMARK_OK` only after all checks pass.
- [ ] Commit on `builder/bailian-issue-3-benchmark`.

### Task 4: CPU Optimization Lane

**Files:**
- Modify: `src/lbm_cpu.cpp`

- [ ] Inspect the periodic summary block and prove it has no observable consumer.
- [ ] Remove only the redundant periodic full-field macro and summary sweep.
- [ ] Preserve final macroscopic and summary calculation.
- [ ] Run existing unit tests and CPU validation.
- [ ] Commit on `builder/claude-issue-3-cpu-opt`.

### Task 5: Integration And GREEN Verification

**Files:**
- Record: integration evidence in the PR/run log

- [ ] Create `integration/issue-3` from the planning baseline.
- [ ] Merge benchmark lane, inspect scope, and validate the harness.
- [ ] Merge optimization lane and inspect scope.
- [ ] Build candidate CPU-only executable with identical flags.
- [ ] Run the benchmark gate; expected result is at least 3% median improvement and `LBM_BENCHMARK_OK`.
- [ ] Run `scripts/validate.ps1`; expected markers are `LBM_TESTS_OK` and `LBM_VALIDATION_OK`.
- [ ] Confirm local CUDA backend still executes.

### Task 6: Remote pr-complete

**Files:**
- Update: PR body and remote evidence records only with observed values

- [ ] Push feature branch and open a draft PR against `main`.
- [ ] Confirm PR head equals the pushed integration head.
- [ ] Verify current-head Actions required jobs and steps.
- [ ] Verify CSV artifact name, run/head, non-empty size, and digest when available.
- [ ] Publish a final-head Supervisor Check.
- [ ] Mark PR ready and verify `draft=false`.
- [ ] Leave PR open and unmerged.

### Task 7: Completion Audit

- [ ] Map AC-1 through AC-7 to current evidence.
- [ ] Confirm no stale CI, artifact, or review evidence.
- [ ] Confirm builder changes stayed within lane scopes.
- [ ] Record workflow stability findings and unresolved automation limitations.
