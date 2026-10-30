# Local Testing Tools

## gen -- Input Generator

```bash
./bin/gen <seed>
```

Generates N=10000 cities and M=2500 wires with varying L parameter.

## tester -- Scoring Program

```bash
./bin/tester <input_file> <output_file>
```

Computes P + Q (transmission + movement cost). Validates positive/negative wire constraints.

- **Success**: stderr `Score = <integer>`, exit code 0
- **Failure**: stderr `wrong answer: <reason>`, exit code 1

Note: The tester performs O(M^2) intersection checks and O(N*M) distance calculations, so it may take several seconds on large inputs.

## Source Code

- `src/gen.cpp` -- Generator source (C++17)
- `src/tester.cpp` -- Tester/scorer source (C++17)

## Building from source

```bash
g++ -std=c++17 -O2 -o bin/gen src/gen.cpp
g++ -std=c++17 -O2 -o bin/tester src/tester.cpp
```
