#!/bin/bash
# Grader for jagua_nesting_optimization (Verified judge contract, see SCHEMA.md).
#
# Reproduces v1 exactly:
#   v1 eval_cmd : the command below, verbatim (scorer at /home/workspace/jagua_task_scorer, as in v1)
#   v1 parser   : score_sum  (sforge/harness/log_parsers/score_sum.py)
#   v1 score    : first `TOTAL_SCORE <n>` in the eval output (sforge/harness/grading.py:extract_score)
# This wrapper only runs it; /judge/result.py translates its output into /opt/sforge/result.json.
# stdout = logs only.
set -uo pipefail

mkdir -p /opt/sforge
rm -f /opt/sforge/result.json
LOG="$(mktemp)"

cd /home/workspace/jagua-rs && JAGUA_EVAL_CASES=16 JAGUA_EVAL_SAMPLES=900 JAGUA_CASE_TIMEOUT=20 JAGUA_BUILD_TIMEOUT=300 CANDIDATE_ROOT=/home/workspace/jagua-rs REFERENCE_ROOT=/home/workspace/jagua-rs-ref bash /home/workspace/jagua_task_scorer/score.sh > "$LOG" 2>&1
EVAL_EXIT=$?
cat "$LOG"
echo "score.sh exit code: $EVAL_EXIT"

python3 -I /judge/result.py "$LOG" "$EVAL_EXIT"
rm -f "$LOG"
echo "--- result.json ---"
head -c 600 /opt/sforge/result.json; echo
exit 0
