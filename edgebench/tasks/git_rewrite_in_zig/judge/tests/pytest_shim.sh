#!/usr/bin/env bash
# SE-Bench-harness corrected pytest_shim (replaces upstream's version).
#
# Upstream problem: compute_reward.py emits numeric subscores for anything,
# including "baseline-pass" signals (e.g. postgres tap hits ~11% on an empty
# scaffold, cranelift compile_time=1.0 just because the tree still compiles).
# The old shim treated any sub_score > 0 as PASSED, so empty archives got
# pass_rate=0.33 and the agent thought it was "done".
#
# This version's rule for subscores:
#   * By default, a subscore is a DIAGNOSTIC: printed as a comment, does
#     not affect pass_rate. The continuous `score` / TOTAL_SCORE is the
#     real signal.
#   * If reward.json annotates a subscore with `pass_threshold` (float),
#     it becomes a test that PASSes when sub_score >= threshold.
#   * If it sets `counts_for_pass_rate: true` with no threshold, keep
#     the old "sub_score > 0" semantics.
# The overall_score line is always emitted, and is the sole test when
# there are no threshold'd subscores and no hard-fail reasons — so
# pass_rate == (score > 0) by default instead of a spurious fraction.
# Hard-fail reasons still surface as FAILED test rows.
set -euo pipefail

REWARD_JSON="${1:-${VERIFIER_DIR:-/tmp/verifier}/reward.json}"

if [ ! -f "$REWARD_JSON" ]; then
    cat <<EOF
tests/eval.py::reward_json_exists FAILED  [reward.json not found]
=== 0 passed, 1 failed in 0.00s ===
TOTAL_SCORE 0.0
EOF
    exit 0
fi

python3 - "$REWARD_JSON" <<'PYEOF'
import json, sys

data = json.load(open(sys.argv[1]))
score = float(data.get("score") or data.get("reward") or 0.0)
subscores = data.get("subscores") or []
hard_fails = data.get("hard_fail_reasons") or []
reason = data.get("reason") or ""

passed = 0
failed = 0
lines = []
gated_subscores = 0  # subscores that actually count as tests

def emit(name, ok, tag=""):
    global passed, failed
    status = "PASSED" if ok else "FAILED"
    suffix = f"  [{tag}]" if tag else ""
    lines.append(f"{name} {status}{suffix}")
    if ok:
        passed += 1
    else:
        failed += 1

# Hard-fail reasons are always FAILED test rows.
for hf in hard_fails:
    gate_name = str(hf).replace(" ", "_").replace("/", "_")[:60]
    emit(f"tests/gates.py::{gate_name}", False, str(hf))

# Subscores: diagnostic by default, test-gated only when annotated.
for sub in subscores:
    subtask = sub.get("subtask", sub.get("name", "unknown"))
    sub_score = sub.get("score")
    stdout = sub.get("stdout", "")
    name = str(subtask).replace(" ", "_").replace("/", "_")[:80]
    threshold = sub.get("pass_threshold")
    counts = sub.get("counts_for_pass_rate", False)

    if not isinstance(sub_score, (int, float)):
        if threshold is not None or counts:
            emit(f"tests/subscores.py::{name}", False, "no-score")
            gated_subscores += 1
        else:
            lines.append(f"# subscore::{name} = <no-score>  [diagnostic]")
        continue

    tag = stdout or f"score={sub_score}"
    if threshold is not None:
        ok = sub_score >= float(threshold)
        emit(f"tests/subscores.py::{name}", ok, f"{tag}  threshold={threshold}")
        gated_subscores += 1
    elif counts:
        ok = sub_score > 0
        emit(f"tests/subscores.py::{name}", ok, tag)
        gated_subscores += 1
    else:
        lines.append(f"# subscore::{name} = {sub_score}  [diagnostic, {tag}]")

# overall_score is the single gating test unless gated subscores / hard-fails
# already provide structure (in which case it is diagnostic only).
if gated_subscores > 0 or hard_fails:
    lines.append(
        f"# overall_score: {score:.6f}"
        + (f"  reason: {reason}" if reason else "")
    )
else:
    emit("tests/eval.py::overall_score", score > 0, f"score={score:.6f}")

for line in lines:
    print(line)
print(f"=== {passed} passed, {failed} failed in 0.00s ===")
print(f"TOTAL_SCORE {score:.6f}")
if reason and (gated_subscores > 0 or hard_fails):
    print(f"# reason: {reason}")
PYEOF
