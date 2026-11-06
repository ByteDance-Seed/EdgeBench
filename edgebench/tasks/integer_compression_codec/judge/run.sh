#!/bin/bash
# Verified judge entry point (task.toml [judge].cmd), run with workdir = cwd.
# Runs the v1 eval_cmd unchanged and converts its structured output into
# /opt/sforge/result.json with the v1 `structured_json` parser semantics.
mkdir -p /opt/sforge
LOG=$(mktemp /tmp/icc_judge_log.XXXXXX)
# v1 eval_cmd:
cd /home/workspace/integer-compression-codec && python3 runner_judge.py > "$LOG" 2>&1
echo "runner_judge.py exit code: $?"
cat "$LOG"
python3 /judge/emit_result.py "$LOG" /opt/sforge/result.json
