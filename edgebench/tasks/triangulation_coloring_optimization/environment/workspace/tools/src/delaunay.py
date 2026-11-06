"""Bowyer-Watson Delaunay triangulation (pure Python, no scipy)."""

from __future__ import annotations

import math
from typing import List, Sequence, Tuple

from triangulation import Point, normalize_triangle

Triangle = Tuple[int, int, int]


def _circumcircle_contains(
    ax: float, ay: float, bx: float, by: float, cx: float, cy: float, px: float, py: float
) -> bool:
    d = 2.0 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by))
    if abs(d) < 1e-12:
        return False
    ux = (
        (ax * ax + ay * ay) * (by - cy)
        + (bx * bx + by * by) * (cy - ay)
        + (cx * cx + cy * cy) * (ay - by)
    ) / d
    uy = (
        (ax * ax + ay * ay) * (cx - bx)
        + (bx * bx + by * by) * (ax - cx)
        + (cx * cx + cy * cy) * (bx - ax)
    ) / d
    r2 = (ax - ux) ** 2 + (ay - uy) ** 2
    return (px - ux) ** 2 + (py - uy) ** 2 <= r2 + 1e-9


def _edge_key(a: int, b: int) -> Tuple[int, int]:
    return (a, b) if a < b else (b, a)


def delaunay_triangles(points: Sequence[Point]) -> List[Triangle]:
    """Return Delaunay triangles as 0-indexed vertex triples."""
    n = len(points)
    if n < 3:
        raise ValueError("need at least 3 points")

    minx = min(p[0] for p in points)
    miny = min(p[1] for p in points)
    maxx = max(p[0] for p in points)
    maxy = max(p[1] for p in points)
    dx = maxx - minx
    dy = maxy - miny
    delta = max(dx, dy, 1) * 20.0

    super_a = n
    super_b = n + 1
    super_c = n + 2
    all_pts: List[Point] = list(points) + [
        (minx - delta, miny - delta),
        (minx + dx * 0.5, maxy + delta),
        (maxx + delta, miny - delta),
    ]

    triangles: List[List[int]] = [[super_a, super_b, super_c]]

    for pi in range(n):
        px, py = all_pts[pi]
        bad: List[int] = []
        for idx, tri in enumerate(triangles):
            a, b, c = tri
            ax, ay = all_pts[a]
            bx, by = all_pts[b]
            cx, cy = all_pts[c]
            if _circumcircle_contains(ax, ay, bx, by, cx, cy, px, py):
                bad.append(idx)

        boundary: dict[Tuple[int, int], int] = {}
        for idx in bad:
            a, b, c = triangles[idx]
            for u, v in ((a, b), (b, c), (c, a)):
                key = _edge_key(u, v)
                boundary[key] = boundary.get(key, 0) + 1

        hole_edges = [e for e, cnt in boundary.items() if cnt == 1]

        for idx in sorted(bad, reverse=True):
            triangles.pop(idx)

        for u, v in hole_edges:
            triangles.append([pi, u, v])

    result: List[Triangle] = []
    for a, b, c in triangles:
        if a < n and b < n and c < n:
            result.append(normalize_triangle(a, b, c))
    return result
