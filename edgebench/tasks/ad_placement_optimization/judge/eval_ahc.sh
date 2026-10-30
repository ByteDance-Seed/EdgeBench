#!/bin/bash
# AHC evaluator: compile once, run fixed cases with bounded parallelism,
# and report score_sum-compatible CASE/TOTAL_SCORE lines.
set -uo pipefail

WORK_DIR="/home/workspace/ad-placement"
CASES_DIR="$WORK_DIR/cases"
TESTER="$WORK_DIR/tools/bin/tester"
SOLUTION_BIN="$WORK_DIR/solution"
TIME_LIMIT=5
MAX_JOBS="${SEBENCH_AD_EVAL_JOBS:-}"
if [ -z "$MAX_JOBS" ]; then
    MAX_JOBS=$(nproc 2>/dev/null || echo 1)
    if [ "$MAX_JOBS" -gt 2 ]; then
        MAX_JOBS=2
    fi
fi
RESULTS_DIR="/tmp/ad_placement_results_$$"
mkdir -p "$RESULTS_DIR"

if ! [[ "$MAX_JOBS" =~ ^[0-9]+$ ]] || [ "$MAX_JOBS" -lt 1 ]; then
    MAX_JOBS=1
fi

# --- Compile ---
COMPILED=0
mapfile -t SOURCES < <(find "$WORK_DIR" -name '*.cpp' ! -path '*/tools/*' | sort)

if [ ${#SOURCES[@]} -eq 0 ]; then
    echo "CASE 0000 CE score=0"
    echo "TOTAL_SCORE 0"
    echo "CASES_OK 0"
    echo "CASES_TOTAL 1"
    rm -rf "$RESULTS_DIR"
    exit 0
fi

if [ -f "$WORK_DIR/Makefile" ]; then
    if make -C "$WORK_DIR" >/dev/null 2>&1 && [ -x "$SOLUTION_BIN" ]; then
        COMPILED=1
    fi
fi

if [ "$COMPILED" -eq 0 ]; then
    SRC="${SOURCES[0]}"
    if ! g++ -std=c++17 -O2 -o "$SOLUTION_BIN" "$SRC" 2>/dev/null; then
        echo "CASE 0000 CE score=0"
        echo "TOTAL_SCORE 0"
        echo "CASES_OK 0"
        echo "CASES_TOTAL 1"
        rm -rf "$RESULTS_DIR"
        exit 0
    fi
fi

mapfile -t CASE_FILES < <(find "$CASES_DIR" -name '*.txt' | sort)

if [ ${#CASE_FILES[@]} -eq 0 ]; then
    echo "CASE 0000 CE score=0"
    echo "TOTAL_SCORE 0"
    echo "CASES_OK 0"
    echo "CASES_TOTAL 0"
    rm -rf "$RESULTS_DIR"
    exit 0
fi

run_case() {
    local CASE_FILE="$1"
    local CASE_ID OUT_FILE RUN_EXIT TESTER_STDERR TESTER_EXIT SCORE
    CASE_ID=$(basename "$CASE_FILE" .txt)
    OUT_FILE="$RESULTS_DIR/out_${CASE_ID}.txt"

    timeout "$TIME_LIMIT" "$SOLUTION_BIN" < "$CASE_FILE" > "$OUT_FILE" 2>/dev/null
    RUN_EXIT=$?
    if [ "$RUN_EXIT" -ne 0 ]; then
        if [ "$RUN_EXIT" -eq 124 ]; then
            echo "CASE $CASE_ID TLE score=0" > "$RESULTS_DIR/${CASE_ID}.result"
        else
            echo "CASE $CASE_ID RE score=0" > "$RESULTS_DIR/${CASE_ID}.result"
        fi
        return 0
    fi

    TESTER_STDERR=$(timeout 10 "$TESTER" "$CASE_FILE" "$OUT_FILE" 2>&1 1>/dev/null)
    TESTER_EXIT=$?
    SCORE=$(echo "$TESTER_STDERR" | grep -oP 'Score\s*=\s*\K\d+' | head -1)

    if [ "$TESTER_EXIT" -eq 0 ] && [ -n "$SCORE" ]; then
        echo "CASE $CASE_ID OK score=$SCORE" > "$RESULTS_DIR/${CASE_ID}.result"
    else
        echo "CASE $CASE_ID WA score=${SCORE:-0}" > "$RESULTS_DIR/${CASE_ID}.result"
    fi
}

JOB_COUNT=0
for CASE_FILE in "${CASE_FILES[@]}"; do
    run_case "$CASE_FILE" &
    JOB_COUNT=$((JOB_COUNT + 1))
    if [ "$JOB_COUNT" -ge "$MAX_JOBS" ]; then
        wait || true
        JOB_COUNT=0
    fi
done
wait || true

TOTAL_SCORE=0
CASES_OK=0
CASES_TOTAL=${#CASE_FILES[@]}

for RESULT_FILE in "$RESULTS_DIR"/*.result; do
    [ -e "$RESULT_FILE" ] || continue
    LINE=$(cat "$RESULT_FILE")
    echo "$LINE"
    STATUS=$(echo "$LINE" | awk '{print $3}')
    SCORE=$(echo "$LINE" | grep -oP 'score=\K\d+' | head -1)
    if [ "$STATUS" = "OK" ]; then
        TOTAL_SCORE=$((TOTAL_SCORE + SCORE))
        CASES_OK=$((CASES_OK + 1))
    fi
done

echo "TOTAL_SCORE $TOTAL_SCORE"
echo "CASES_OK $CASES_OK"
echo "CASES_TOTAL $CASES_TOTAL"
rm -rf "$RESULTS_DIR"
