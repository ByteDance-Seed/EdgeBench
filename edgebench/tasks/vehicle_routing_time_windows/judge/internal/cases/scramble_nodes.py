#!/usr/bin/env python3
"""Scramble node IDs in CVRPTW instances to defeat hard-coded answer attacks.

For each input file, we generate:
  * <name>_<hash>.txt     -- same geometry, but customer IDs randomly permuted
                             (depot id stays 0). The 4-char hash suffix prevents
                             Agents from guessing the original instance name.
  * scramble_map.json     -- one big dict mapping new_name -> {orig_name,
                             id_perm: [orig_id_for_new_id_1..N]}, used by the
                             evaluator to reconstruct ground-truth scoring.

Usage:
    python3 scramble_nodes.py \
        --src /path/to/raw_instances \
        --dst /path/to/cases \
        --map /path/to/scramble_map.json \
        --seed 20260507

Idempotent: re-running with the same seed yields the same scrambling.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import random
import re
from pathlib import Path
from typing import Any


SECTION_RE = re.compile(r"^[A-Z_]+_SECTION\s*$")


def parse_instance(path: Path) -> dict[str, Any]:
    """Light-weight parser: returns {header, nodes:[{id,x,y,demand,e,l,s}]}."""
    head: dict[str, Any] = {"name": path.stem}
    nodes_by_id: dict[int, dict[str, Any]] = {}
    section: str | None = None
    for raw in path.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith("EOF"):
            continue
        if line.startswith("NAME"):       head["name"] = line.split(":")[1].strip();  continue
        if line.startswith("DIMENSION"):  head["dim"] = int(line.split(":")[1]);     continue
        if line.startswith("CAPACITY"):   head["cap"] = int(line.split(":")[1]);     continue
        if line.startswith("MAX_VEHICLES"):head["mv"] = int(line.split(":")[1]);     continue
        if line.startswith("EDGE_WEIGHT_TYPE"): continue
        if SECTION_RE.match(line):
            section = line.split("_SECTION")[0]
            continue
        if section == "NODE_COORD":
            i, x, y = line.split(); i = int(i)
            nodes_by_id.setdefault(i, {"id": i})
            nodes_by_id[i]["x"] = float(x); nodes_by_id[i]["y"] = float(y)
        elif section == "DEMAND":
            i, q = line.split(); i = int(i)
            nodes_by_id.setdefault(i, {"id": i})["demand"] = int(q)
        elif section == "TIME_WINDOW":
            i, e, l = line.split(); i = int(i)
            nodes_by_id.setdefault(i, {"id": i})["e"] = float(e)
            nodes_by_id[i]["l"] = float(l)
        elif section == "SERVICE_TIME":
            i, s = line.split(); i = int(i)
            nodes_by_id.setdefault(i, {"id": i})["s"] = float(s)
        elif section == "DEPOT":
            pass
    nodes = [nodes_by_id[i] for i in sorted(nodes_by_id)]
    return {"header": head, "nodes": nodes}


def write_instance(path: Path, header: dict[str, Any], nodes: list[dict[str, Any]]) -> None:
    n = len(nodes)
    lines = [
        f"NAME : {header['name']}",
        f"DIMENSION : {n}",
        f"CAPACITY : {header['cap']}",
        f"MAX_VEHICLES : {header['mv']}",
        "EDGE_WEIGHT_TYPE : EUC_2D_X10",
        "NODE_COORD_SECTION",
    ]
    for nd in nodes:
        lines.append(f"{nd['id']:<4d} {nd['x']:.1f} {nd['y']:.1f}")
    lines.append("DEMAND_SECTION")
    for nd in nodes: lines.append(f"{nd['id']:<4d} {nd['demand']}")
    lines.append("TIME_WINDOW_SECTION")
    for nd in nodes: lines.append(f"{nd['id']:<4d} {nd['e']:.1f}  {nd['l']:.1f}")
    lines.append("SERVICE_TIME_SECTION")
    for nd in nodes: lines.append(f"{nd['id']:<4d} {nd['s']:.1f}")
    lines.append("DEPOT_SECTION")
    lines.append("0")
    lines.append("-1")
    lines.append("EOF")
    path.write_text("\n".join(lines) + "\n")


def scramble(inst: dict[str, Any], rng: random.Random) -> tuple[dict[str, Any], list[int], str]:
    """Permute customer IDs (depot stays 0). Return (new_inst, id_perm, suffix)."""
    nodes = inst["nodes"]
    n = len(nodes)        # includes depot at idx 0
    cust_ids = [nd["id"] for nd in nodes if nd["id"] != 0]
    perm = cust_ids[:]; rng.shuffle(perm)
    # mapping: new_id (1..N) -> old_id
    new_to_old = {0: 0}
    for new_id, old_id in zip(range(1, len(perm) + 1), perm):
        new_to_old[new_id] = old_id
    by_old = {nd["id"]: nd for nd in nodes}
    new_nodes = []
    for new_id in range(n):
        old = by_old[new_to_old[new_id]]
        new_nodes.append({**old, "id": new_id})
    suffix = hashlib.sha256(f"{inst['header']['name']}|{rng.random()}".encode()).hexdigest()[:6]
    new_header = dict(inst["header"])
    new_header["name"] = f"{inst['header']['name']}_{suffix}"
    return ({"header": new_header, "nodes": new_nodes},
            [new_to_old[i] for i in range(n)],
            suffix)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", required=True, type=Path)
    ap.add_argument("--dst", required=True, type=Path)
    ap.add_argument("--map", required=True, type=Path)
    ap.add_argument("--seed", default=20260507, type=int)
    args = ap.parse_args()
    args.dst.mkdir(parents=True, exist_ok=True)
    rng = random.Random(args.seed)
    smap: dict[str, Any] = {}
    files = sorted(args.src.glob("*.txt"))
    print(f"Scrambling {len(files)} instances ...")
    for src in files:
        inst = parse_instance(src)
        new_inst, id_perm, suffix = scramble(inst, rng)
        out = args.dst / f"{new_inst['header']['name']}.txt"
        write_instance(out, new_inst["header"], new_inst["nodes"])
        smap[new_inst["header"]["name"]] = {
            "orig_name": inst["header"]["name"],
            "id_perm":   id_perm,
        }
    args.map.write_text(json.dumps(smap, indent=2))
    print(f"Done. {len(smap)} entries in {args.map}")


if __name__ == "__main__":
    main()
