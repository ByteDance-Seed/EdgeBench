# Task: implement Arc compiler/runtime modules

Implement the missing JavaScript modules under `compiler/src/` so the Arc language compiler/runtime works. Use `CHEATSHEET.md` as the public language reference.

## Boundaries

- Edit implementation files under `compiler/src/` only during a solver attempt.
- Do not modify tests, scoring scripts, manifests, task metadata, Dockerfile, or package files.
- Work offline. Do not use network search, cloning, GPU, mouse, video, or human interaction.
- Do not add hidden solutions, private provenance, source maps, compiled answer artifacts, answer material.
- Do not attempt to access evaluator-only hidden tests during solving.

## Public smoke scoring

The public package contains smoke/sample tests only. They are intended for local progress checks and interface validation, not as the full official evaluation.

| Item | Value |
| --- | ---: |
| Public raw denominator | 48 |
| Public weighted denominator | 48 |
| Starter expectation | `SCORE=0.00`, `SCORE_STATUS=OK` |

Run `bash score.sh` from the package root for public smoke feedback.

## Final evaluation

The final official score is computed by a separate evaluator-only hidden package using SPEC_CONFIRMED tests derived from this public language contract.
