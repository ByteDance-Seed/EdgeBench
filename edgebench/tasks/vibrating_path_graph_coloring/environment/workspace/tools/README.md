# Local Testing Tools

## Overview

- **gen**: Input generator (seed-based, deterministic)
- **tester**: Scoring program (evaluates your solution's output)

## gen -- Input Generator

```bash
./bin/gen <seed>
```

Generates a test input. Different seeds produce different (N, K) combinations cycling through 8 configurations.

## tester -- Scoring Program

```bash
./bin/tester <input_file> <output_file>
```

- **Success**: stderr outputs `Score = <integer>`, exit code 0
- **Failure**: stderr outputs `wrong answer: <reason>`, exit code 1

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

- `src/gen.py` -- Generator source
- `src/verifier.py` -- Tester source
