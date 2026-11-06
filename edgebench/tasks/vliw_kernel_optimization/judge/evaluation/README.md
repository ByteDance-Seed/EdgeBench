# Private Evaluation

This directory contains the official evaluator for the SE-Bench package.

Evaluation procedure:

1. Replace `solution.py` with the agent-submitted version.
2. Run:

```bash
python3 runner.py
```

The runner loads `test_cases/hidden_cases.json`, imports `solution.py`, and calls `verifier.py`. The verifier uses `tests/frozen_problem.py` as the frozen simulator and reference implementation when available.

The runner always prints a parseable `Score: <value>` line. Incorrect submissions or evaluator errors receive `Score: 0.00`.

The original upstream `tests/submission_tests.py` is retained for audit compatibility, but the SE-Bench evaluator entrypoint is `runner.py`.
