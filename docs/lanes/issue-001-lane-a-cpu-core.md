# Lane A: CPU Core

Builder: bailian-opencode-builder
Model: bailian/qwen-plus
Branch: builder/bailian-cpu-core
Depends on: committed contract
Overlap level: none
Merge owner: Codex Supervisor

## Allowed Files

- src/lbm_cpu.cpp

## Goal

Implement D2Q9 constants, equilibrium, cylinder mask, CPU BGK collision/streaming, boundary conditions, CSV output, and summary printing declared by src/lbm.hpp.

## Forbidden Files

- All other files.
- docs/gates/**

