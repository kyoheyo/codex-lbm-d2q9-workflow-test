# Lane C: Tests And Runner

Builder: bailian-opencode-builder
Model: bailian/qwen-plus
Branch: builder/bailian-tests-runner
Depends on: integrated Lane A and Lane B
Overlap level: none
Merge owner: Codex Supervisor

## Allowed Files

- tests/lbm_tests.cpp
- src/main.cpp
- scripts/validate.ps1

## Goal

Implement contract-based unit tests, the validation executable entry point, and a cross-platform PowerShell validation script that uses CUDA locally when available and CPU fallback on GitHub Actions.

## Forbidden Files

- All other files.
- docs/gates/**

