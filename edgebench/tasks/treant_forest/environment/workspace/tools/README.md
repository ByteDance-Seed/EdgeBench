# Local Testing Tools

## Overview

This directory provides tools for local testing of your solution:
- **gen**: Input generator (seed-based, deterministic)
- **tester**: Scoring program (replays the interactive game with your placements)

Both are Python scripts that can be run directly.

## Scoring (important)

**Use only `./bin/tester` for scores.** It replays the full game and prints `Score = <turns>` on stderr.

`src/verifier.py` checks **output line format only** (no adventurer simulation). Do not use it to estimate your score.

## gen -- Input Generator

```bash
./bin/gen <seed>
```

Generates a test input and prints it to stdout. The output contains:
1. Grid dimensions and flower position
2. Grid layout (`.` = empty, `T` = tree)
3. Destination candidate list (for deterministic replay)

The seed determines the random values; the same seed always produces the same input.

Example:
```bash
./bin/gen 0 > input.txt
./bin/gen 42 > input.txt
```

## tester -- Scoring Program

```bash
./bin/tester <input_file> <output_file>
```

Replays the interactive game using the input (grid + dest candidates) and the output (treant placements), then computes the score.

- **Success**: stderr outputs `Score = <integer>` (number of turns), exit code 0
- **Failure**: stderr outputs `wrong answer: <reason>`, exit code 1

The score is the number of turns the adventurer takes to reach the flower. Higher is better.

Example:
```bash
python3 solution.py < input.txt > output.txt
./bin/tester input.txt output.txt
```

## Output Format

Your solution outputs one line per turn:
- `m x0 y0 x1 y1 ...` -- place m treants at the given coordinates
- `0` -- place no treants this turn
- `-1` -- stop placing treants (cutoff); remaining turns treated as m=0

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
- `src/verifier.py` -- Format check only (not for scoring)
- `src/interactive_runner.py` -- Original interactive runner (for reference)
