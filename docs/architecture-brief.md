# Architecture Brief

## Problem

Create a small but real CUDA/C++ numerical project while validating remote GitHub issue, PR, and Actions behavior.

## Contract-First Design

The planner owns src/lbm.hpp. Builders implement against this committed contract instead of inventing incompatible APIs.

## Lane Graph

~~~text
lane-0-contract (Codex planner, committed baseline)
  +-> lane-a-cpu-core (bailian-opencode-builder)
  +-> lane-b-cuda-backend (claude-builder)
       |
       +-> integration/core
             |
             +-> lane-c-tests-runner (bailian-opencode-builder)
                   |
                   +-> lane-d-user-docs (claude-builder)
                         |
                         +-> remote feature branch -> PR -> Actions -> Codex review
~~~

## Overlap Policy

- Lane A and B: no overlap.
- Lane C depends on integrated A and B; no speculative API assumptions.
- Lane D runs after code integration and may edit README/docs only.
- Codex is merge owner for all branches.

## Builder Selection

- Active Codex: planner, supervisor, reviewer, integration owner.
- Bailian OpenCode: CPU core and later tests/runner.
- Claude DeepSeek: CUDA backend and later user documentation.
- External Codex CLI is not selected because the user did not request it and viable non-Codex builders are available.

