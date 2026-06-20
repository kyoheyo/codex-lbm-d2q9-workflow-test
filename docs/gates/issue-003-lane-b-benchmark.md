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

Record builder head SHA, complete baseline diff, negative-path checks, and Codex independent execution.
