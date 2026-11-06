# Local sample data (N=512)

Pre-built cases for local testing.

These are **not** judge cases. Judge hidden seeds start at **9,000,000**; local dev seeds below are disjoint.

| File | seed | N | pre-flip K | X | Y | P | Q |
|------|------|---|------------|---|---|---|---|
| 0000.txt | 1000001 | 512 | 16 | 10 | 160 | 256 | 1024 |
| 0001.txt | 1000002 | 512 | 16 | 40 | 40 | 256 | 1024 |
| 0002.txt | 1000003 | 512 | 256 | 80 | 20 | 256 | 1024 |

**pre-flip K** is the random edge-flip count applied during case generation (official CodeChef parameter). **P** and **Q** are the operation limits in each input file (P = N/2 = 256, Q = 1024).

```bash
./eval_sample_data.sh
python3 solution.py < sample_data/0000.txt > output.txt
./tools/bin/tester sample_data/0000.txt output.txt
```

Final scoring uses **10 hidden judge cases** (same N=512 constraints); those inputs are not included in this workspace.
