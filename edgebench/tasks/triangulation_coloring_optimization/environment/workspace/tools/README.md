# Local Testing Tools (CodeChef-aligned)

## tester -- Full Scorer

```bash
./tools/bin/tester <input_file> <output_file>
```

On success: `Score = <G>` on stderr (exit 0).

The tester:

1. Validates **C, F**, colors, and flip line format
2. **Executes each flip** on the input triangulation (invalid flip → wrong answer)
3. Counts **U** on the **final** triangulation with final colors
4. Returns **G = X·C + Y·F + U²**

This matches the official CodeChef scoring model.

## Example loop

Use the provided files in `sample_data/`:

```bash
python3 solution.py < sample_data/0000.txt > output.txt
./tools/bin/tester sample_data/0000.txt output.txt
```

Or run all samples:

```bash
./eval_sample_data.sh
```

Source: `src/triangulation.py`, `src/delaunay.py`, `src/verifier.py`.
