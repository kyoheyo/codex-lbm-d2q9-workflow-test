# Lane A2: CPU Stability Repair

Builder: claude-builder
Model: opus
Branch: builder/claude-cpu-stability-fix
Depends on: failed integration gate after Lane A and B
Overlap level: semantic-overlap, sequential repair
Shared file: src/lbm_cpu.cpp
Merge owner: Codex Supervisor

## Allowed Files

- src/lbm_cpu.cpp

## Goal

Replace the unstable CPU time-stepping and boundary implementation with a finite, stable D2Q9 BGK cylinder-wake validation path for 180 iterations. Preserve the committed public contract.

