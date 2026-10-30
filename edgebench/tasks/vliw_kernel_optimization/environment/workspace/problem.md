# Problem

Optimize the generated kernel for a custom VLIW/SIMD machine.

## Task

Edit `solution.py`, specifically `KernelBuilder.build_kernel`, so that it generates a faster instruction program for the machine defined in `problem.py`.

The generated program must produce the same final output values as `reference_kernel2`.

The main workload is:

- `forest_height = 10`
- `rounds = 16`
- `batch_size = 256`

## Machine Model

The simulator in `problem.py` models a custom architecture with these per-cycle slot limits:

- `alu`: 12 slots
- `valu`: 6 slots
- `load`: 2 slots
- `store`: 2 slots
- `flow`: 1 slot

SIMD vector length is `VLEN = 8`. The machine has one core. Instruction effects are written at the end of a cycle, so slots in the same instruction bundle read the old scratch values.

## Required Interface

`solution.py` must define:

```python
class KernelBuilder:
    def build_kernel(self, forest_height: int, n_nodes: int, batch_size: int, rounds: int):
        ...
```

The runner will instantiate `KernelBuilder`, call `build_kernel`, then execute `kb.instrs` on the simulator. You may add helper methods, constants, and scratch allocation logic inside `solution.py`.

## Scoring

The official score is based on simulated cycle count on hidden/generated test cases. Lower is better. Correctness is required before cycle count is considered.

The original baseline produces `147734` cycles on the main workload. Thresholds reported by the verifier include:

- `<147734`
- `<18532`
- `<2164`
- `<1790`
- `<1579`
- `<1548`
- `<1487`
- `<1363`

For scoring, `cycles` means the maximum cycle count across all correct performance cases in the case file:

```text
Score = invalid                                if any case is incorrect
Score = cycles                                 otherwise
```

Lower scores are better. Incorrect submissions are invalid and are not eligible
for best-score comparison. The runner prints the final line as
`Score: <value>` for correct submissions, or `Score: invalid` if correctness
fails.

## Local Run

Use the public runner:

```bash
python3 runner.py
```

This reads `test_cases/public_cases.json`, imports `solution.py`, and calls `verifier.py`. Public cases are only for smoke testing and do not define the official score. The private evaluator uses different hidden seeds.

## Constraints

- Do not use network access.
- Do not change `problem.py` semantics.
- Do not modify hidden/private evaluation files.
- Do not hard-code answers for specific random seeds or generated instances.
