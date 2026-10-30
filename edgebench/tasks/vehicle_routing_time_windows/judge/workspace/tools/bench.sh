#!/usr/bin/env bash
# Batch benchmark: run cvrptw_solver on every *.txt in <instances_dir>
# and append a row to <out.csv>.
#
# Usage: bash tools/bench.sh instances/public out_bench.csv [time_budget_sec]
#
# CSV columns: instance,N,NV,TD,BKS_NV,BKS_TD,score,cpu_ms,feasible

set -euo pipefail

INSTANCES_DIR="${1:-instances/public}"
OUT_CSV="${2:-out_bench.csv}"
DEFAULT_BUDGET="${3:-}"   # empty => use per-scale budget table

if [[ ! -x ./cvrptw_solver ]]; then
    echo "ERROR: ./cvrptw_solver not built. Run 'make' first." >&2
    exit 2
fi
if [[ ! -x ./tools/verify ]]; then
    echo "ERROR: ./tools/verify not built. Run 'make verify' first." >&2
    exit 2
fi

scale_budget() {
    local n="$1"
    if   [[ "$n" -le 100  ]]; then echo 60
    elif [[ "$n" -le 200  ]]; then echo 120
    elif [[ "$n" -le 400  ]]; then echo 240
    elif [[ "$n" -le 600  ]]; then echo 360
    elif [[ "$n" -le 800  ]]; then echo 480
    else                            echo 600
    fi
}

# clean previous run output dir
mkdir -p out_bench
echo "instance,N,NV,TD,BKS_NV,BKS_TD,score,cpu_ms,feasible" > "$OUT_CSV"

shopt -s nullglob
for inp in "$INSTANCES_DIR"/*.txt; do
    name="$(basename "${inp%.txt}")"
    out="out_bench/${name}.sol"
    bks="${INSTANCES_DIR}/${name}.bks"
    N="$(awk -F: '/DIMENSION/{gsub(/ /,"",$2); print $2-1; exit}' "$inp")"
    if [[ -n "$DEFAULT_BUDGET" ]]; then
        budget="$DEFAULT_BUDGET"
    else
        budget="$(scale_budget "$N")"
    fi

    t0=$(date +%s%N)
    ./cvrptw_solver "$inp" "$out" "$budget" 2>/dev/null || true
    t1=$(date +%s%N)
    cpu_ms=$(( (t1 - t0) / 1000000 ))

    feasible="false"; NV=""; TD=""
    if [[ -s "$out" ]]; then
        if v="$(./tools/verify "$inp" "$out" 2>/dev/null)"; then
            feasible="true"
            NV=$(echo "$v" | awk '/^NV:/{print $2}')
            TD=$(echo "$v" | awk '/^TD:/{print $2}')
        fi
    fi

    BKS_NV=""; BKS_TD=""; score=""
    if [[ -f "$bks" ]]; then
        read -r BKS_NV BKS_TD < "$bks"
    fi

    if [[ "$feasible" == "true" && -n "$BKS_NV" ]]; then
        score=$(awk -v nv="$NV" -v td="$TD" -v bnv="$BKS_NV" -v btd="$BKS_TD" '
            BEGIN {
                gap_nv = nv - bnv; if (gap_nv < 0) gap_nv = 0;
                gap_td = (td - btd) / btd * 100; if (gap_td < 0) gap_td = 0;
                s = 100 - 30*gap_nv - 0.5*gap_td;
                if (s < 0) s = 0;
                # bonus
                if (nv < bnv) s += 30 * (bnv - nv);
                if (nv <= bnv && td < btd) {
                    b = (btd - td) / btd * 100;
                    if (b > 30) b = 30;
                    s += b;
                }
                if (s > 160) s = 160;
                printf "%.2f", s;
            }')
    else
        score="0.00"
    fi
    printf '%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
        "$name" "$N" "$NV" "$TD" "$BKS_NV" "$BKS_TD" "$score" "$cpu_ms" "$feasible" \
        | tee -a "$OUT_CSV"
done

echo
echo "Aggregate:"
awk -F, 'NR>1 && $9=="true" {n++; sum+=$7} END{ if (n>0) printf "  feasible: %d, mean_score: %.2f\n", n, sum/n; else print "  no feasible solutions" }' "$OUT_CSV"
