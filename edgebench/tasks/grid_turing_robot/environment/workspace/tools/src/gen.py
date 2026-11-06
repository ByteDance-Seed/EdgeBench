#!/usr/bin/env python3
"""Input generator for Grid Turing Robot (AHC056).
Usage: ./gen <seed>
Outputs test input to stdout.

Generation algorithm (from problem statement):
1. N = rand(10, 20)
2. W = rand(0, N-1) wall segments
3. Start with no internal walls. Repeat W times:
   - Choose a vertex not adjacent to any existing wall
   - Choose a direction (U/D/L/R)
   - Extend wall from that vertex until it hits another wall
4. K = rand(N, N^2) destinations
5. Shuffle N^2 cells, take first K
6. X = minimum moves to visit all destinations in order (BFS shortest path sum)
7. T = rand(X, 2X)
"""
import sys
import random
from collections import deque


def bfs_shortest(N, v_walls, h_walls, start, goal):
    """BFS shortest path on the grid with walls.
    v_walls[i][j] = True means wall between (i,j) and (i,j+1)
    h_walls[i][j] = True means wall between (i,j) and (i+1,j)
    """
    if start == goal:
        return 0
    dist = [[-1] * N for _ in range(N)]
    si, sj = start
    gi, gj = goal
    dist[si][sj] = 0
    q = deque([(si, sj)])
    while q:
        ci, cj = q.popleft()
        if ci == gi and cj == gj:
            return dist[ci][cj]
        # Up: (ci-1, cj) - check h_walls[ci-1][cj]
        if ci > 0 and not h_walls[ci - 1][cj] and dist[ci - 1][cj] == -1:
            dist[ci - 1][cj] = dist[ci][cj] + 1
            q.append((ci - 1, cj))
        # Down: (ci+1, cj) - check h_walls[ci][cj]
        if ci < N - 1 and not h_walls[ci][cj] and dist[ci + 1][cj] == -1:
            dist[ci + 1][cj] = dist[ci][cj] + 1
            q.append((ci + 1, cj))
        # Left: (ci, cj-1) - check v_walls[ci][cj-1]
        if cj > 0 and not v_walls[ci][cj - 1] and dist[ci][cj - 1] == -1:
            dist[ci][cj - 1] = dist[ci][cj] + 1
            q.append((ci, cj - 1))
        # Right: (ci, cj+1) - check v_walls[ci][cj]
        if cj < N - 1 and not v_walls[ci][cj] and dist[ci][cj + 1] == -1:
            dist[ci][cj + 1] = dist[ci][cj] + 1
            q.append((ci, cj + 1))
    # Should always be reachable
    return -1


def generate(seed):
    rng = random.Random(seed)

    N = rng.randint(10, 20)

    # Wall data: v_walls[i][j] = wall between (i,j) and (i,j+1), for j in 0..N-2
    # h_walls[i][j] = wall between (i,j) and (i+1,j), for i in 0..N-2
    v_walls = [[False] * (N - 1) for _ in range(N)]
    h_walls = [[False] * N for _ in range(N - 1)]

    # Track which vertices have adjacent walls.
    # Vertices are at corners of cells: (i,j) for i in 0..N, j in 0..N
    # A wall segment is between two adjacent vertices on the grid boundary.
    # But in this problem, walls are between cells, which correspond to edges
    # between vertex points.
    #
    # The "vertex" in the generation refers to corner points of cells.
    # There are (N+1) x (N+1) corner vertices.
    # A vertical wall segment at v_walls[i][j] goes between vertices (i,j+1)-(i+1,j+1)
    # A horizontal wall segment at h_walls[i][j] goes between vertices (i+1,j)-(i+1,j+1)

    # Track which corner vertices are adjacent to a wall
    vertex_has_wall = [[False] * (N + 1) for _ in range(N + 1)]

    # The outer boundary walls: all border vertices have walls
    for i in range(N + 1):
        vertex_has_wall[i][0] = True
        vertex_has_wall[i][N] = True
    for j in range(N + 1):
        vertex_has_wall[0][j] = True
        vertex_has_wall[N][j] = True

    W = rng.randint(0, N - 1)

    for _ in range(W):
        # Find vertices not adjacent to any wall (internal vertices only)
        # "not adjacent to any existing wall" means the vertex itself is not
        # touched by any wall segment. But boundary vertices always have walls.
        # Actually, re-reading: "Randomly choose one vertex that is not adjacent
        # to any existing wall."
        # This means vertex_has_wall[vi][vj] == False
        candidates = []
        for vi in range(1, N):  # internal vertices only
            for vj in range(1, N):
                if not vertex_has_wall[vi][vj]:
                    candidates.append((vi, vj))

        if not candidates:
            break

        vi, vj = candidates[rng.randint(0, len(candidates) - 1)]

        # Choose direction: 0=up, 1=down, 2=left, 3=right
        direction = rng.randint(0, 3)

        # Extend wall from vertex in chosen direction until hitting another wall
        if direction == 0:  # Up: decrease row
            # Wall goes upward from (vi,vj), creating horizontal wall segments
            # At vertex (vi, vj), going up means the wall extends between
            # columns vj-1 and vj at rows decreasing from vi
            # Actually, from vertex (vi,vj) going up: we add wall segments
            # between consecutive vertices (vi,vj)->(vi-1,vj)->(vi-2,vj)...
            # Each segment between (r,vj) and (r-1,vj) is a horizontal wall
            # h_walls[r-1][?] - this is a wall between cell (r-1, ?) and (r, ?)
            # A wall going up from vertex (vi,vj) means vertical edges:
            # between vertices (r, vj) and (r-1, vj)
            # This corresponds to h_walls at: wall between cell(r-1, vj-1) and cell(r, vj-1)
            # => h_walls[r-1][vj-1] if vj >= 1 -- no wait.
            #
            # Let me reconsider. The vertex (vi, vj) is at the corner.
            # Going "up" from this vertex means we extend along the vertical
            # edge from (vi, vj) towards (vi-1, vj).
            # The wall segment between vertex (r, vj) and (r-1, vj) blocks
            # movement between cell (r-1, vj-1) and cell (r-1, vj).
            # That's a vertical wall: v_walls[r-1][vj-1] (wall between (r-1,vj-1) and (r-1,vj))
            # Wait, v_walls[i][j] = wall between cell (i,j) and (i,j+1)
            # The vertical line between vertices (r, vj) and (r-1, vj) sits
            # between cell columns vj-1 and vj at row... it sits between cells
            # (r-1, vj-1) and (r-1, vj). So this is v_walls[r-1][vj-1].
            # But we need vj >= 1 and vj <= N-1 for this to be a valid internal wall.
            r = vi
            vertex_has_wall[vi][vj] = True
            while r > 0:
                r -= 1
                if vertex_has_wall[r][vj]:
                    # Hit a wall, mark this vertex too and stop
                    vertex_has_wall[r][vj] = True
                    break
                vertex_has_wall[r][vj] = True
            # Now add the actual wall segments
            for rr in range(r, vi):
                # Wall between vertex (rr, vj) and (rr+1, vj)
                # This blocks between cell (rr, vj-1) and (rr, vj)
                if 0 < vj < N:
                    v_walls[rr][vj - 1] = True

        elif direction == 1:  # Down: increase row
            r = vi
            vertex_has_wall[vi][vj] = True
            while r < N:
                r += 1
                if vertex_has_wall[r][vj]:
                    vertex_has_wall[r][vj] = True
                    break
                vertex_has_wall[r][vj] = True
            for rr in range(vi, r):
                if 0 < vj < N:
                    v_walls[rr][vj - 1] = True

        elif direction == 2:  # Left: decrease column
            c = vj
            vertex_has_wall[vi][vj] = True
            while c > 0:
                c -= 1
                if vertex_has_wall[vi][c]:
                    vertex_has_wall[vi][c] = True
                    break
                vertex_has_wall[vi][c] = True
            for cc in range(c, vj):
                # Wall between vertex (vi, cc) and (vi, cc+1)
                # This blocks between cell (vi-1, cc) and (vi, cc)
                if 0 < vi < N:
                    h_walls[vi - 1][cc] = True

        elif direction == 3:  # Right: increase column
            c = vj
            vertex_has_wall[vi][vj] = True
            while c < N:
                c += 1
                if vertex_has_wall[vi][c]:
                    vertex_has_wall[vi][c] = True
                    break
                vertex_has_wall[vi][c] = True
            for cc in range(vj, c):
                if 0 < vi < N:
                    h_walls[vi - 1][cc] = True

    # Verify connectivity (all cells must be reachable via BFS from (0,0))
    visited = [[False] * N for _ in range(N)]
    visited[0][0] = True
    bfs_q = deque([(0, 0)])
    visit_count = 1
    while bfs_q:
        ci, cj = bfs_q.popleft()
        for d, (di, dj) in [('U', (-1, 0)), ('D', (1, 0)), ('L', (0, -1)), ('R', (0, 1))]:
            ni, nj = ci + di, cj + dj
            if 0 <= ni < N and 0 <= nj < N and not visited[ni][nj]:
                # Check wall
                blocked = False
                if d == 'U' and h_walls[ci - 1][cj]:
                    blocked = True
                elif d == 'D' and h_walls[ci][cj]:
                    blocked = True
                elif d == 'L' and v_walls[ci][cj - 1]:
                    blocked = True
                elif d == 'R' and v_walls[ci][cj]:
                    blocked = True
                if not blocked:
                    visited[ni][nj] = True
                    visit_count += 1
                    bfs_q.append((ni, nj))
    assert visit_count == N * N, f"Grid not connected: {visit_count}/{N*N} cells reachable"

    # Generate destinations
    K = rng.randint(N, N * N)
    all_cells = [(i, j) for i in range(N) for j in range(N)]
    rng.shuffle(all_cells)
    targets = all_cells[:K]

    # Calculate minimum moves X
    X = 0
    for idx in range(1, K):
        d = bfs_shortest(N, v_walls, h_walls, targets[idx - 1], targets[idx])
        if d == -1:
            # Fallback: shouldn't happen with connected grid
            d = abs(targets[idx][0] - targets[idx - 1][0]) + abs(targets[idx][1] - targets[idx - 1][1])
        X += d

    T = rng.randint(max(X, 1), max(2 * X, 1))

    # Format output
    lines = []
    lines.append(f"{N} {K} {T}")

    # Vertical walls: v_walls[i][j] for each row i, columns j=0..N-2
    for i in range(N):
        row_str = ''.join('1' if v_walls[i][j] else '0' for j in range(N - 1))
        lines.append(row_str)

    # Horizontal walls: h_walls[i][j] for each row i=0..N-2, columns j=0..N-1
    for i in range(N - 1):
        row_str = ''.join('1' if h_walls[i][j] else '0' for j in range(N))
        lines.append(row_str)

    # Destinations
    for x, y in targets:
        lines.append(f"{x} {y}")

    return '\n'.join(lines) + '\n'


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: ./gen <seed>", file=sys.stderr)
        sys.exit(1)
    print(generate(int(sys.argv[1])), end='')
