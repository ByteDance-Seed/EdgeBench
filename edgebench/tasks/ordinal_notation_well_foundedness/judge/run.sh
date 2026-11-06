#!/bin/bash
# Grader for ordinal_notation_well_foundedness (Verified judge contract, see SCHEMA.md). [judge].cmd, run with
# workdir = cwd (/home/workspace/ordinal_notation_wf) after the submission is extracted there over the
# starter files and the hidden eval_task*.v.
#
# v1's judge.eval_cmd was `python3 /opt/sebench/ordinal_notation_wf_eval.py`, run by the harness's eval.sh
# (`set -uxo pipefail`, `<eval_cmd> 2>&1`) from the task cwd. The script is /judge/eval.py, byte-identical
# (it works on the hard-coded ROOT /home/workspace/ordinal_notation_wf, not on its own location). It
# compiles every helper .v, then each taskN.v and eval_taskN.v, and prints CASE lines followed by a
# structured block. Everything is captured in a mktemp log, echoed to stdout (logs only) and turned into
# /opt/sforge/result.json by write_result.py, which applies v1's structured_json parsing.
set -uo pipefail
mkdir -p /opt/sforge
LOG=$(mktemp)

(cd /home/workspace/ordinal_notation_wf && python3 /judge/eval.py) > "$LOG" 2>&1
EXIT_CODE=$?
cat "$LOG"
echo "Exit code: $EXIT_CODE"

python3 /judge/write_result.py "$LOG" /opt/sforge/result.json
