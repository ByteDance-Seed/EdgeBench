#!/bin/bash
# [judge].cmd. Runs v1's eval script (judge/eval.sh = v1 eval_cmd wrapped the way SForge ran it,
# stdout and stderr merged), then grades its output with v1's pytest_v + TOTAL_SCORE semantics
# and writes /opt/sforge/result.json.
OUT=$(mktemp)
cd /home/workspace/swscale-impl
/bin/bash /judge/eval.sh > "$OUT" 2>&1
cat "$OUT"
mkdir -p /opt/sforge
python3 -I /judge/grade.py "$OUT" /opt/sforge/result.json
rm -f "$OUT"
