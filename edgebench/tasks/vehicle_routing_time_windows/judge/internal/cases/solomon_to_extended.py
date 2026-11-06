#!/usr/bin/env python3
"""Convert Solomon-100 raw format to this project's extended format.

Input  (one Solomon file):
    C101

    VEHICLE
    NUMBER     CAPACITY
      25         200

    CUSTOMER
    CUST NO.  XCOORD.   YCOORD.    DEMAND   READY TIME  DUE DATE   SERVICE   TIME

        0      40         50          0          0       1236          0
        1      45         68         10        912        967         90
    ...

Output (extended format, see workspace/README.md):
    NAME : C101
    DIMENSION : 101
    CAPACITY : 200
    MAX_VEHICLES : 25
    EDGE_WEIGHT_TYPE : EUC_2D_X10
    NODE_COORD_SECTION
    0   40.0  50.0
    1   45.0  68.0
    ...
    DEMAND_SECTION
    0   0
    ...
    TIME_WINDOW_SECTION
    0   0  1236
    ...
    SERVICE_TIME_SECTION
    0   0
    ...
    DEPOT_SECTION
    0
    -1
    EOF

Usage:
    python3 solomon_to_extended.py raw_solomon100/ raw/
"""
from __future__ import annotations

import argparse
import re
from pathlib import Path


def parse_solomon(text: str) -> tuple[str, int, int, list[tuple[int, float, float, int, float, float, float]]]:
    lines = [l.rstrip() for l in text.splitlines()]
    name = lines[0].strip()
    # Find capacity line: typically line 4 has "  K   Q"
    cap = None; max_vehicles = None
    for i, ln in enumerate(lines):
        if ln.strip().startswith("NUMBER"):
            parts = lines[i + 1].split()
            max_vehicles = int(parts[0])
            cap = int(parts[1])
            break
    if cap is None: raise ValueError(f"cannot parse capacity in {name}")

    # Find customer rows (after "CUST NO." header)
    customers = []
    in_table = False
    for ln in lines:
        if "CUST NO" in ln:
            in_table = True; continue
        if not in_table: continue
        parts = ln.split()
        if len(parts) < 7: continue
        try:
            cid    = int(parts[0])
            x      = float(parts[1])
            y      = float(parts[2])
            demand = int(parts[3])
            ready  = float(parts[4])
            due    = float(parts[5])
            svc    = float(parts[6])
        except ValueError:
            continue
        customers.append((cid, x, y, demand, ready, due, svc))
    return name, cap, max_vehicles, customers


def write_extended(out_path: Path, name: str, cap: int, max_vehicles: int,
                   customers: list[tuple[int, float, float, int, float, float, float]]) -> None:
    n = len(customers)
    lines = [
        f"NAME : {name}",
        f"DIMENSION : {n}",
        f"CAPACITY : {cap}",
        f"MAX_VEHICLES : {max_vehicles}",
        "EDGE_WEIGHT_TYPE : EUC_2D_X10",
        "NODE_COORD_SECTION",
    ]
    for cid, x, y, _, _, _, _ in customers:
        lines.append(f"{cid:<4d} {x:.1f} {y:.1f}")
    lines.append("DEMAND_SECTION")
    for cid, _, _, q, _, _, _ in customers:
        lines.append(f"{cid:<4d} {q}")
    lines.append("TIME_WINDOW_SECTION")
    for cid, _, _, _, e, l, _ in customers:
        lines.append(f"{cid:<4d} {e:.1f}  {l:.1f}")
    lines.append("SERVICE_TIME_SECTION")
    for cid, _, _, _, _, _, s in customers:
        lines.append(f"{cid:<4d} {s:.1f}")
    lines.append("DEPOT_SECTION")
    lines.append("0")
    lines.append("-1")
    lines.append("EOF")
    out_path.write_text("\n".join(lines) + "\n")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("src", type=Path, help="dir of raw Solomon files")
    ap.add_argument("dst", type=Path, help="output dir for extended format")
    args = ap.parse_args()
    args.dst.mkdir(parents=True, exist_ok=True)
    files = sorted(args.src.glob("*.txt"))
    print(f"Converting {len(files)} files: {args.src} -> {args.dst}")
    for src in files:
        try:
            name, cap, mv, custs = parse_solomon(src.read_text())
            assert custs[0][0] == 0, f"{name}: depot id != 0"
            assert custs[0][3] == 0, f"{name}: depot demand != 0"
            write_extended(args.dst / f"{name}.txt", name, cap, mv, custs)
        except Exception as exc:
            print(f"  FAIL: {src.name}: {exc}")
    print(f"Done. Wrote {len(list(args.dst.glob('*.txt')))} files.")


if __name__ == "__main__":
    main()
