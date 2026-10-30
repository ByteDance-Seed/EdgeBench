#!/bin/bash
# Judge entry point (task.toml judge.cmd), run with workdir = /home/workspace after
# the submission (se-bmk-intern/carleson/**, minus .lake) is extracted there.
#
# The command chain is v1's eval_cmd (published task JSON) verbatim. Its first step,
# `cp -r <judge>/carleson/.lake .`, now copies the judge's build products plus the
# package symlinks into the base's Mathlib (cp -r keeps symlinks), not 6.6 GB of packages.
# Output is captured and turned into /opt/sforge/result.json by write_result.py,
# which reproduces v1's structured_json parsing (see NOTES.md).
set -uo pipefail
mkdir -p /opt/sforge
LOG=$(mktemp)

(
  cd /home/workspace/se-bmk-intern/carleson \
  && cp -r /home/workspace/judge/se-bmk-intern/carleson/.lake . \
  && cp /home/workspace/judge/se-bmk-intern/carleson/lake-manifest.json . \
  && lake build \
  && cp /home/workspace/judge/se-bmk-intern/carleson/ListDeclAxiom.lean . \
  && cd /home/workspace/judge/se-bmk-intern \
  && python3 eval_lean.py --baseline-repo /home/workspace/judge/se-bmk-intern/carleson --current-repo /home/workspace/se-bmk-intern/carleson
) > "$LOG" 2>&1
EXIT_CODE=$?
# keep the full log in the judge output, as v1 did
tail -c 200000 "$LOG"
echo "Exit code: $EXIT_CODE"

python3 /judge/write_result.py "$LOG" /opt/sforge/result.json
