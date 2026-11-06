#!/usr/bin/env python3
"""
Verifier for VBR - Vibrating Path
"""

import sys
import math
from typing import Tuple, Optional

class Verifier:
    def __init__(self, input_file: str):
        self.input_file = input_file

    def verify(self, output_file: str) -> Tuple[bool, Optional[str], float]:
        try:
            with open(self.input_file, 'r') as f:
                data = f.read().split()
            idx = 0
            N = int(data[idx]); idx += 1
            M = int(data[idx]); idx += 1
            K = int(data[idx]); idx += 1
            costs = [int(data[idx + i]) for i in range(N)]
            idx += N

            with open(output_file, 'r') as f:
                out_lines = f.read().strip().split('\n')

            Q = int(out_lines[0])
            if Q > 0:
                hit_nodes = list(map(int, out_lines[1].split()))
                colors = list(map(int, out_lines[2].split()))
            else:
                hit_nodes = []
                colors = list(map(int, out_lines[1].split()))

            total_cost = sum(costs[node-1] for node in hit_nodes)
            return True, None, total_cost
        except Exception as e:
            return False, str(e), 0.0

def main():
    if len(sys.argv) < 3:
        print("Usage: python verifier.py <input_file> <output_file>")
        sys.exit(1)

    verifier = Verifier(sys.argv[1])
    is_valid, error_msg, score = verifier.verify(sys.argv[2])

    if not is_valid:
        print(f"INVALID: {error_msg}")
        sys.exit(1)
    else:
        print(f"Score: {score:.2f}")

if __name__ == "__main__":
    main()
