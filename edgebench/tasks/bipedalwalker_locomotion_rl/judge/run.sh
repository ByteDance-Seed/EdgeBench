#!/bin/bash
# Verified judge entry point (task.toml [judge].cmd), run with workdir = cwd after the
# submission is extracted into /home/workspace/loco-rl.
# Runs the v1 eval_cmd unchanged and converts its output into /opt/sforge/result.json
# with the v1 `structured_json` parser semantics (emit_result.py).
set -uo pipefail
mkdir -p /opt/sforge
LOG=$(mktemp)
# v1 eval_cmd (verbatim):
cd /home/workspace/loco-rl && SEBENCH_LOCO_EVAL_EPISODES=${SEBENCH_LOCO_EVAL_EPISODES:-10} python sebench_eval.py > "$LOG" 2>&1
EXIT_CODE=$?
cat "$LOG"
echo "Exit code: $EXIT_CODE"
python3 /judge/emit_result.py "$LOG" /opt/sforge/result.json
