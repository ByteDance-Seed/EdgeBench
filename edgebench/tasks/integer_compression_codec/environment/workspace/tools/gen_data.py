#!/usr/bin/env python3
"""Deterministic generator for the 8 evaluation datasets.

Local small-sample mode (default): ~1.25–2.5 M elements each (~5–10 MB files).
Remote full-scale mode (--full):    50–100 M elements each (used by the remote
evaluator; the same seeds and formulas are applied, only N differs).

Seeds are fixed constants so the generator is auditable and the remote data
cannot be "memorized" by the model any differently from the public sample.
"""

from __future__ import annotations

import argparse
import os
import struct
import sys

import numpy as np

SEEDS = {
    "docids": 1001,
    "ts_sec": 1002,
    "ts_ns":  1003,
    "temp":   1004,
    "grid":   1005,
    "zipf":   1006,
    "rand":   1007,
    "sparse": 1008,
}

# (local_N, remote_N) per dataset
SIZES = {
    "docids": ( 2_500_000, 100_000_000),
    "ts_sec": ( 1_250_000,  50_000_000),
    "ts_ns":  ( 1_250_000,  50_000_000),
    "temp":   ( 1_250_000,  50_000_000),
    "grid":   ( 1_250_000,  50_000_000),
    "zipf":   ( 1_250_000,  50_000_000),
    "rand":   ( 1_250_000,  50_000_000),
    "sparse": ( 1_250_000,  50_000_000),
}


def rng(name: str) -> np.random.Generator:
    return np.random.default_rng(SEEDS[name])


def gen_docids(n: int) -> np.ndarray:
    r = rng("docids")
    # Pareto gaps (α=1.2, xm=1) accumulated and truncated to [0, 2^31).
    gaps = r.pareto(1.2, size=n) + 1.0
    cum = np.cumsum(gaps)
    # Scale so that the max stays inside [0, 2^31) — this gives realistic docid density.
    cum *= (2**31 - 1) / cum[-1]
    return np.floor(cum).astype(np.uint32)


def gen_ts_sec(n: int) -> np.ndarray:
    r = rng("ts_sec")
    base = 1577836800  # 2020-01-01T00:00:00Z
    # Poisson arrivals, ~1 event per ms → seconds granularity has heavy repeats.
    inter = r.exponential(scale=1e-3, size=n)
    t = base + np.cumsum(inter)
    return np.floor(t).astype(np.uint32)


def gen_ts_ns(n: int) -> np.ndarray:
    r = rng("ts_ns")
    # Take only low 32 bits of nanosecond timestamps (upper bits constant).
    base = 1_577_836_800_000_000_000  # ns since epoch for 2020-01-01
    inter = r.exponential(scale=1e3, size=n)  # avg 1μs = 1000 ns
    t = base + np.cumsum(inter).astype(np.int64)
    return (t & 0xFFFFFFFF).astype(np.uint32)


def gen_temp(n: int) -> np.ndarray:
    r = rng("temp")
    t = r.normal(25.0, 3.0, size=n) * 100.0  # hundredths of a degree
    return np.clip(t, 0, 10_000).astype(np.uint32)


def gen_grid(n: int) -> np.ndarray:
    r = rng("grid")
    lat = r.integers(0, 1 << 16, size=n, dtype=np.uint32)
    lon = r.integers(0, 1 << 16, size=n, dtype=np.uint32)
    # Morton interleave (simple bit spread)
    def spread(x: np.ndarray) -> np.ndarray:
        x = (x | (x << 8)) & np.uint32(0x00FF00FF)
        x = (x | (x << 4)) & np.uint32(0x0F0F0F0F)
        x = (x | (x << 2)) & np.uint32(0x33333333)
        x = (x | (x << 1)) & np.uint32(0x55555555)
        return x
    morton = spread(lat) | (spread(lon) << 1)
    # Add zigzag jitter σ=16
    jitter = r.integers(-16, 17, size=n, dtype=np.int64).astype(np.int64)
    out = (morton.astype(np.int64) + jitter).clip(0, (1 << 32) - 1)
    return out.astype(np.uint32)


def gen_zipf(n: int) -> np.ndarray:
    r = rng("zipf")
    # Zipf(s=1.1), clipped to a reasonable vocab size.
    v = r.zipf(1.1, size=n * 2)
    v = v[v < 500_000][:n]
    return v.astype(np.uint32)


def gen_rand(n: int) -> np.ndarray:
    r = rng("rand")
    return r.integers(0, 1 << 32, size=n, dtype=np.uint32)


def gen_sparse(n: int) -> np.ndarray:
    r = rng("sparse")
    hot = r.integers(0, 1 << 30, size=100, dtype=np.uint32)
    mask = r.random(n) < 0.5
    out = np.where(
        mask,
        hot[r.integers(0, 100, size=n)],
        r.integers(0, 1 << 32, size=n, dtype=np.uint32),
    )
    out.sort()
    return out.astype(np.uint32)


GEN = {
    "docids": gen_docids,
    "ts_sec": gen_ts_sec,
    "ts_ns":  gen_ts_ns,
    "temp":   gen_temp,
    "grid":   gen_grid,
    "zipf":   gen_zipf,
    "rand":   gen_rand,
    "sparse": gen_sparse,
}


def write(path: str, arr: np.ndarray) -> None:
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "wb") as f:
        f.write(arr.tobytes())
    mb = arr.nbytes / (1 << 20)
    print(f"  wrote {path}: n={len(arr)}, {mb:.1f} MB")


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--full", action="store_true",
                   help="generate remote full-scale dataset sizes")
    p.add_argument("--out-dir", default="datasets")
    p.add_argument("--only", nargs="*", default=None,
                   help="subset of dataset names to regenerate")
    p.add_argument("--inspect", default=None,
                   help="print histogram summary for a dataset and exit")
    args = p.parse_args()

    targets = args.only or list(SEEDS.keys())
    if args.inspect:
        arr = np.fromfile(os.path.join(args.out_dir, args.inspect + ".u32"),
                          dtype=np.uint32)
        print(f"{args.inspect}: n={len(arr)}, min={arr.min()}, "
              f"max={arr.max()}, mean={arr.mean():.2f}")
        diffs = np.diff(arr.astype(np.int64))
        print(f"  gaps: min={diffs.min()}, max={diffs.max()}, "
              f"median={np.median(diffs):.1f}")
        return 0

    which = 1 if args.full else 0
    print(f"mode = {'FULL (remote)' if which else 'LOCAL (small sample)'}")
    for name in targets:
        n = SIZES[name][which]
        print(f"generating {name} (N={n}) ...")
        arr = GEN[name](n)
        write(os.path.join(args.out_dir, f"{name}.u32"), arr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
