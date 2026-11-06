#!/usr/bin/env bash
# Fetch the 56 Solomon-100 standard CVRPTW benchmark instances from a public
# GitHub mirror, convert them to this project's extended EUC_2D_X10 format,
# and write per-instance .bks files based on SINTEF 2024 BKS quotes.
#
# Usage:  bash fetch_solomon.sh
# Requires: curl, python3 (no third-party packages).
#
# This script is for the Agent's LOCAL development. The remote evaluator runs
# with --network=none and is preloaded with the same data via docker volume.

set -euo pipefail

cd "$(dirname "$0")"

if ! command -v curl >/dev/null 2>&1; then echo "ERROR: curl required" >&2; exit 1; fi
if ! command -v python3 >/dev/null 2>&1; then echo "ERROR: python3 required" >&2; exit 1; fi

# Source: iRB-Lab/py-ga-VRPTW @master (Solomon-100 standard mirror).
URL_BASE="https://raw.githubusercontent.com/iRB-Lab/py-ga-VRPTW/master/data/text"

NAMES=(
    C101 C102 C103 C104 C105 C106 C107 C108 C109
    C201 C202 C203 C204 C205 C206 C207 C208
    R101 R102 R103 R104 R105 R106 R107 R108 R109 R110 R111 R112
    R201 R202 R203 R204 R205 R206 R207 R208 R209 R210 R211
    RC101 RC102 RC103 RC104 RC105 RC106 RC107 RC108
    RC201 RC202 RC203 RC204 RC205 RC206 RC207 RC208
)

mkdir -p _solomon_raw

echo "Downloading 56 Solomon-100 instances ..."
ok=0; fail=0
for name in "${NAMES[@]}"; do
    if curl -sfL --max-time 15 "${URL_BASE}/${name}.txt" -o "_solomon_raw/${name}.txt"; then
        ok=$((ok+1))
    else
        echo "  FAIL: $name"; fail=$((fail+1))
    fi
done
echo "  $ok OK / $fail FAIL"
if [[ "$fail" -gt 0 ]]; then
    echo "Some downloads failed. Re-run the script to retry the missing ones."
    exit 1
fi

# Convert raw Solomon format to this project's extended format.
echo "Converting to extended format ..."
python3 - "$@" <<'PY'
import re, sys
from pathlib import Path

src = Path("_solomon_raw"); dst = Path(".")
n_done = 0
for f in sorted(src.glob("*.txt")):
    text = f.read_text()
    lines = [l.rstrip() for l in text.splitlines()]
    name = lines[0].strip()
    cap = mv = None
    for i, ln in enumerate(lines):
        if ln.strip().startswith("NUMBER"):
            parts = lines[i+1].split()
            mv = int(parts[0]); cap = int(parts[1]); break
    customers = []
    in_table = False
    for ln in lines:
        if "CUST NO" in ln: in_table = True; continue
        if not in_table: continue
        parts = ln.split()
        if len(parts) < 7: continue
        try:
            cid = int(parts[0]); x = float(parts[1]); y = float(parts[2])
            q = int(parts[3]); e = float(parts[4]); l = float(parts[5]); s = float(parts[6])
        except ValueError:
            continue
        customers.append((cid, x, y, q, e, l, s))
    n = len(customers)
    out = [f"NAME : {name}", f"DIMENSION : {n}", f"CAPACITY : {cap}",
           f"MAX_VEHICLES : {mv}", "EDGE_WEIGHT_TYPE : EUC_2D_X10",
           "NODE_COORD_SECTION"]
    for c, x, y, *_ in customers:        out.append(f"{c:<4d} {x:.1f} {y:.1f}")
    out.append("DEMAND_SECTION")
    for c, _, _, q, *_ in customers:     out.append(f"{c:<4d} {q}")
    out.append("TIME_WINDOW_SECTION")
    for c, _, _, _, e, l, _ in customers: out.append(f"{c:<4d} {e:.1f}  {l:.1f}")
    out.append("SERVICE_TIME_SECTION")
    for c, _, _, _, _, _, s in customers: out.append(f"{c:<4d} {s:.1f}")
    out += ["DEPOT_SECTION", "0", "-1", "EOF"]
    (dst / f"{name}.txt").write_text("\n".join(out) + "\n")
    n_done += 1
print(f"  wrote {n_done} extended-format instances")
PY

# SINTEF Solomon-100 BKS (2024 snapshot). Used to populate per-instance .bks
# files so Agent can score itself locally with bench.sh. Hard-coded here for
# offline reproducibility — these are public, widely-cited values.
echo "Writing 56 .bks files (SINTEF 2024 BKS) ..."
python3 - <<'PY'
BKS = {
"C101":(10,828.94),"C102":(10,828.94),"C103":(10,828.06),"C104":(10,824.78),
"C105":(10,828.94),"C106":(10,828.94),"C107":(10,828.94),"C108":(10,828.94),
"C109":(10,828.94),
"C201":(3,591.56),"C202":(3,591.56),"C203":(3,591.17),"C204":(3,590.60),
"C205":(3,588.88),"C206":(3,588.49),"C207":(3,588.29),"C208":(3,588.32),
"R101":(19,1650.80),"R102":(17,1486.12),"R103":(13,1292.68),"R104":(9,1007.31),
"R105":(14,1377.11),"R106":(12,1252.03),"R107":(10,1104.66),"R108":(9,960.88),
"R109":(11,1194.73),"R110":(10,1118.84),"R111":(10,1096.72),"R112":(9,982.14),
"R201":(4,1252.37),"R202":(3,1191.70),"R203":(3,939.50),"R204":(2,825.52),
"R205":(3,994.42),"R206":(3,906.14),"R207":(2,890.61),"R208":(2,726.82),
"R209":(3,909.16),"R210":(3,939.37),"R211":(2,892.71),
"RC101":(14,1696.94),"RC102":(12,1554.75),"RC103":(11,1261.67),"RC104":(10,1135.48),
"RC105":(13,1629.44),"RC106":(11,1424.73),"RC107":(11,1230.48),"RC108":(10,1139.82),
"RC201":(4,1406.91),"RC202":(3,1365.65),"RC203":(3,1049.62),"RC204":(3,798.46),
"RC205":(4,1297.65),"RC206":(3,1146.32),"RC207":(3,1061.14),"RC208":(3,828.14),
}
import os
for name, (nv, td) in BKS.items():
    open(f"{name}.bks", "w").write(f"{nv} {td}\n")
print(f"  wrote {len(BKS)} .bks files")
PY

# Cleanup: keep _solomon_raw for reference but optionally remove
# rm -rf _solomon_raw

echo
echo "Done. Now you have:"
echo "  $(ls C[0-9]*.txt R[0-9]*.txt RC[0-9]*.txt 2>/dev/null | wc -l | tr -d ' ') extended-format instance files"
echo "  $(ls C[0-9]*.bks R[0-9]*.bks RC[0-9]*.bks 2>/dev/null | wc -l | tr -d ' ') .bks files"
echo "  Run 'cd ../.. && make bench' from workspace/ to bench-test your solver."
