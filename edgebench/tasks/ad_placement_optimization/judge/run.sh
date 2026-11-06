#!/bin/bash
# Grader for ad_placement_optimization (Verified judge contract, see SCHEMA.md).
#
# Reproduces v1 exactly:
#   v1 eval_cmd : cd /home/workspace/ad-placement && bash /tmp/eval_ahc.sh
#   v1 parser   : score_sum  (sforge/harness/log_parsers/score_sum.py)
#   v1 score    : first `TOTAL_SCORE <n>` in the eval output (sforge/harness/grading.py:extract_score)
# /judge/eval_ahc.sh is byte-identical to the v1 /tmp/eval_ahc.sh. This wrapper only
# runs it and translates its stdout into /opt/sforge/result.json. stdout = logs only.
set -uo pipefail

RESULT_DIR=/opt/sforge
RESULT="$RESULT_DIR/result.json"
LOG=$(mktemp)
mkdir -p "$RESULT_DIR"
rm -f "$RESULT"

cd /home/workspace/ad-placement && bash /judge/eval_ahc.sh > "$LOG" 2>&1
EVAL_EXIT=$?
cat "$LOG"
echo "eval_ahc.sh exit code: $EVAL_EXIT"

awk -v eval_exit="$EVAL_EXIT" '
# JSON string escape. A character loop, not gsub: awk implementations disagree on
# backslashes in gsub replacements (mawk turned "\\\\" into a single backslash).
function jstr(s,    out, i, c) {
    out = ""
    for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (c == "\\") c = "\\\\"; else if (c == "\"") c = "\\\""
        else if (c == "\t") c = "\\t"; else if (c == "\r") c = "\\r"; else if (c < " ") c = " "
        out = out c
    }
    return "\"" out "\""
}
BEGIN { n = 0; passed = 0; score = ""; all = "" }
{ all = all $0 "\n" }
# score_sum: ^CASE\s+(\S+)\s+(OK|TLE|RE|WA|CE)\s+score=(inf|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)
match($0, /^CASE[ \t]+[^ \t]+[ \t]+(OK|TLE|RE|WA|CE)[ \t]+score=(inf|[0-9]+(\.[0-9]+)?([eE][+-]?[0-9]+)?)/) {
    split($0, f, /[ \t]+/); id = f[2]; st = f[3]; sc = substr(f[4], 7)
    sub(/[^0-9a-z.eE+-].*$/, "", sc)
    n++
    if (st == "OK") { name[n] = "case_" id; status[n] = "PASSED"; passed++ }
    else            { name[n] = "case_" id "_" st; status[n] = "FAILED" }
    cscore[n] = (sc == "inf") ? "null" : sc
}
# grading.extract_score: first match of TOTAL_SCORE\s+(inf|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)
score == "" && match($0, /TOTAL_SCORE[ \t]+(inf|[0-9]+(\.[0-9]+)?([eE][+-]?[0-9]+)?)/) {
    t = substr($0, RSTART, RLENGTH); sub(/^TOTAL_SCORE[ \t]+/, "", t); score = t
}
END {
    if (n == 0) {   # score_sum fallback when no CASE line was printed
        n = 1; status[1] = "FAILED"; cscore[1] = "null"
        name[1] = (index(all, "CE") > 0 || index(tolower(all), "compile") > 0) ? "compile" : "unknown"
    }
    summary = passed "/" n " tests passed"
    nf = 0; failed = ""
    for (i = 1; i <= n; i++) if (status[i] != "PASSED") { nf++; if (nf <= 10) failed = failed (nf > 1 ? ", " : "") name[i] }
    if (nf > 0) { summary = summary ". Failed: " failed; if (nf > 10) summary = summary " (+" (nf - 10) " more)" }
    if (score == "" || score == "inf") {
        # v1 reported score=None (unrankable) here; the Verified contract expresses that as valid=false.
        valid = "false"; jscore = "null"
        summary = summary ". No TOTAL_SCORE in eval output"
    } else { valid = "true"; jscore = score }
    printf "{\"score\": %s, \"valid\": %s, \"summary\": %s,\n \"details\": [", jscore, valid, jstr(summary)
    for (i = 1; i <= n; i++) printf "%s\n  {\"name\": %s, \"status\": \"%s\", \"score\": %s}", (i > 1 ? "," : ""), jstr(name[i]), status[i], cscore[i]
    printf "],\n \"metrics\": {\"cases_passed\": %d, \"cases_total\": %d, \"eval_exit_code\": %d}}\n", passed, n, eval_exit
}' "$LOG" > "$RESULT.tmp" && mv "$RESULT.tmp" "$RESULT"

echo "--- result.json ---"
head -c 400 "$RESULT"; echo
exit 0
