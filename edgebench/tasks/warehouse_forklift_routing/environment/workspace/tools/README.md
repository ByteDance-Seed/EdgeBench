# Local Testing Tools

## gen -- Input Generator

```bash
./bin/gen <seed>
```

Generates T=5 test cases with random R, C, and arrival order.

## tester -- Scoring Program

```bash
./bin/tester <input_file> <output_file>
```

Validates the forklift commands and computes the score.

- **Success**: stderr `Score = <number>`, exit code 0
- **Failure**: stderr `wrong answer: <reason>`, exit code 1

## Source Code

- `src/gen.py` -- Generator source
- `src/verifier.py` -- Verifier source
