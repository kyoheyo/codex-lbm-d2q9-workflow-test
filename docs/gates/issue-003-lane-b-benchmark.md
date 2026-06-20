# Gate: issue-003-lane-b-benchmark

## Identity

Issue: #3
Lane: lane-b-benchmark
Gate Type: lane
Owner: Codex
Target Completion Level: pr-complete

## Goal

Prove that the benchmark harness compares two prebuilt CPU executables reproducibly and fails closed on numerical or performance defects.

## Required Interface

```powershell
./scripts/benchmark_cpu.ps1 -BaselineExe <path> -CandidateExe <path> -Iterations 600 -WarmupRuns 1 -MeasuredRuns 7 -MinimumImprovementPercent 3.0 -NumericTolerance 1e-12
```

## Pass Criteria

- Changed files are exactly `scripts/benchmark_cpu.ps1`.
- Missing executables and non-zero child exit codes fail.
- Summary and CSV numerical mismatch beyond tolerance fails.
- Candidate improvement below 3% fails.
- Median calculation uses all seven measured runs.
- Success prints baseline/candidate medians, improvement percentage, correctness result, and `LBM_BENCHMARK_OK`.
- Builder does not modify `docs/gates/**`.

## Evidence

Decision: accepted after two review repairs.

- Accepted branch: `builder/bailian-issue-3-benchmark`
- Accepted head: `3c7e7ff08c681c3f82a836afde94900bed8bba1d`
- Changed files against the planning baseline: exactly `scripts/benchmark_cpu.ps1`.
- Missing baseline executable: independent process exit 1.
- Same executable as baseline and candidate: independent process exit 1 at the insufficient-improvement check, after interface and numerical parsing succeeded.
- Initial implementation used unsupported `-i/-o` arguments and the wrong CSV path; commit `1001ef1` repaired the real CLI and output contract.
- Initial timing used `Tee-Object` inside the measured interval; commit `3c7e7ff` replaced it with direct child-process timing.
- Integration success emitted baseline/candidate medians, numerical PASS, and `LBM_BENCHMARK_OK`.
