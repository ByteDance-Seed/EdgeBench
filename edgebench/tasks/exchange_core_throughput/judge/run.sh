#!/bin/bash
# Grader for exchange_core_throughput (Verified judge contract, see SCHEMA.md).
#
# v1 eval_cmd : cd /home/workspace/exchange-core && python3 /tmp/eval_exchange_core.py
# v1 parser   : score_sum (sforge/harness/log_parsers/score_sum.py)
# v1 score    : first `TOTAL_SCORE <n>` in the eval output (sforge/harness/grading.py:extract_score)
# /judge/eval_exchange_core.py is byte-identical to v1's /tmp/eval_exchange_core.py (it runs
# `mvn -B test -Dtest=PerfThroughput#testThroughputPeak` and prints the CASE/TOTAL_SCORE block).
# write_result.py turns its output into /opt/sforge/result.json. stdout = logs only.
set -uo pipefail
LOG=$(mktemp)
cd /home/workspace/exchange-core && python3 /judge/eval_exchange_core.py > "$LOG" 2>&1
EVAL_EXIT=$?
cat "$LOG"
echo "eval_exchange_core.py exit code: $EVAL_EXIT"
python3 -I /judge/write_result.py "$LOG" "$EVAL_EXIT"
