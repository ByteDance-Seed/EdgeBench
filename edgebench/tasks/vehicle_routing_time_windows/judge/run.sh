#!/bin/bash
# Grader for vehicle_routing_time_windows (Verified judge contract, see SCHEMA.md).
# [judge].cmd, workdir = cwd (/home/workspace/task_cvrptw_905da6dd/workspace) after the
# submission (src/, include/, Makefile) is extracted there over the starter files.
#
# v1 judge.eval_cmd was `cd <cwd> && { python - <<'PY' ... PY }`. /judge/eval.py is that
# heredoc body, byte for byte, and is fed to `python -` on stdin as before (so sys.path[0]
# is still '' = cwd). It compiles with `make -j4`, runs ./cvrptw_solver on the 56 hidden
# instances under a 20-minute global deadline, checks each output with ./tools/verify and
# prints a structured block. The output is framed with v1's eval.sh markers, captured in a
# mktemp log, echoed to stdout (logs only) and turned into /opt/sforge/result.json by
# write_result.py, which applies v1's extract_test_output + structured_json parsing.
set -uo pipefail
mkdir -p /opt/sforge
LOG=$(mktemp)

{
  echo ">>>>> Start Test Output"
  cd /home/workspace/task_cvrptw_905da6dd/workspace && python - < /judge/eval.py 2>&1
  EXIT_CODE=$?
  echo ">>>>> End Test Output"
  echo "Exit code: $EXIT_CODE"
} > "$LOG" 2>&1
cat "$LOG"

python3 /judge/write_result.py "$LOG" /opt/sforge/result.json
