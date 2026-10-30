#!/bin/bash
# Grader for tree_block_partitioning (Verified judge contract: writes /opt/sforge/result.json).
#
# Runs the v1 eval_cmd verbatim (stderr merged into stdout, as the v1 eval.sh did):
#   cd /home/workspace/p1 && python3 /opt/p1_judge/prob/P1/eval.py --source-root /home/workspace/p1 \
#     --time-factor 1 --time-grace 0 --score-sum
# and translates its output into /opt/sforge/result.json with /judge/grade.py, which
# reproduces v1's parser `score_sum` + `_grade_legacy` + `extract_score`. stdout = logs only.
set -uo pipefail

RESULT_DIR=/opt/sforge
LOG=$(mktemp)
mkdir -p "$RESULT_DIR"
rm -f "$RESULT_DIR/result.json"

cd /home/workspace/p1 && python3 /opt/p1_judge/prob/P1/eval.py --source-root /home/workspace/p1 --time-factor 1 --time-grace 0 --score-sum > "$LOG" 2>&1
EVAL_EXIT=$?
# The CASE lines (7200 of them) are only in the log file; show the rest.
grep -v '^CASE ' "$LOG"
echo "eval.py exit code: $EVAL_EXIT"

python3 /judge/grade.py "$LOG" "$EVAL_EXIT" "$RESULT_DIR/result.json"
echo "--- result.json ---"
head -c 400 "$RESULT_DIR/result.json"; echo
exit 0
