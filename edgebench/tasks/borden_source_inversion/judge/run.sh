#!/bin/bash
# Verified judge entry point (task.toml [judge].cmd), run with workdir = cwd after the
# submission is extracted into /home/workspace/borden_inverse.
# Runs the v1 eval_cmd unchanged and converts its output into /opt/sforge/result.json
# with the v1 `structured_json` parser semantics (emit_result.py).
set -uo pipefail
mkdir -p /opt/sforge
LOG=$(mktemp)
# v1 eval_cmd (verbatim):
python /opt/borden_scoring/evaluate.py --submission_dir /home/workspace/borden_inverse --case_dir /home/workspace/borden_inverse --scoring_dir /opt/borden_scoring --output /home/workspace/borden_inverse/score.json > "$LOG" 2>&1
EXIT_CODE=$?
cat "$LOG"
echo "Exit code: $EXIT_CODE"
python3 /judge/emit_result.py "$LOG" /opt/sforge/result.json
