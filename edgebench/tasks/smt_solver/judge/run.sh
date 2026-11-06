#!/bin/bash
# Grader for smt_solver (Verified judge contract, see SCHEMA.md). [judge].cmd, workdir = cwd
# (/home/workspace/smt_solver) after the submission (build.sh, solve, src/) is extracted there.
#
# The command chain is v1's judge.eval_cmd, with two changes (NOTES.md, "Deviations"):
#  * v1 first re-extracted /home/workspace/smt_judge/SMT-hidden_benchmarks.zip into
#    /home/workspace/smt_judge/hidden_benchmarks (rm -rf + extractall). The image now holds that
#    extracted tree directly, so in the fresh judge container the step would be a no-op; it is dropped.
#  * v1's fixed scratch files /tmp/smt_{build,eval}.{out,err}, /tmp/smt_hidden_score.json and the
#    heredoc /tmp/sebench_parse_result.py: scratch files now live in a mktemp dir, and the parse
#    script is /judge/parse_result.py (v1 heredoc, score path taken from argv).
# All output is captured in a mktemp log, echoed to stdout (logs only), and turned into
# /opt/sforge/result.json by write_result.py, which applies v1's structured_json parsing to it.
set -uo pipefail
mkdir -p /opt/sforge
LOG=$(mktemp)
T=$(mktemp -d)

(
cd /home/workspace/smt_solver && rm -rf benchmarks hidden_benchmarks scripts expected_answers.json selection_manifest.json hidden_score.json public_score.json; chmod +x build.sh solve; build_status=0; ./build.sh >"$T/smt_build.out" 2>"$T/smt_build.err" || build_status=$?; if [ "$build_status" -eq 0 ]; then python3 /home/workspace/smt_judge/scripts/evaluate.py --solver ./solve --benchmarks /home/workspace/smt_judge/hidden_benchmarks --expected /home/workspace/smt_judge/hidden_benchmarks/expected_answers.json --manifest /home/workspace/smt_judge/hidden_benchmarks/selection_manifest.json --timeout 60 --parallel 16 --perturb --perturb-salt hidden-sebench --submission-root /home/workspace/smt_solver --output "$T/smt_hidden_score.json" >"$T/smt_eval.out" 2>"$T/smt_eval.err"; eval_status=$?; else eval_status=$build_status; fi; if [ -f "$T/smt_build.out" ]; then cat "$T/smt_build.out"; fi; if [ -f "$T/smt_build.err" ]; then cat "$T/smt_build.err"; fi; if [ -f "$T/smt_eval.out" ]; then cat "$T/smt_eval.out"; fi; if [ -f "$T/smt_eval.err" ]; then cat "$T/smt_eval.err"; fi; python3 /judge/parse_result.py "$T/smt_hidden_score.json"
) > "$LOG" 2>&1
EXIT_CODE=$?
cat "$LOG"
echo "Exit code: $EXIT_CODE"

python3 /judge/write_result.py "$LOG" /opt/sforge/result.json
