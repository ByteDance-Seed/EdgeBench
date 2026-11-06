#!/bin/bash
# Verified judge entry point (task.toml [judge].cmd), run with workdir = /app after the
# submission is extracted into /app.
#
# v1 eval_cmd:
#   set +x; cd /app && bash /tests/test.sh > /tmp/test_full.log 2>&1;
#   python3 - > /tmp/structured_result.log 2>&1 <<'PY' ... PY
#   cat /tmp/structured_result.log
# Same steps; the two logs are mktemp files instead of fixed /tmp paths, and the heredoc
# program is /judge/structured_result.py. write_result.py applies the v1 structured_json
# parser to what v1 parsed (the cat output) and writes /opt/sforge/result.json.
set -uo pipefail
TEST_LOG=$(mktemp)     # v1: /tmp/test_full.log
RESULT_LOG=$(mktemp)   # v1: /tmp/structured_result.log
cd /app && bash /tests/test.sh > "$TEST_LOG" 2>&1
python3 /judge/structured_result.py "$TEST_LOG" > "$RESULT_LOG" 2>&1
# Logs only (v1 did not print test.sh's output; the harness does not parse stdout).
echo "===== test.sh output ====="
cat "$TEST_LOG"
echo "===== v1 parsed output ====="
cat "$RESULT_LOG"
python3 /judge/write_result.py "$RESULT_LOG" /opt/sforge/result.json
