#!/usr/bin/env python3
"""Format-only output checker for AHC054.

Official local and remote scoring use ``tools/bin/tester`` only.
This script does NOT replay the game or compute turn count / score.
"""
import sys
from typing import Tuple, Optional


class Verifier:
    def __init__(self, input_file: str):
        self.input_file = input_file

    def verify(self, output_file: str) -> Tuple[bool, Optional[str]]:
        try:
            with open(output_file, "r") as f:
                content = f.read().strip()

            if not content:
                return True, None

            for line in content.split("\n"):
                line = line.strip()
                if not line:
                    continue
                if line == "-1":
                    continue
                parts = line.split()
                if len(parts) < 1:
                    continue
                m = int(parts[0])
                if m < 0:
                    return False, f"Invalid m: {m}"
                if len(parts) != 1 + 2 * m:
                    return (
                        False,
                        f"Invalid number of coordinates for m={m}",
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
