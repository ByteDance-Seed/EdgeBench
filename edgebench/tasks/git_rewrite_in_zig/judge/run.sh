#!/bin/bash
# Grader for git_rewrite_in_zig (task.toml [judge].cmd; workdir = /home/workspace/zig-port
# after the filtered submission has been extracted there).
#
# The subshell runs v1's judge.eval_cmd verbatim, under the `set -u -o pipefail` that v1's
# generated eval.sh had (xtrace dropped: logs only), with stderr merged into stdout like v1's
# `eval_cmd 2>&1`. result.py echoes that output (logs) and grades it like v1's parser
# `pytest_v` + extract_score, writing /opt/sforge/result.json.
#
# No temp file is used for the output on purpose: test.sh (Step 4) deletes everything in
# /tmp except /tmp/git-build before running the test suite.
(
set -u -o pipefail
mkdir -p /logs/verifier /tmp/verifier && ln -sfn /home/workspace /app && ln -sfn /opt/tests /tests && ln -sfn /tmp/verifier /logs/verifier 2>/dev/null; export APP_DIR=/home/workspace VERIFIER_DIR=/logs/verifier && bash /opt/tests/test.sh >/tmp/verifier.log 2>&1 || true; cat /tmp/verifier.log >&2; bash /opt/tests/pytest_shim.sh "/logs/verifier/reward.json"
) 2>&1 | python3 -I /judge/result.py
exit 0
