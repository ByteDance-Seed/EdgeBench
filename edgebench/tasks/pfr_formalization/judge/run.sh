#!/bin/bash
# Judge entry point (task.toml judge.cmd), run with workdir = /home/workspace after
# the submission (se-bmk-intern/pfr/**, minus .lake) is extracted there.
#
# The command chain is v1's eval_cmd verbatim. `cp -r` keeps the judge copy's
# .lake/packages symlinks (Mathlib and its dependencies, pointing into the base)
# as symlinks and copies the real AddCombi/checkdecls checkouts and the prebuilt
# baseline build, so the submission builds against the same packages as in v1.
# Output is captured and turned into /opt/sforge/result.json by write_result.py,
# which reproduces v1's structured_json parsing (see NOTES.md).
set -uo pipefail
mkdir -p /opt/sforge
LOG=$(mktemp)

(
  cd /home/workspace/se-bmk-intern/pfr \
  && cp -r /home/workspace/judge/se-bmk-intern/pfr/.lake . \
  && cp /home/workspace/judge/se-bmk-intern/pfr/lake-manifest.json . \
  && lake build \
  && cp /home/workspace/judge/se-bmk-intern/pfr/ListDeclAxiom.lean . \
  && cd /home/workspace/judge/se-bmk-intern \
  && python3 eval_lean.py --baseline-repo /home/workspace/judge/se-bmk-intern/pfr --current-repo /home/workspace/se-bmk-intern/pfr
) > "$LOG" 2>&1
EXIT_CODE=$?
# keep the end of the log in the judge output (last 200000 bytes, cut on a UTF-8
# character boundary so the stream stays valid text; Lean messages contain Unicode)
python3 -c 'import sys; sys.stdout.write(open(sys.argv[1], "rb").read()[-200000:].decode("utf-8", "ignore"))' "$LOG"
echo "Exit code: $EXIT_CODE"

python3 /judge/write_result.py "$LOG" /opt/sforge/result.json
