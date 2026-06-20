# Lane B: CUDA Backend

Builder: claude-builder
Model: opus
Branch: builder/claude-cuda-backend
Depends on: committed contract
Overlap level: none
Merge owner: Codex Supervisor

## Allowed Files

- src/lbm_cuda.cu

## Goal

Implement runCuda declared by src/lbm.hpp, including device kernels, memory management, cylinder bounce-back, inlet/outlet and top/bottom boundaries, result copy-back, and a clean false return when CUDA is unavailable.

## Forbidden Files

- All other files.
- docs/gates/**

