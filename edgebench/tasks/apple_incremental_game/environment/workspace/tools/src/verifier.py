#!/usr/bin/env python3
"""Format-only output checker for AHC058.

Official local and remote scoring use ``tools/bin/tester`` only.
This script does NOT simulate the game or compute a score.
"""
import sys
from typing import Tuple, Optional


class Verifier:
    def __init__(self, input_file: str):
        with open(input_file, "r") as f:
            parts = f.readline().split()
        self.T = int(parts[2])

    def verify(self, output_file: str) -> Tuple[bool, Optional[str]]:
        try:
            with open(output_file, "r") as f:
                lines = f.read().strip().split("\n")

            actions = [
                l.strip() for l in lines if l.strip() and not l.startswith("#")
            ]

            if len(actions) < self.T:
                return (
                    False,
                    f"Expected at least {self.T} actions, got {len(actions)}",
                )

            return True, None
        except Exception as e:
            return False, f"Error: {str(e)}"


def main():
    if len(sys.argv) < 3:
        print("Usage: python verifier.py <input> <output>", file=sys.stderr)
        sys.exit(1)
    v = Verifier(sys.argv[1])
    is_valid, msg = v.verify(sys.argv[2])
    if not is_valid:
        print(f"INVALID: {msg}")
        sys.exit(1)
    print("VALID (format only; run ./bin/tester for score)")


if __name__ == "__main__":
    main()
