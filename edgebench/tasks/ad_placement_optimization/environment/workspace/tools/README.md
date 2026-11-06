# Local Tools

This directory provides an input generator and scoring program for local testing.
The example commands below assume you run them from the workspace root directory.

## Pre-compiled Binaries

`bin/` contains pre-compiled Linux x86-64 statically-linked binaries, ready to use:

- `bin/gen` — Input generator
- `bin/tester` — Scoring program (judge)

## Rust Source Code

`src/` contains the corresponding Rust source code. To recompile:

```bash
cargo build --release --bin gen --bin tester
```

Compiled binaries will be in `target/release/`. The current workspace does not guarantee that `cargo` or `rustc` are installed; you should normally use the pre-compiled binaries in `bin/`.

---

## gen — Input Generator

Generates test case inputs from a seed file.

**Usage**:
```bash
./tools/bin/gen <seeds_file> -d <output_dir>
```

- `seeds_file`: Path to a text file with one integer seed per line; blank lines are ignored
- `output_dir`: Output directory for generated cases; `gen` will create it if it doesn't exist
- Output files are named `0000.txt`, `0001.txt`, ... in the order of seeds in the file

**Examples**:
```bash
printf '0\n' > /tmp/seeds.txt
rm -rf /tmp/ad_cases && mkdir -p /tmp/ad_cases
./tools/bin/gen /tmp/seeds.txt -d /tmp/ad_cases
cp /tmp/ad_cases/0000.txt input.txt

seq 0 9 > /tmp/seeds.txt
rm -rf /tmp/ad_cases && mkdir -p /tmp/ad_cases
./tools/bin/gen /tmp/seeds.txt -d /tmp/ad_cases
```

You can use any seed values to generate unlimited test data locally for debugging.

---

## tester — Scoring Program

Reads an input file and a program output file, then computes the score.

**Usage**:
```bash
./bin/tester <input_file> <output_file>
```

- `input_file`: Path to the test case input file
- `output_file`: Path to the program output file
- Score is written to stderr in the format `Score = <integer>`
- If the output is invalid, stderr outputs `wrong answer: <reason>` and exits with code 1

**Examples**:
```bash
# Generate input, run solution, score — end to end:
printf '0\n' > /tmp/seeds.txt
rm -rf /tmp/ad_cases && mkdir -p /tmp/ad_cases
./tools/bin/gen /tmp/seeds.txt -d /tmp/ad_cases
cp /tmp/ad_cases/0000.txt input.txt
./my_solution < input.txt > output.txt
./tools/bin/tester input.txt output.txt
# stderr output: Score = 123456
```

**Piped local testing loop**:
```bash
seq 0 9 > /tmp/seeds.txt
rm -rf /tmp/ad_cases && mkdir -p /tmp/ad_cases
./tools/bin/gen /tmp/seeds.txt -d /tmp/ad_cases
for input in /tmp/ad_cases/*.txt; do
    ./my_solution < "$input" > /tmp/out.txt
    echo -n "$(basename "$input") "
    ./tools/bin/tester "$input" /tmp/out.txt 2>&1
done
```
