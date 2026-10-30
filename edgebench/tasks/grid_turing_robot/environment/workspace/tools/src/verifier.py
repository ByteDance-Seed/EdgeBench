#!/usr/bin/env python3
"""
Scoring logic for Grid Turing Robot (AHC056).

``tools/bin/tester`` imports this module and is the only supported scoring entry
point. Do not run this file directly to judge your solution.
"""

import sys
from typing import Tuple, Optional


class Verifier:
    def __init__(self, input_file: str):
        with open(input_file, 'r') as f:
            lines = f.readlines()
        idx = 0
        self.N, self.K, self.T = map(int, lines[idx].split())
        idx += 1
        self.v = [lines[idx + i].strip() for i in range(self.N)]
        idx += self.N
        self.h = [lines[idx + i].strip() for i in range(self.N - 1)]
        idx += self.N - 1
        self.targets = []
        for i in range(self.K):
            self.targets.append(tuple(map(int, lines[idx + i].split())))

    def can_move(self, i, j, d):
        if d == 'U':
            if i == 0:
                return False
            return self.h[i - 1][j] == '0'
        elif d == 'D':
            if i == self.N - 1:
                return False
            return self.h[i][j] == '0'
        elif d == 'L':
            if j == 0:
                return False
            return self.v[i][j - 1] == '0'
        elif d == 'R':
            if j == self.N - 1:
                return False
            return self.v[i][j] == '0'
        return False

    def verify(self, output_file: str) -> Tuple[bool, Optional[str], int]:
        """Verify output file. Returns (ok, error_msg, absolute_score)."""
        try:
            with open(output_file, 'r') as f:
                lines = f.readlines()
        except Exception as e:
            return False, f"Cannot read output: {e}", 0

        if not lines:
            return False, "Empty output", 0

        idx = 0
        try:
            parts = lines[idx].split()
            C = int(parts[0])
            Q = int(parts[1])
            M = int(parts[2])
            idx += 1

            if not (1 <= C <= self.N ** 4):
                return False, f"C={C} out of range [1, {self.N**4}]", 0
            if not (1 <= Q <= self.N ** 4):
                return False, f"Q={Q} out of range [1, {self.N**4}]", 0
            if not (0 <= M <= self.T):
                return False, f"M={M} out of range [0, {self.T}]", 0

            initial_colors = []
            for i in range(self.N):
                row = list(map(int, lines[idx + i].split()))
                if len(row) != self.N:
                    return False, f"Row {i}: expected {self.N} colors, got {len(row)}", 0
                for c in row:
                    if not (0 <= c < C):
                        return False, f"Color {c} out of range [0, {C-1}]", 0
                initial_colors.append(row)
            idx += self.N

            rules = {}
            for i in range(M):
                parts = lines[idx + i].split()
                c = int(parts[0])
                q = int(parts[1])
                a = int(parts[2])
                s = int(parts[3])
                d = parts[4]
                if (c, q) in rules:
                    return False, f"Duplicate rule for (c={c}, q={q})", 0
                if not (0 <= c < C):
                    return False, f"Rule color {c} out of range", 0
                if not (0 <= q < Q):
                    return False, f"Rule state {q} out of range", 0
                if not (0 <= a < C):
                    return False, f"Rule repaint {a} out of range", 0
                if not (0 <= s < Q):
                    return False, f"Rule new state {s} out of range", 0
                if d not in ('U', 'D', 'L', 'R', 'S'):
                    return False, f"Invalid direction: {d}", 0
                rules[(c, q)] = (a, s, d)
        except Exception as e:
            return False, f"Output format error: {e}", 0

        # Simulation
        curr_i, curr_j = self.targets[0]
        curr_q = 0
        curr_grid = [row[:] for row in initial_colors]

        visited_count = 1  # Start at target 0
        next_target_idx = 1

        for t in range(self.T):
            c = curr_grid[curr_i][curr_j]
            if (c, curr_q) not in rules:
                break

            a, s, d = rules[(c, curr_q)]

            # Repaint
            curr_grid[curr_i][curr_j] = a
            # Update state
            curr_q = s
            # Move
            if d != 'S':
                if self.can_move(curr_i, curr_j, d):
                    di, dj = {'U': (-1, 0), 'D': (1, 0), 'L': (0, -1), 'R': (0, 1)}[d]
                    curr_i += di
                    curr_j += dj

            # Check if reached current destination
            if next_target_idx < self.K:
                ti, tj = self.targets[next_target_idx]
                if curr_i == ti and curr_j == tj:
                    visited_count += 1
                    next_target_idx += 1

        V = visited_count
        if V == self.K:
            abs_score = C + Q
        else:
            abs_score = 2 * (self.N ** 4) + (self.K - V) * (self.N ** 2)

        return True, None, abs_score


def main():
    if len(sys.argv) < 3:
        print("Usage: python verifier.py <input_file> <output_file>", file=sys.stderr)
        sys.exit(1)

    v = Verifier(sys.argv[1])
    ok, err, score = v.verify(sys.argv[2])
    if not ok:
        print(f"INVALID: {err}", file=sys.stderr)
        sys.exit(1)
    else:
        print(f"Score: {score}", file=sys.stderr)


if __name__ == "__main__":
    main()
