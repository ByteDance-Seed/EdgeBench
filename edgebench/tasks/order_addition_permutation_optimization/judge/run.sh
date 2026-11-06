#!/bin/bash
# Judge entry point ([judge].cmd). Runs v1's eval_cmd unchanged and turns its output into
# /opt/sforge/result.json with v1's pytest_v + extract_score semantics (see result.py, NOTES.md).
set -u
LOG=$(mktemp)
cd /home/workspace/complex_job_scheduling
# v1 eval_cmd: cd /home/workspace/complex_job_scheduling && python -m pytest tests/test_final_result.py -s -v
python -m pytest tests/test_final_result.py -s -v > "$LOG" 2>&1
EXIT_CODE=$?
cat "$LOG"
echo "Exit code: $EXIT_CODE"
# -I: do not import anything from the submission-controlled cwd.
python3 -I /judge/result.py "$LOG" "$EXIT_CODE"
