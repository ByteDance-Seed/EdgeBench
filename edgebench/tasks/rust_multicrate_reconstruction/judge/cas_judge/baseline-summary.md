# Baseline Summary

This file records the starter baseline for the evaluator package.

## Structural Verification

Command:

```bash
PYTHONPYCACHEPREFIX=/private/tmp/caspycache-eval-fixed bash verify_task.sh
```

Result:

```text
VERIFY_RESULT=OK PASS=17 FAIL=0
```

`PYTHONPYCACHEPREFIX` is used only to keep Python bytecode caches inside a
writable temporary directory on macOS sandboxed runners.

## Starter Score

Command:

```bash
python3 tools/score.py --workspace agent-start --manifest hidden-tests/split-manifest.json --hidden-source-dir hidden-tests/hidden-sources --output skeleton-score.json --timeout-per-crate 600 --timeout-total 3600
```

Result summary:

```text
score_status=OK
total_score=3.8189
public_score=3.3913
raw_passed=66
raw_total=2611
total_duration_sec=400.32
infra_errors=[]
hidden_snippets_injected=833
```

The full machine-readable result is stored in `skeleton-score.json`.

