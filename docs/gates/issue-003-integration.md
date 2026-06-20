# Gate: issue-003-integration

## Identity

Issue: #3
Gate Type: integration
Owner: Codex
Target Completion Level: pr-complete

## Accepted Lanes

| Lane | Branch | Head SHA | Evidence |
|---|---|---|---|
| lane-b-benchmark | `builder/bailian-issue-3-benchmark` | pending | independent lane inspection |
| lane-a-cpu-opt | `builder/claude-issue-3-cpu-opt` | pending | independent lane inspection |

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
