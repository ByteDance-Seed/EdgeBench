#!/usr/bin/env python3
"""Input generator for Triangulation Coloring (CodeChef TRICOL)."""

from __future__ import annotations

import argparse
import random
import sys
from typing import List, Sequence, Tuple

from delaunay import delaunay_triangles
from triangulation import Point, Triangulation, ccw, normalize_triangle


def has_collinear_triple(points: Sequence[Point]) -> bool:
    n = len(points)
    for i in range(n):
        for j in range(i + 1, n):
            for k in range(j + 1, n):
                if ccw(i, j, k, points) == 0:
                    return True
    return False


def random_points(rng: random.Random, n: int, limit: int = 10_000) -> List[Point]:
    while True:
        pts = [(rng.randint(1, limit), rng.randint(1, limit)) for _ in range(n)]
        if not has_collinear_triple(pts):
            return pts


def delaunay_triangulation(points: Sequence[Point]) -> List[Tuple[int, int, int]]:
    return delaunay_triangles(points)


def random_colors(rng: random.Random, n: int) -> str:
    return "".join(rng.choice("RGB") for _ in range(n))


def apply_random_flips(rng: random.Random, tri: Triangulation, k: int) -> None:
    for _ in range(k):
        edges = tri.list_flippable_edges()
        if not edges:
            break
        u, v = rng.choice(edges)
        tri.flip(u, v)


def format_input(
    n: int,
    x: int,
    y: int,
    p: int,
    q: int,
    colors: str,
    points: Sequence[Point],
    triangles: Sequence[Tuple[int, int, int]],
) -> str:
    lines = [f"{n} {len(triangles)}", f"{x} {y} {p} {q}", colors]
    for px, py in points:
        lines.append(f"{px} {py}")
    for a, b, c in triangles:
        lines.append(f"{a + 1} {b + 1} {c + 1}")
    return "\n".join(lines) + "\n"


def generate(
    seed: int,
    n: int,
    k: int,
    x: int,
    y: int,
    p: int | None = None,
    q: int = 1024,
) -> str:
    if p is None:
        p = n // 2
    rng = random.Random(seed)
    points = random_points(rng, n)
    colors = random_colors(rng, n)
    triangles = delaunay_triangulation(points)
    tri = Triangulation(points, triangles)
    apply_random_flips(rng, tri, k)
    return format_input(n, x, y, p, q, colors, points, tri.triangles)


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate TRICOL test input")
    parser.add_argument("seed", type=int, help="Random seed")
    parser.add_argument("--n", type=int, default=30, help="Number of points (default: 30)")
    parser.add_argument("--k", type=int, default=16, help="Pre-flips during generation")
    parser.add_argument("--x", type=int, default=40, help="Color change cost X")
    parser.add_argument("--y", type=int, default=40, help="Flip cost Y")
    parser.add_argument("--p", type=int, default=None, help="Max color changes (default: N/2)")
    parser.add_argument("--q", type=int, default=1024, help="Max flips Q")
    args = parser.parse_args()

    sys.stdout.write(
        generate(args.seed, args.n, args.k, args.x, args.y, p=args.p, q=args.q)
    )


if __name__ == "__main__":
    main()
