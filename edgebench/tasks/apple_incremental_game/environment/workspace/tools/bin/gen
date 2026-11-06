#!/usr/bin/env python3
"""Input generator for Apple Incremental Game (AHC058).
Usage: ./gen <seed>
Outputs test input to stdout.
"""
import sys
import random

def generate(seed):
    random.seed(seed)
    N, L, T, K = 10, 4, 500, 1

    # Generate A
    A = [1]
    for j in range(1, N):
        A.append(round(10 ** random.uniform(0, 2)))
    A.sort()

    # Generate C
    C = []
    for i in range(L):
        row = []
        for j in range(N):
            if i == 0 and j == 0:
                row.append(1)
            else:
                val = round(A[j] * (500**i) * 10 ** random.uniform(0, 2))
                row.append(min(val, 10**15))
        C.append(row)

    lines = [f"{N} {L} {T} {K}"]
    lines.append(" ".join(map(str, A)))
    for row in C:
        lines.append(" ".join(map(str, row)))
    return "\n".join(lines) + "\n"

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: ./gen <seed>", file=sys.stderr)
        sys.exit(1)
    print(generate(int(sys.argv[1])), end='')
