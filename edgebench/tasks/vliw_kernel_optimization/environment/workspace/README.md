# SE-Bench: Performance Kernel Optimization

This workspace is the public, agent-facing portion of the SE-Bench task. The
complete task statement is in `problem.md`.

## Quick Start

Edit `solution.py`, then run:

```bash
python3 runner.py
```

The runner loads `test_cases/public_cases.json`, calls `solution.py`, and uses
`verifier.py` to check correctness, report simulated cycle counts, and print
`Score: <value>`.

The public cases are only a smoke test. Official evaluation uses private test
cases and the frozen simulator under the evaluator's private files.

## Score

Correctness is mandatory. If any case is incorrect, the submission is invalid
and is not eligible for best-score comparison. Otherwise, `cycles` is the
maximum cycle count across performance cases, and score is computed directly
from that cycle count:

```text
Score = cycles
```

Lower scores are better. The verifier still reports the benchmark thresholds as
interpretability markers.

## Constraints

- Edit `solution.py`; do not change `problem.py`, `runner.py`, `verifier.py`, or
  files under `test_cases/`.
- Do not use network access.
- Do not hard-code public or hidden random seeds.
