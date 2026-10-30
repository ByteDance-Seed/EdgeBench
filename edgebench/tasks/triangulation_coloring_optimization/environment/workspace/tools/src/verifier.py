#!/usr/bin/env python3
"""Full verifier for Triangulation Coloring (CodeChef TRICOL).

Applies output flips on the input triangulation, then counts ugly triangles
on the final triangulation with the final colors.
"""

from __future__ import annotations

import sys
from typing import Optional, Tuple

from triangulation import Point, Triangulation, normalize_triangle


class Verifier:
    def __init__(self, input_file: str):
        with open(input_file, "r") as f:
            self.input_data = f.read().split()

    def verify(self, output_file: str) -> Tuple[bool, Optional[str], int]:
        try:
            with open(output_file, "r") as f:
                output_lines = f.read().strip().split("\n")
        except OSError as e:
            return False, f"Cannot read output file: {e}", 0

        idx = 0
        n = int(self.input_data[idx]); idx += 1
        m = int(self.input_data[idx]); idx += 1
        x = int(self.input_data[idx]); idx += 1
        y = int(self.input_data[idx]); idx += 1
        p = int(self.input_data[idx]); idx += 1
        q = int(self.input_data[idx]); idx += 1
        s = self.input_data[idx]; idx += 1

        points: list[Point] = []
        for _ in range(n):
            px = int(self.input_data[idx]); idx += 1
            py = int(self.input_data[idx]); idx += 1
            points.append((px, py))

        triangles = []
        for _ in range(m):
            a = int(self.input_data[idx]) - 1; idx += 1
            b = int(self.input_data[idx]) - 1; idx += 1
            c = int(self.input_data[idx]) - 1; idx += 1
            triangles.append(normalize_triangle(a, b, c))

        try:
            if len(output_lines) < 2:
                return False, "Insufficient output lines", 0

            parts = output_lines[0].split()
            if len(parts) != 2:
                return False, "Invalid first line format (expected C F)", 0

            c = int(parts[0])
            f = int(parts[1])
            if c < 0:
                return False, f"Negative color changes C={c}", 0
            if f < 0:
                return False, f"Negative flips F={f}", 0
            if c > p:
                return False, f"Color changes {c} > P={p}", 0
            if f > q:
                return False, f"Flips {f} > Q={q}", 0

            final_colors = output_lines[1].strip()
            if len(final_colors) != n:
                return False, f"Color string length {len(final_colors)} != {n}", 0
            for ch in final_colors:
                if ch not in "RGB":
                    return False, f"Invalid color: {ch}", 0

            actual_changes = sum(1 for i in range(n) if final_colors[i] != s[i])
            if actual_changes != c:
                return False, f"Actual changes {actual_changes} != claimed {c}", 0

            flips = []
            for i in range(f):
                if 2 + i >= len(output_lines):
                    return False, f"Missing flip {i}", 0
                fparts = output_lines[2 + i].split()
                if len(fparts) != 2:
                    return False, f"Invalid flip format at line {2 + i}", 0
                u = int(fparts[0]) - 1
                v = int(fparts[1]) - 1
                if u < 0 or u >= n or v < 0 or v >= n:
                    return False, f"Flip vertex out of range: {u + 1} {v + 1}", 0
                if u == v:
                    return False, f"Self-loop flip: {u + 1} {v + 1}", 0
                flips.append((u, v))

            tri = Triangulation(points, triangles)
            for u, v in flips:
                if not tri.has_edge(u, v):
                    return False, f"Flip edge ({u + 1},{v + 1}) not in triangulation", 0
                if not tri.is_flippable(u, v):
                    return False, f"Invalid flip ({u + 1},{v + 1})", 0
                tri.flip(u, v)

            ugly = tri.count_ugly(final_colors)
            score = x * c + y * f + ugly * ugly
            return True, None, score

        except Exception as e:
            return False, f"Error parsing output: {e}", 0


def main() -> None:
    if len(sys.argv) < 3:
        print("Usage: python verifier.py <input_file> <output_file>", file=sys.stderr)
        sys.exit(1)

    v = Verifier(sys.argv[1])
    ok, err, score = v.verify(sys.argv[2])
    if not ok:
        print(f"INVALID: {err}", file=sys.stderr)
        sys.exit(1)
    print(f"Score: {score}", file=sys.stderr)


if __name__ == "__main__":
    main()
