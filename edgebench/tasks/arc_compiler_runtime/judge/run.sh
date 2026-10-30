#!/bin/bash
# Grader for arc_compiler_runtime (Verified judge contract, see SCHEMA.md). [judge].cmd, workdir = cwd
# (/home/workspace/arc-compiler-runtime-implementation/agent-start) after the submission (compiler/src/)
# is extracted there over the starter files.
#
# The command is v1's judge.eval_cmd: `cd /home/workspace/arc-compiler-runtime-implementation &&
# python -c 'exec("...")'`. The exec'd program is /judge/eval_hidden.py (decoded verbatim). It runs
# `bash evaluator-hidden/score_hidden.sh agent-start` (1400 s timeout) and prints the scorer output
# followed by a structured block. Everything is captured in a mktemp log, echoed to stdout (logs only)
# and turned into /opt/sforge/result.json by write_result.py, which applies v1's structured_json parsing.
set -uo pipefail
mkdir -p /opt/sforge
LOG=$(mktemp)

(cd /home/workspace/arc-compiler-runtime-implementation && python /judge/eval_hidden.py) > "$LOG" 2>&1
EXIT_CODE=$?
cat "$LOG"
echo "Exit code: $EXIT_CODE"

python3 /judge/write_result.py "$LOG" /opt/sforge/result.json
