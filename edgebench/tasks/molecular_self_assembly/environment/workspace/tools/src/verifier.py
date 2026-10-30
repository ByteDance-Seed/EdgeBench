#!/usr/bin/env python3
"""
Reference verifier for A_Molecules (AHC057).

Official scoring uses ``tools/bin/tester`` only. This file is for reading the
rules; it may drift from ``bin/tester``. Do not use it as the sole judge.
"""

import sys
import math
from typing import Tuple, Optional, List

class Verifier:
    def __init__(self, input_file: str):
        self.input_file = input_file
        self.N, self.T, self.M, self.K, self.L = 0, 0, 0, 0, 0
        self.points = []
        self._read_input()

    def _read_input(self):
        with open(self.input_file, 'r') as f:
            data = f.read().split()
        idx = 0
        self.N = int(data[idx]); idx += 1
        self.T = int(data[idx]); idx += 1
        self.M = int(data[idx]); idx += 1
        self.K = int(data[idx]); idx += 1
        self.L = int(data[idx]); idx += 1

        for i in range(self.N):
            x = int(data[idx]); idx += 1
            y = int(data[idx]); idx += 1
            vx = int(data[idx]); idx += 1
            vy = int(data[idx]); idx += 1
            self.points.append([x, y, vx, vy])

    def toroidal_dist(self, x1: float, y1: float, x2: float, y2: float) -> float:
        dx = abs(x1 - x2)
        dy = abs(y1 - y2)
        dx = min(self.L - dx, dx)
        dy = min(self.L - dy, dy)
        return round(math.sqrt(dx * dx + dy * dy))

    def verify(self, output_file: str) -> Tuple[bool, Optional[str], float]:
        try:
            with open(output_file, 'r') as f:
                lines = f.read().strip().split('\n')
        except Exception as e:
            return False, f"Cannot read output file: {e}", 0.0

        bonds = []
        for line in lines:
            if not line.strip():
                continue
            parts = line.split()
            if len(parts) != 3:
                return False, f"Invalid line format: {line}", 0.0
            try:
                t = int(parts[0])
                i = int(parts[1])
                j = int(parts[2])
            except ValueError:
                return False, f"Invalid numbers: {line}", 0.0

            if t < 0 or t >= self.T:
                return False, f"Time t={t} out of range [0, {self.T})", 0.0
            if i < 0 or i >= self.N or j < 0 or j >= self.N:
                return False, f"Indices out of range: i={i}, j={j}", 0.0
            if i == j:
                return False, f"Cannot bond point with itself: i=j={i}", 0.0

            bonds.append((t, i, j))

        # Check number of bonds
        if len(bonds) != self.N - self.M:
            return False, f"Expected {self.N - self.M} bonds, got {len(bonds)}", 0.0

        # Sort by time
        bonds.sort(key=lambda x: x[0])

        # Simulate
        parent = list(range(self.N))
        size = [1] * self.N
        vx = [float(p[2]) for p in self.points]
        vy = [float(p[3]) for p in self.points]
        pos = [[float(p[0]), float(p[1])] for p in self.points]

        def find(x):
            if parent[x] != x:
                parent[x] = find(parent[x])
            return parent[x]

        def union(x, y, vx_new, vy_new):
            px, py = find(x), find(y)
            if px == py:
                return False
            if size[px] < size[py]:
                px, py = py, px
            parent[py] = px
            size[px] += size[py]
            vx[px] = vx_new
            vy[py] = vy_new
            return True

        total_cost = 0.0
        bond_idx = 0

        for t in range(self.T):
            # Bonding phase
            while bond_idx < len(bonds) and bonds[bond_idx][0] == t:
                _, i, j = bonds[bond_idx]
                pi, pj = find(i), find(j)
                if pi == pj:
                    return False, f"Bonding already connected points at t={t}: {i}, {j}", 0.0

                cost = self.toroidal_dist(pos[i][0], pos[i][1], pos[j][0], pos[j][1])
                total_cost += cost

                # Conservation of momentum
                si, sj = size[pi], size[pj]
                vxi, vyi = vx[pi], vy[pi]
                vxj, vyj = vx[pj], vy[pj]
                vx_new = (si * vxi + sj * vxj) / (si + sj)
                vy_new = (si * vyi + sj * vyj) / (si + sj)

                union(i, j, vx_new, vy_new)
                bond_idx += 1

            # Movement phase
            for i in range(self.N):
                pi = find(i)
                pos[i][0] = (pos[i][0] + vx[pi]) % self.L
                pos[i][1] = (pos[i][1] + vy[pi]) % self.L

        # Check final state
        comps = set()
        for i in range(self.N):
            comps.add(find(i))

        if len(comps) != self.M:
            return False, f"Expected {self.M} components, got {len(comps)}", 0.0

        for c in comps:
            if size[c] != self.K:
                return False, f"Component {c} has size {size[c]}, expected {self.K}", 0.0

        # Calculate score: round(10^6 * log2(L * (N - M) / (D_sum + 1)))
        numerator = self.L * (self.N - self.M)
        raw_score = round(1e6 * math.log2(numerator / (total_cost + 1)))
        return True, None, max(0, raw_score)


def main():
    if len(sys.argv) < 3:
        print("Usage: python verifier.py <input_file> <output_file>")
        sys.exit(1)

    verifier = Verifier(sys.argv[1])
    is_valid, error_msg, score = verifier.verify(sys.argv[2])

    if not is_valid:
        print(f"INVALID: {error_msg}")
        sys.exit(1)
    print(
        "Note: official scoring uses ./bin/tester (not this script).",
        file=sys.stderr,
    )
    print(f"Reference score (unofficial): {score:.2f}")

if __name__ == "__main__":
    main()
