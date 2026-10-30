#!/usr/bin/env python3
"""Input generator for Vibrating Path (CodeChef VBR).
Usage: ./gen <seed>
Outputs test input to stdout.
"""
import sys
import random

def generate(seed):
    random.seed(seed)
    # 8 combinations: N in {1000, 10000}, K in {1,2,3,4}
    combos = [(1000, 1), (1000, 2), (1000, 3), (1000, 4),
              (10000, 1), (10000, 2), (10000, 3), (10000, 4)]
    combo = combos[seed % len(combos)]
    N, K = combo
    M = 100000

    lines = [f"{N} {M} {K}"]

    # Costs
    costs = [random.randint(1, 512) for _ in range(N)]
    lines.append(' '.join(map(str, costs)))

    # Generate M distinct edges
    edge_set = set()
    while len(edge_set) < M:
        u = random.randint(1, N)
        v = random.randint(1, N)
        if u != v:
            e = (min(u, v), max(u, v))
            edge_set.add(e)

    edges = list(edge_set)
    # Random permutation for weights
    weights = list(range(1, M + 1))
    random.shuffle(weights)

    for i, (u, v) in enumerate(edges):
        lines.append(f"{u} {v} {weights[i]}")

    return '\n'.join(lines) + '\n'

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: ./gen <seed>", file=sys.stderr)
        sys.exit(1)
    print(generate(int(sys.argv[1])), end='')
