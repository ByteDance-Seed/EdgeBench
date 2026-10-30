#!/bin/bash
# Verified judge entry point (task.toml [judge].cmd), run with workdir = cwd after the
# submission (solution/solution.py) is extracted into /home/workspace/045_graph_node_classification.
# Runs the v1 eval_cmd unchanged and converts its output into /opt/sforge/result.json
# with the v1 `structured_json` parser semantics (emit_result.py).
set -uo pipefail
mkdir -p /opt/sforge
LOG=$(mktemp)
# v1 eval_cmd (verbatim). In v1 its stdout/stderr were a pipe (docker exec stream), not a file;
# keep a pipe so that anything writing to judge_eval.py's fd 1 (e.g. via /proc/<pid>/fd/1)
# appends to the log exactly as in v1 instead of overwriting it at offset 0 (see NOTES.md).
cd /home/workspace/045_graph_node_classification && CUDA_VISIBLE_DEVICES= NVIDIA_VISIBLE_DEVICES=none python judge_eval.py 2>&1 | cat > "$LOG"
EXIT_CODE=${PIPESTATUS[0]}
cat "$LOG"
echo "Exit code: $EXIT_CODE"
python3 /judge/emit_result.py "$LOG" /opt/sforge/result.json
