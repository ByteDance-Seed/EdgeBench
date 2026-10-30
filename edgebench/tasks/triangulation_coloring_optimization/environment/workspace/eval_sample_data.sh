#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
total=0
for f in sample_data/0*.txt; do
  python3 solution.py < "$f" > /tmp/tricol_sample_out.txt
  line=$(./tools/bin/tester "$f" /tmp/tricol_sample_out.txt 2>&1 | grep 'Score =')
  score=$(echo "$line" | sed -n 's/.*Score = \([0-9]*\).*/\1/p')
  echo "$f: Score = ${score:-?}"
  total=$((total + ${score:-0}))
done
echo "SAMPLE_TOTAL $total"
