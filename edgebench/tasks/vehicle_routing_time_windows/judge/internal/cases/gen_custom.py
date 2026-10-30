#!/usr/bin/env python3
"""Generate custom CVRPTW instances for the title's "GH-2000" / "GH-5000"
extensions (used only by reviewers as ablation; not part of the main 56).

The defaults reproduce the same parameter ranges as Solomon C/R/RC plus
Gehring-Homberger 200-1000, scaled up to 2000 / 5000 customers.

Usage:
    python3 gen_custom.py --n 2000 --kind C --seed 42 --out custom_C2000_42.txt
"""
from __future__ import annotations

import argparse
import math
import random
from pathlib import Path

DEPOT_TW_HOURS = 23.0      # service horizon — Solomon style


def gen_clustered(n: int, rng: random.Random) -> list[tuple[float, float]]:
    centers = [(rng.uniform(20, 80), rng.uniform(20, 80)) for _ in range(max(3, n // 30))]
    coords = []
    for _ in range(n):
        cx, cy = rng.choice(centers)
        coords.append((max(0.0, min(100.0, cx + rng.gauss(0, 4))),
                       max(0.0, min(100.0, cy + rng.gauss(0, 4)))))
    return coords


def gen_random(n: int, rng: random.Random) -> list[tuple[float, float]]:
    return [(rng.uniform(0, 100), rng.uniform(0, 100)) for _ in range(n)]


def gen_mixed(n: int, rng: random.Random) -> list[tuple[float, float]]:
    half = n // 2
    return gen_clustered(half, rng) + gen_random(n - half, rng)


def gen_tw(n: int, kind: str, rng: random.Random) -> list[tuple[float, float, float]]:
    """Return (e, l, service) tuples in minutes scale (Solomon convention)."""
    horizon = 23 * 60       # 1380
    out = []
    if kind in ("C", "R", "RC"):
        narrow = kind in ("C", "RC")
        for _ in range(n):
            mid = rng.uniform(20, horizon - 20)
            half = rng.uniform(20, 60) if narrow else rng.uniform(60, 200)
            e = max(0.0, mid - half); l = min(horizon, mid + half)
            out.append((e, l, 10.0))
    else:
        raise ValueError(kind)
    return out


def write_instance(path: Path, name: str, n: int, capacity: int, max_vehicles: int,
                   coords: list[tuple[float, float]],
                   demands: list[int],
                   tws: list[tuple[float, float, float]]) -> None:
    lines = [
        f"NAME : {name}",
        f"DIMENSION : {n + 1}",
        f"CAPACITY : {capacity}",
        f"MAX_VEHICLES : {max_vehicles}",
        "EDGE_WEIGHT_TYPE : EUC_2D_X10",
        "NODE_COORD_SECTION",
        f"0    50.0  50.0",
    ]
    for i, (x, y) in enumerate(coords, start=1):
        lines.append(f"{i:<4d} {x:.1f} {y:.1f}")
    lines.append("DEMAND_SECTION")
    lines.append("0    0")
    for i, q in enumerate(demands, start=1):
        lines.append(f"{i:<4d} {q}")
    lines.append("TIME_WINDOW_SECTION")
    lines.append("0    0  1380")
    for i, (e, l, _) in enumerate(tws, start=1):
        lines.append(f"{i:<4d} {e:.1f}  {l:.1f}")
    lines.append("SERVICE_TIME_SECTION")
    lines.append("0    0")
    for i, (_, _, s) in enumerate(tws, start=1):
        lines.append(f"{i:<4d} {s:.1f}")
    lines.append("DEPOT_SECTION")
    lines.append("0")
    lines.append("-1")
    lines.append("EOF")
    path.write_text("\n".join(lines) + "\n")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--n", type=int, required=True)
    ap.add_argument("--kind", choices=["C", "R", "RC"], required=True)
    ap.add_argument("--seed", type=int, required=True)
    ap.add_argument("--capacity", type=int, default=200)
    ap.add_argument("--max-vehicles", type=int, default=0,
                    help="0 => 0.4*n")
    ap.add_argument("--out", type=Path, required=True)
    args = ap.parse_args()
    rng = random.Random(args.seed)
    n = args.n
    if args.kind == "C":
        coords = gen_clustered(n, rng)
    elif args.kind == "R":
        coords = gen_random(n, rng)
    else:
        coords = gen_mixed(n, rng)
    demands = [rng.randint(5, 40) for _ in range(n)]
    tws     = gen_tw(n, args.kind, rng)
    mv = args.max_vehicles or max(20, int(0.4 * n))
    write_instance(args.out, args.out.stem, n, args.capacity, mv, coords, demands, tws)
    print(f"wrote {args.out}  (n={n}, kind={args.kind}, seed={args.seed})")


if __name__ == "__main__":
    main()
