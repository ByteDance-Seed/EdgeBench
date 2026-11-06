# Ordinal Notation Well-Foundedness

Complete as many Coq proof targets as possible.

## Files

- `ChildOf.v` contains the immutable problem definition. It is visible for reference, but changes to this file are not submitted.
- `task1.v` through `task9.v` contain the proof targets.

You may edit the `taskN.v` files and add extra `.v` helper libraries in this directory. Shared helper libraries are submitted and can be reused across targets.

The environment includes Coq 8.20, `python3`, `gcc`, and `g++`. You may write local helper programs for experiments, but only submitted Coq files affect scoring.

## Scoring

The final score is the sum of weights for proof targets that pass the hidden checker. Higher is better.

| Target | Weight |
|---|---:|
| `task1` | 1 |
| `task2` | 2 |
| `task3` | 2 |
| `task4` | 4 |
| `task5` | 4 |
| `task6` | 8 |
| `task7` | 16 |
| `task8` | 16 |
| `task9` | 32 |

Maximum score: 85.

## Evaluation

For each target, the judge compiles the immutable definition, your submitted helper libraries, the corresponding `taskN.v`, and a hidden `eval_taskN.v`.

A target receives credit only if the hidden checker's `Print Assumptions` output is closed under the global context. Proofs that rely on `Admitted`, new axioms, parameters, or other open assumptions may compile locally but will not receive credit.

Basic local checks:

```bash
coqc ChildOf.v
coqc task1.v
```

For a stronger local sanity check, create a temporary file that imports your task and runs `Print Assumptions` on the exported lemma, then remove the temporary file before submission.

Run `sebench-submit` for weighted feedback from the judge, and `sebench-submit --details` for per-target diagnostics.
