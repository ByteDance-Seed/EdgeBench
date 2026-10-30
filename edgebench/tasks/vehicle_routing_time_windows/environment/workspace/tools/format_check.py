#!/usr/bin/env python3
"""Static format checker for solver output files.

Checks:
  * 'Routes: N' header
  * Exactly N 'Route k: 0 ... 0' lines, k = 1..N
  * Each route starts and ends at depot 0
  * 'Cost: x.xx' line with exactly 2 decimal digits
  * No extra non-empty lines

Usage:
  python3 tools/format_check.py <output.txt>

Exit codes:
  0  format ok
  1  format error
"""
from __future__ import annotations
import re
import sys

ROUTE_RE  = re.compile(r"^Route (\d+): 0((?: \d+)+) 0$")
HEADER_RE = re.compile(r"^Routes: (\d+)$")
COST_RE   = re.compile(r"^Cost: (\d+\.\d{2})$")


def fail(msg: str) -> int:
    print(f"FORMAT_ERROR: {msg}", file=sys.stderr)
    return 1


def check(path: str) -> int:
    try:
        raw = open(path, "r", encoding="utf-8").read()
    except OSError as exc:
        return fail(f"cannot read {path}: {exc}")
    lines = [ln.rstrip("\r") for ln in raw.split("\n")]
    while lines and lines[-1] == "":
        lines.pop()

    if not lines:
        return fail("empty file")
    m = HEADER_RE.match(lines[0])
    if not m:
        return fail(f"first line not 'Routes: <N>': {lines[0]!r}")
    n_decl = int(m.group(1))
    if len(lines) != n_decl + 2:
        return fail(
            f"expected {n_decl + 2} lines (1 header + {n_decl} routes + 1 cost), got {len(lines)}"
        )
    for i in range(1, n_decl + 1):
        rm = ROUTE_RE.match(lines[i])
        if not rm:
            return fail(f"line {i+1} not a valid Route line: {lines[i]!r}")
        if int(rm.group(1)) != i:
            return fail(f"line {i+1} should be 'Route {i}:' but says 'Route {rm.group(1)}:'")
    cm = COST_RE.match(lines[-1])
    if not cm:
        return fail(f"last line not 'Cost: x.xx': {lines[-1]!r}")
    print("FORMAT_OK")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} <output.txt>", file=sys.stderr)
        sys.exit(2)
    sys.exit(check(sys.argv[1]))
