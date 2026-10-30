# Local datasets

Run `python3 tools/gen_data.py` in the `workspace/` root to (re)generate these
files. They are the **same seeds** the remote evaluator uses, only smaller.

| File             | Elements | Size   |
|------------------|----------|--------|
| `docids.u32`     | 2.5 M    | 10 MB  |
| `ts_sec.u32`     | 1.25 M   | 5 MB   |
| `ts_ns.u32`      | 1.25 M   | 5 MB   |
| `temp.u32`       | 1.25 M   | 5 MB   |
| `grid.u32`       | 1.25 M   | 5 MB   |
| `zipf.u32`       | 1.25 M   | 5 MB   |
| `rand.u32`       | 1.25 M   | 5 MB   |
| `sparse.u32`     | 1.25 M   | 5 MB   |

File format: raw little-endian `uint32` values, no header.

The remote evaluator uses the same generator with `--full`, yielding 50–100 M
elements per dataset.
