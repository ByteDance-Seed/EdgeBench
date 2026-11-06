#!/usr/bin/env python3
"""
Verifier for WAREHOUS - Warehouse Manager
"""

import sys
from typing import Tuple, Optional

class Verifier:
    def __init__(self, input_file: str):
        self.input_file = input_file

    def verify(self, output_file: str) -> Tuple[bool, Optional[str], float]:
        try:
            with open(self.input_file, 'r') as f:
                in_lines = f.read().strip().split('\n')
            with open(output_file, 'r') as f:
                out_lines = f.read().strip().split('\n')

            li = 0
            T = int(in_lines[li]); li += 1

            if len(out_lines) != T:
                return False, f"Expected {T} output lines, got {len(out_lines)}", 0.0

            total_score = 0.0
            for tc in range(T):
                R, C = map(int, in_lines[li].split()); li += 1
                li += 1  # skip shipments
                S = len(out_lines[tc].strip())
                case_score = (S + 2) / (R + C - 1) - 2 * R * C + 20
                total_score += case_score

            avg_score = total_score / T
            return True, None, avg_score
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
