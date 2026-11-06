#!/bin/bash
set -uo pipefail

WORK_DIR="/home/workspace/wirel"
CASES_DIR="$WORK_DIR/cases"
TESTER="$WORK_DIR/tools/bin/tester"
SOLUTION_BIN="$WORK_DIR/solution"
TIME_LIMIT=5
TESTER_TIMEOUT=10
BAD_SCORE=100000000000000000
RESULTS_DIR="/tmp/wirel_results_$$"
mkdir -p "$RESULTS_DIR"

cd "$WORK_DIR"

mapfile -t CASE_FILES < <(find "$CASES_DIR" -type f | sort)
CASES_TOTAL=${#CASE_FILES[@]}

if [ "$CASES_TOTAL" -eq 0 ]; then
    echo "TOTAL_SCORE $BAD_SCORE"
    echo "CASES_OK 0"
    echo "CASES_TOTAL 0"
    rm -rf "$RESULTS_DIR"
    exit 0
fi

if [ ! -f "$WORK_DIR/solution.cpp" ]; then
    echo "CASE 0000 CE score=$BAD_SCORE"
    echo "TOTAL_SCORE $BAD_SCORE"
    echo "CASES_OK 0"
    echo "CASES_TOTAL $CASES_TOTAL"
    rm -rf "$RESULTS_DIR"
    exit 0
fi

if ! g++ -std=c++17 -O2 -o "$SOLUTION_BIN" "$WORK_DIR/solution.cpp" 2>"$RESULTS_DIR/compile.err"; then
    echo "CASE 0000 CE score=$BAD_SCORE"
    echo "TOTAL_SCORE $BAD_SCORE"
    echo "CASES_OK 0"
    echo "CASES_TOTAL $CASES_TOTAL"
    rm -rf "$RESULTS_DIR"
    exit 0
fi

run_case() {
    local CASE_FILE="$1"
    local CASE_ID OUT_FILE RUN_EXIT TESTER_OUTPUT TESTER_EXIT SCORE
    CASE_ID=$(basename "$CASE_FILE" .txt)
    OUT_FILE="$RESULTS_DIR/out_${CASE_ID}.txt"

    timeout "$TIME_LIMIT" "$SOLUTION_BIN" < "$CASE_FILE" > "$OUT_FILE" 2>/dev/null
    RUN_EXIT=$?
    if [ "$RUN_EXIT" -ne 0 ]; then
        if [ "$RUN_EXIT" -eq 124 ]; then
            echo "CASE $CASE_ID TLE score=$BAD_SCORE" > "$RESULTS_DIR/${CASE_ID}.result"
        else
            echo "CASE $CASE_ID RE score=$BAD_SCORE" > "$RESULTS_DIR/${CASE_ID}.result"
        fi
        return 0
    fi

    TESTER_OUTPUT=$(timeout "$TESTER_TIMEOUT" "$TESTER" "$CASE_FILE" "$OUT_FILE" 2>&1 1>/dev/null)
    TESTER_EXIT=$?
    SCORE=$(echo "$TESTER_OUTPUT" | grep -oE 'Score[[:space:]]*=[[:space:]]*[0-9]+' | grep -oE '[0-9]+' | head -1)

    if [ "$TESTER_EXIT" -eq 0 ] && [ -n "$SCORE" ]; then
        echo "CASE $CASE_ID OK score=$SCORE" > "$RESULTS_DIR/${CASE_ID}.result"
    else
        echo "CASE $CASE_ID WA score=$BAD_SCORE" > "$RESULTS_DIR/${CASE_ID}.result"
    fi
}

MAX_JOBS=2
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
for CASE_FILE in "${CASE_FILES[@]}"; do
    CASE_ID=$(basename "$CASE_FILE" .txt)
    RESULT_FILE="$RESULTS_DIR/${CASE_ID}.result"
    if [ -f "$RESULT_FILE" ]; then
        LINE=$(cat "$RESULT_FILE")
    else
        LINE="CASE $CASE_ID RE score=$BAD_SCORE"
    fi
    echo "$LINE"
    STATUS=$(echo "$LINE" | awk '{print $3}')
    SCORE=$(echo "$LINE" | grep -oE 'score=[0-9]+' | cut -d= -f2)
    if [ "$STATUS" = "OK" ]; then
        CASES_OK=$((CASES_OK + 1))
    fi
    TOTAL_SCORE=$((TOTAL_SCORE + SCORE))
done

echo "TOTAL_SCORE $TOTAL_SCORE"
echo "CASES_OK $CASES_OK"
echo "CASES_TOTAL $CASES_TOTAL"
rm -rf "$RESULTS_DIR"
