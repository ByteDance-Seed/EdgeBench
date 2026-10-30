#!/usr/bin/env python3
"""
Interactive Runner for Treant's Forest (AHC054).

This is the original interactive runner that runs solutions via bidirectional pipes.
The batch tester (tools/bin/tester) embeds the same game logic but operates on
pre-recorded output files instead.

Usage:
    python interactive_runner.py --seed 42 -- python solution.py
"""

import subprocess
import sys
import random
import argparse
import time
from pathlib import Path
from collections import deque
from typing import List, Dict, Any, Tuple, Optional, Set


class TreantsForestRunner:
    """Runner for Treants Forest problem"""

    def __init__(self, problem_dir=".", timeout=60.0, verbose=False, seed=None):
        self.problem_dir = Path(problem_dir)
        self.test_cases_dir = self.problem_dir / "test_cases"
        self.solution_path = self.problem_dir / "solution.py"
        self.timeout = timeout
        self.verbose = verbose
        self.seed = seed
        self.rng = random.Random(seed) if seed is not None else random.Random()

        self.N = 0
        self.ti = 0
        self.tj = 0
        self.grid = []
        self.adventurer_pos = (0, 0)
        self.revealed = set()
        self.destination = None
        self.entrance = (0, 0)

    def log(self, *args, **kwargs):
        if self.verbose:
            print(*args, file=sys.stderr, **kwargs)

    def rand(self, L, U):
        return self.rng.randint(L, U)

    def generate_forest(self):
        self.N = self.rand(20, 40)
        self.grid = [[0 for _ in range(self.N)] for _ in range(self.N)]
        self.entrance = (0, self.N // 2)
        max_trees = max(1, self.rand(0, (self.N * self.N) // 6))
        cells = [(i, j) for i in range(self.N) for j in range(self.N)
                 if not (i == self.entrance[0] and j == self.entrance[1])]
        self.rng.shuffle(cells)
        tree_count = 0
        for i, j in cells:
            if tree_count >= max_trees:
                break
            self.grid[i][j] = 1
            if self._check_connectivity():
                tree_count += 1
            else:
                self.grid[i][j] = 0
        empty_cells = [(i, j) for i in range(self.N) for j in range(self.N)
                       if self.grid[i][j] == 0 and (i, j) != self.entrance]
        valid_aa = [(i, j) for i, j in empty_cells
                    if abs(i - self.entrance[0]) + abs(j - self.entrance[1]) >= 5]
        if valid_aa:
            self.ti, self.tj = self.rng.choice(valid_aa)
        else:
            self.ti, self.tj = self.rng.choice(empty_cells)
        self.adventurer_pos = self.entrance
        self.revealed = {self.entrance}
        self.destination = None

    def _check_connectivity(self):
        start = self.entrance
        visited = set([start])
        queue = deque([start])
        while queue:
            i, j = queue.popleft()
            for di, dj in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                ni, nj = i + di, j + dj
                if (0 <= ni < self.N and 0 <= nj < self.N and
                    (ni, nj) not in visited and self.grid[ni][nj] == 0):
                    visited.add((ni, nj))
                    queue.append((ni, nj))
        for i in range(self.N):
            for j in range(self.N):
                if self.grid[i][j] == 0 and (i, j) not in visited:
                    return False
        return True

    def _is_valid_cell(self, i, j):
        return 0 <= i < self.N and 0 <= j < self.N and self.grid[i][j] == 0

    def _reveal_cells(self, pi, pj):
        newly_revealed = set()
        for di, dj in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            i, j = pi, pj
            while True:
                i += di
                j += dj
                if not (0 <= i < self.N and 0 <= j < self.N):
                    break
                newly_revealed.add((i, j))
                if self.grid[i][j] == 1:
                    break
        return newly_revealed

    def _find_path(self, start, goal):
        if start == goal:
            return [start]
        visited = {start: None}
        queue = deque([start])
        while queue:
            pos = queue.popleft()
            i, j = pos
            for di, dj in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                ni, nj = i + di, j + dj
                next_pos = (ni, nj)
                if self._is_valid_cell(ni, nj) and next_pos not in visited:
                    visited[next_pos] = pos
                    if next_pos == goal:
                        path = [goal]
                        current = goal
                        while visited[current] is not None:
                            current = visited[current]
                            path.append(current)
                        path.reverse()
                        return path
                    queue.append(next_pos)
        return None

    def _is_reachable(self, start, goal):
        return self._find_path(start, goal) is not None

    def _get_tentative_map_reachable(self, start):
        visited = set([start])
        queue = deque([start])
        while queue:
            i, j = queue.popleft()
            for di, dj in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                ni, nj = i + di, j + dj
                next_pos = (ni, nj)
                if next_pos in visited:
                    continue
                if 0 <= ni < self.N and 0 <= nj < self.N:
                    if next_pos in self.revealed:
                        if self.grid[ni][nj] == 0:
                            visited.add(next_pos)
                            queue.append(next_pos)
                    else:
                        visited.add(next_pos)
                        queue.append(next_pos)
        return visited


def main():
    parser = argparse.ArgumentParser(description="Treants Forest Interactive Runner")
    parser.add_argument("--seed", type=int, help="Random seed")
    parser.add_argument("--verbose", action="store_true")
    parser.add_argument("--timeout", type=float, default=60.0)
    parser.add_argument("--problem-dir", type=Path, default=Path("."))
    parser.add_argument("solution", nargs="*")
    args = parser.parse_args()

    runner = TreantsForestRunner(
        problem_dir=str(args.problem_dir),
        timeout=args.timeout,
        verbose=args.verbose,
        seed=args.seed
    )
    print("Interactive runner - use tools/bin/tester for batch evaluation")


if __name__ == "__main__":
    main()
