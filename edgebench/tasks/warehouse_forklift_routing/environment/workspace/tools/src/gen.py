#!/usr/bin/env python3
"""Input generator for Warehouse Manager (CodeChef WAREHOUS).
Usage: ./gen <seed>
Outputs test input to stdout.
"""
import sys
import random

def generate(seed):
    random.seed(seed)
    T = 5
    lines = [str(T)]
    for _ in range(T):
        R = random.randint(6, 20)
        C = random.randint(6, 20)
        lines.append(f"{R} {C}")
        n = R * C - 1
        shipments = list(range(1, n + 1))
        while True:
            random.shuffle(shipments)
            if shipments[-1] != 1:
                break
        lines.append(' '.join(map(str, shipments)))
    return '\n'.join(lines) + '\n'

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: ./gen <seed>", file=sys.stderr)
        sys.exit(1)
    print(generate(int(sys.argv[1])), end='')
