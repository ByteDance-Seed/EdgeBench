#!/bin/bash
# Judge entry point (task.toml judge.cmd), run with workdir = /home/workspace after
# the submission (se-bmk-intern/con-nf/**, minus .lake) is extracted there.
#
# The command chain is v1's eval_cmd verbatim. The judge's con-nf/.lake holds the
# prebuilt baseline build/ and a `packages` symlink to the base's packages; `cp -r`
# copies the symlink as a symlink (no 5 GB copy, same packages as v1).
# Output is captured and turned into /opt/sforge/result.json by write_result.py,
# which reproduces v1's structured_json parsing (see NOTES.md).
set -uo pipefail
mkdir -p /opt/sforge
LOG=$(mktemp)

(
  cd /home/workspace/se-bmk-intern/con-nf \
  && cp -r /home/workspace/judge/se-bmk-intern/con-nf/.lake . \
  && cp /home/workspace/judge/se-bmk-intern/con-nf/lake-manifest.json . \
  && lake build \
  && cp /home/workspace/judge/se-bmk-intern/con-nf/ListDeclAxiom.lean . \
  && cd /home/workspace/judge/se-bmk-intern \
  && python3 eval_lean.py --baseline-repo /home/workspace/judge/se-bmk-intern/con-nf --current-repo /home/workspace/se-bmk-intern/con-nf
) > "$LOG" 2>&1
EXIT_CODE=$?
# keep the full log in the judge output, as v1 did
tail -c 200000 "$LOG"
echo "Exit code: $EXIT_CODE"

python3 /judge/write_result.py "$LOG" /opt/sforge/result.json
