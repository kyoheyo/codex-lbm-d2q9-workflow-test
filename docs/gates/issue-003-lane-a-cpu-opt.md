# Gate: issue-003-lane-a-cpu-opt

## Identity

Issue: #3
Lane: lane-a-cpu-opt
Gate Type: lane
Owner: Codex
Target Completion Level: pr-complete

## Goal

Prove that the CPU optimization changes only redundant internal work and preserves existing observable behavior.

## Pass Criteria

- Changed files are exactly `src/lbm_cpu.cpp`.
- Public APIs, CUDA code, boundary conditions, and final summary logic are unchanged.
- CPU-only build succeeds with `g++ -std=c++17 -O2`.
- Existing unit tests pass with `LBM_TESTS_OK`.
- CPU validation exits zero with `LBM_VALIDATION_OK`.
- Builder does not modify `docs/gates/**`.

## Evidence

Decision: accepted after builder reassignment.

- Accepted branch: `builder/bailian-issue-3-cpu-repair`
- Accepted head: `f1003fe65a9dc00955e8006d80eb614bc8a200d2`
- Accepted commits include the two scoped Claude commits at `24e95d2` and `d0480ad`, followed by the Bailian traversal repair at `2b30a5c` and `f1003fe`.
- Changed files against the planning baseline: exactly `src/lbm_cpu.cpp`.
- Codex independent `scripts/validate.ps1`: exit 0 with `LBM_TESTS_OK`, CUDA execution, and `LBM_VALIDATION_OK`.
- Codex independent CPU-only build: exit 0 with `g++ -std=c++17 -O2`.
- Claude head `4edfe00` was rejected because it retained an out-of-scope optimization commit and modified protected gate/lane documentation.
- Bailian repair commit `2b30a5c` initially failed compilation because one closing brace was missing; `f1003fe` fixed the defect and passed independent validation.
