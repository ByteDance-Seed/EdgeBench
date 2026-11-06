#!/usr/bin/env python3
"""Input generator for Molecules (AHC057).
Usage: ./gen <seed>
Outputs test input to stdout.
"""
import sys
import random

def generate(seed):
    random.seed(seed)
    N = 300
    T = 1000
    M = 10
    K = 30
    L = 100000

    lines = [f"{N} {T} {M} {K} {L}"]
    for _ in range(N):
        x = random.randint(0, L - 1)
        y = random.randint(0, L - 1)
        vx = random.randint(-100, 100)
        vy = random.randint(-100, 100)
        lines.append(f"{x} {y} {vx} {vy}")
    return '\n'.join(lines) + '\n'

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: ./gen <seed>", file=sys.stderr)
        sys.exit(1)
    print(generate(int(sys.argv[1])), end='')
