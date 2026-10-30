# Scoring Rules

Evaluation is performed on fixed datasets:
1. `encode`
2. Treat compressed output as persisted data
3. `decode`
4. Verify `decode(encode(X)) == X`

For dataset `i`, the following are recorded:
- `B_i`: Average compressed bits per integer (bits per integer, bpi)
- `T_i`: Decoding throughput (GB/s, calculated based on the original `n * 4` bytes)

Per-dataset score:

```text
S_i = min(B_i^baseline / B_i, 8.0) × min(T_i / T_i^baseline, 40.0)
```

Composite score:

```text
Score = Σ w_i × S_i / Σ w_i
```

Dataset weights:

```text
w = [2, 1.5, 1.5, 1, 1, 1, 1, 1]
```

The baseline implementation is the publicly provided Varint starter. Its composite score is defined as `1.0`.

Zero-score conditions:
- `decode(encode(X)) != X`
- Single dataset encode + decode timeout
- Output does not satisfy interface and capacity constraints

Local benchmarking tools can only provide approximate trends and should not be treated as equivalent to official evaluation scores.
