#!/bin/bash
# Grader for vliw_kernel_optimization (Verified judge contract, see SCHEMA.md). [judge].cmd, run with
# workdir = cwd (/home/workspace/sebench_performance_takehome) after the submission (solution.py only) is
# extracted there over the evaluator's files.
#
# v1's judge.eval_cmd was `cd /home/workspace/sebench_performance_takehome && python -c "exec(\"<program>\")"`,
# run by the harness's eval.sh. The program is /judge/eval_hidden.py, verbatim. It runs
# `python runner.py --solution solution.py --cases test_cases/hidden_cases.json --output /tmp/sebench_performance_report.json`
# (600 s timeout), prints the runner output followed by a structured block. Everything is captured in a
# mktemp log, echoed to stdout (logs only) and turned into /opt/sforge/result.json by write_result.py, which
# applies v1's structured_json parsing.
set -uo pipefail
mkdir -p /opt/sforge
LOG=$(mktemp)

(cd /home/workspace/sebench_performance_takehome && python /judge/eval_hidden.py) > "$LOG" 2>&1
EXIT_CODE=$?
cat "$LOG"
echo "Exit code: $EXIT_CODE"

python3 /judge/write_result.py "$LOG" /opt/sforge/result.json
