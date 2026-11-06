#!/bin/bash
# Judge entry point (task.toml judge.cmd), run with workdir = /home/workspace after
# the submission (se-bmk-intern/combinatorial-games/**, minus .lake) is extracted there.
#
# The command chain is v1's eval_cmd verbatim, except for one step:
#   v1:  cp -r /home/workspace/baseline/.lake .
#   now: mkdir -p .lake && ln -sfn /home/workspace/baseline/.lake/packages .lake/packages
# baseline/.lake holds nothing but packages/, so both give the submission the same
# Mathlib packages; the symlink just skips a 7 GB copy per judgement.
# Output is captured and turned into /opt/sforge/result.json by write_result.py,
# which reproduces v1's structured_json parsing (see NOTES.md).
set -uo pipefail
mkdir -p /opt/sforge
LOG=$(mktemp)

(
  cd /home/workspace/se-bmk-intern/combinatorial-games \
  && mkdir -p .lake && ln -sfn /home/workspace/baseline/.lake/packages .lake/packages \
  && cp /home/workspace/baseline/lake-manifest.json . \
  && lake build \
  && cp /home/workspace/judge/se-bmk-intern/combinatorial-games/ListDeclAxiom.lean . \
  && cd /home/workspace/judge/se-bmk-intern \
  && python3 eval_lean.py --baseline-repo /home/workspace/judge/se-bmk-intern/combinatorial-games --current-repo /home/workspace/se-bmk-intern/combinatorial-games
) > "$LOG" 2>&1
EXIT_CODE=$?
# keep the full log in the judge output, as v1 did
tail -c 200000 "$LOG"
echo "Exit code: $EXIT_CODE"

python3 /judge/write_result.py "$LOG" /opt/sforge/result.json
