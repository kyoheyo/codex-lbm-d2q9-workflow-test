# Remote Multi-Agent D2Q9 CUDA LBM Test

This repository validates the complete GitHub + Codex + external-builder workflow:

- remote GitHub issue;
- split builder lanes in Git worktrees;
- integration branch and pull request;
- GitHub Actions;
- Codex supervisor review;
- a D2Q9 LBM cylinder-wake example with a CUDA backend and CPU fallback.

The implementation is intentionally absent from the planning baseline. Builders must implement it under the issue, gate, and lane constraints.

