# Gate: issue-003-integration

## Identity

Issue: #3
Gate Type: integration
Owner: Codex
Target Completion Level: pr-complete

## Accepted Lanes

| Lane | Branch | Head SHA | Evidence |
|---|---|---|---|
| lane-b-benchmark | `builder/bailian-issue-3-benchmark` | `3c7e7ff08c681c3f82a836afde94900bed8bba1d` | negative paths and independent execution passed |
| lane-a-cpu-opt | `builder/bailian-issue-3-cpu-repair` | `f1003fe65a9dc00955e8006d80eb614bc8a200d2` | reassigned repair, scope and independent validation passed |

## Commands

```powershell
powershell -ExecutionPolicy Bypass -File scripts\validate.ps1
powershell -ExecutionPolicy Bypass -File scripts\benchmark_cpu.ps1 -BaselineExe <baseline> -CandidateExe <candidate> -Iterations 600 -WarmupRuns 1 -MeasuredRuns 7 -MinimumImprovementPercent 3.0 -NumericTolerance 1e-12
```

## Pass Criteria

- `LBM_TESTS_OK`, `LBM_VALIDATION_OK`, and `LBM_BENCHMARK_OK` appear.
- Baseline and candidate summary/CSV values agree within `1e-12`.
- Candidate median runtime improves by at least 3%.
- Local validation uses CUDA when available and succeeds.
- No unresolved conflict markers or builder scope violations exist.
- Final-head Actions passes and the CSV artifact is valid.
- Final Supervisor Check supports `pr-complete`.

## Local Integration Evidence

- Integration head: `1765492594e307d9267d3a1b77978ad154e75795`.
- Merge order: benchmark branch first, CPU repair branch second.
- `scripts/validate.ps1`: exit 0; `LBM_TESTS_OK`; CUDA backend; `LBM_VALIDATION_OK`.
- CPU benchmark: baseline median `227.4595 ms`; candidate median `218.6716 ms`; improvement `3.86350097489882%`.
- Numerical comparison: PASS at configured tolerance; `LBM_BENCHMARK_OK` emitted.
- Remote Actions, artifact, and final Supervisor Check remain pending until the feature branch is pushed and the PR is created.
