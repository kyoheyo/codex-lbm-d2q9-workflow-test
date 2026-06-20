# Requirements

## Goal

Implement a compact D2Q9 lattice Boltzmann solver for two-dimensional flow past a circular cylinder.

## Numerical Requirements

- D2Q9 velocities and weights.
- BGK collision operator.
- Streaming.
- Circular-cylinder bounce-back.
- Left velocity inlet.
- Right open/outflow-like boundary.
- Explicit top and bottom boundary behavior.
- CUDA implementation for the primary local GPU path.
- CPU fallback for GitHub Actions and systems without a CUDA device.

## Output Requirements

- Run at least 120 iterations in validation mode.
- Print backend, grid, iteration count, density range, mass, and a sample velocity.
- Print LBM_VALIDATION_OK on success.
- Generate non-empty out/cylinder_wake.csv.

## Test Requirements

- Verify equilibrium mass and momentum moments.
- Verify cylinder-mask center, exterior point, and approximate area.
- Compile and execute the simulation.

