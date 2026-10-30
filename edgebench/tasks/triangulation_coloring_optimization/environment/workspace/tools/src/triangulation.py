"""Triangulation with edge-flip support for CodeChef TRICOL."""

from __future__ import annotations

from typing import Iterable, List, Sequence, Tuple

Point = Tuple[int, int]
Triangle = Tuple[int, int, int]


def orient(ax: int, ay: int, bx: int, by: int, cx: int, cy: int) -> int:
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)


def ccw(a: int, b: int, c: int, points: Sequence[Point]) -> int:
    ax, ay = points[a]
    bx, by = points[b]
    cx, cy = points[c]
    return orient(ax, ay, bx, by, cx, cy)


def normalize_edge(u: int, v: int) -> Tuple[int, int]:
    return (u, v) if u < v else (v, u)


def normalize_triangle(a: int, b: int, c: int) -> Triangle:
    return tuple(sorted((a, b, c)))


class Triangulation:
    def __init__(self, points: Sequence[Point], triangles: Iterable[Triangle]):
        self.points: List[Point] = list(points)
        self.triangles: List[Triangle] = [
            normalize_triangle(a, b, c) for a, b, c in triangles
        ]
        self._rebuild_edges()

    def _rebuild_edges(self) -> None:
        self.edge_to_tris: dict[Tuple[int, int], List[Triangle]] = {}
        for tri in self.triangles:
            a, b, c = tri
            for u, v in ((a, b), (b, c), (c, a)):
                key = normalize_edge(u, v)
                self.edge_to_tris.setdefault(key, []).append(tri)

    def has_edge(self, u: int, v: int) -> bool:
        return normalize_edge(u, v) in self.edge_to_tris

    def _triangles_on_edge(self, u: int, v: int) -> List[Triangle]:
        return list(self.edge_to_tris.get(normalize_edge(u, v), []))

    def is_flippable(self, u: int, v: int) -> bool:
        tris = self._triangles_on_edge(u, v)
        if len(tris) != 2:
            return False
        t1, t2 = tris
        a = next(x for x in t1 if x not in (u, v))
        b = next(x for x in t2 if x not in (u, v))
        s1 = ccw(u, v, a, self.points)
        s2 = ccw(u, v, b, self.points)
        if s1 == 0 or s2 == 0:
            return False
        return s1 * s2 < 0

    def flip(self, u: int, v: int) -> None:
        if not self.is_flippable(u, v):
            raise ValueError(f"edge ({u + 1},{v + 1}) is not flippable")

        tris = self._triangles_on_edge(u, v)
        t1, t2 = tris
        a = next(x for x in t1 if x not in (u, v))
        b = next(x for x in t2 if x not in (u, v))

        new_tris = (
            normalize_triangle(a, b, u),
            normalize_triangle(a, b, v),
        )
        self.triangles = [t for t in self.triangles if t not in (t1, t2)]
        self.triangles.extend(new_tris)
        self._rebuild_edges()

    def list_flippable_edges(self) -> List[Tuple[int, int]]:
        res: List[Tuple[int, int]] = []
        seen = set()
        for u, v in self.edge_to_tris:
            if (u, v) in seen:
                continue
            seen.add((u, v))
            if self.is_flippable(u, v):
                res.append((u, v))
        return res

    def count_ugly(self, colors: str) -> int:
        ugly = 0
        for a, b, c in self.triangles:
            ca, cb, cc = colors[a], colors[b], colors[c]
            if ca == cb or cb == cc or ca == cc:
                ugly += 1
        return ugly
