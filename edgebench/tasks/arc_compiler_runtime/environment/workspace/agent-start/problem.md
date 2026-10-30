# Arc language compiler benchmark

Implement the missing Arc compiler and runtime modules under `agent-start/compiler/src/`.
The solver-visible language contract is `agent-start/CHEATSHEET.md`, this problem statement, `agent-start/TASK.md`, and the public smoke tests.

## Constraints

- Work offline. Do not use network search, cloning, GPU, mouse interaction, video, or human-in-the-loop input.
- During a solver attempt, edit only implementation files under `agent-start/compiler/src/`.
- Do not modify tests, scoring scripts, task metadata, Dockerfile, package files, or manifests.
- Do not add hidden solutions, answer artifacts, private provenance, answer material, or generated build outputs to the workspace.

## Public vs hidden evaluation

The public starter contains only smoke/sample tests:

```text
Public raw total: 48
Public weighted total: 48
Expected stripped starter score: 0.00
```

The final official score is computed by an evaluator-only hidden package that is not visible to agents. Hidden tests are deterministic, closed, SPEC_CONFIRMED, and based on the public language contract. They cover parser boundaries, type-system edge cases, interpreter/codegen consistency, stdlib composition, toolchain/CLI edge behavior, and cross-module integration.

Run public validation:

```bash
bash score.sh
bash verify_task.sh
docker build -t arc-lang-public-starter .
docker run --rm --network=none arc-lang-public-starter
```
