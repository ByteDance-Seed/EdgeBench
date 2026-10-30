# Local Testing Tools

## Overview

This directory provides tools for local testing of your solution:
- **gen**: Input generator (seed-based, deterministic)
- **tester**: Scoring program (evaluates your solution's output)

Both are Python scripts that can be run directly.

## Scoring (important)

**Use only `./bin/tester` for scores.** It is the supported entry point and runs the simulation in `src/verifier.py`.

Do not run `python3 src/verifier.py` directly to judge your solution.

## gen -- Input Generator

```bash
./bin/gen <seed>
```

Generates a test input and prints it to stdout. The seed determines the random values; the same seed always produces the same input.

Example:
```bash
./bin/gen 0 > input.txt
./bin/gen 42 > input.txt
```

## tester -- Scoring Program

```bash
./bin/tester <input_file> <output_file>
```

Evaluates the output against the input and prints the score to stderr.

- **Success**: stderr outputs `Score = <integer>`, exit code 0
- **Failure**: stderr outputs `wrong answer: <reason>`, exit code 1

The score represents the absolute score (C + Q if all destinations visited, or a penalty otherwise). **Lower is better.**

Example:
```bash
python3 solution.py < input.txt > output.txt
./bin/tester input.txt output.txt
```

## Testing Loop

```bash
for seed in $(seq 0 9); do
    ./bin/gen $seed > input.txt
    python3 solution.py < input.txt > output.txt
    echo -n "Seed $seed: "
    ./bin/tester input.txt output.txt 2>&1 1>/dev/null
done
```

## Source Code

Source code is available in `src/` for reference:
- `src/gen.py` -- Generator source
- `src/verifier.py` -- Scoring logic (used by `bin/tester` only)
