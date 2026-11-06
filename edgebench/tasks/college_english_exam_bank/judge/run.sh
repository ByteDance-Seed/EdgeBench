#!/bin/bash
# Verified judge entry point (task.toml [judge].cmd), run with workdir = /home/workspace after
# the submission is extracted there.
#
# THIS GRADER CALLS AN LLM. scoring/grade_with_codex.py runs the Codex CLI (`codex exec`) as a
# grading agent against an OpenAI-Responses-compatible endpoint. It needs, in the judge container:
#   SFORGE_JUDGE_API_KEY, SFORGE_JUDGE_API_BASE_URL (default https://openrouter.ai/api/v1),
#   SFORGE_JUDGE_MODEL (v1 used gpt-5.5-2026-04-24)
# and network access to that endpoint. The harness passes none of these by default; the operator
# supplies them through SFORGE_JUDGE_EXTRA_ENV. Without them every submission is
# valid=false, score 0 ("Codex invocation failed: No API key ..."). See NOTES.md.
#
# Runs the v1 eval script (same markers and `set -x` as v1's generated eval.sh) and converts its
# output into /opt/sforge/result.json with the v1 `structured_json` semantics (emit_result.py).
set -uo pipefail
mkdir -p /opt/sforge
LOG=$(mktemp)
(
  set -x
  echo ">>>>> Start Test Output"
  # v1 eval_cmd (verbatim):
  cd /home/workspace && python3 scoring/grade_with_codex.py --report . --scoring-dir scoring --task-id college_english_exam_bank --input-dir input --timeout 900 2>&1
  EXIT_CODE=$?
  echo ">>>>> End Test Output"
  echo "Exit code: $EXIT_CODE"
) > "$LOG" 2>&1
cat "$LOG"
python3 /judge/emit_result.py "$LOG" /opt/sforge/result.json
