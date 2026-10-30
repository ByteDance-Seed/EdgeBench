#!/usr/bin/env python3
"""
run_dev_bench.py — Agent development benchmarking tool.

Benchmarks the candidate shared library against the public baseline on
a set of visible workloads.  Reports per-workload speedup and geometric
mean across all workloads.

Usage:
    python3 /app/run_dev_bench.py [--candidate /path/to/libswscale_candidate.so]
"""

from __future__ import annotations

import argparse
import json
import math
import os
import sys
import time
from pathlib import Path

sys.path.insert(0, "/app")
from pixel_formats import (
    PIXFMT_DESCS,
    ALGO_NEAREST,
    ALGO_BILINEAR,
    PIXFMT_YUV420P,
    PIXFMT_RGB24,
    PIXFMT_BGRA,
    PIXFMT_NV12,
    PIXFMT_GRAY8,
    load_swscale_library,
    allocate_image,
    fill_image_from_bytes,
)

BASELINE_LIB = "/app/libswscale_public_baseline.so"
WARMUP_ITERS = 5
BENCH_ITERS = 50


def find_candidate_lib() -> str:
    candidates = [
        "/app/swscale-impl/zig-out/lib/libswscale_candidate.so",
        "/app/swscale-impl/target/release/libswscale_candidate.so",
        "/app/swscale-impl/libswscale_candidate.so",
    ]
    for p in candidates:
        if os.path.exists(p):
            return p
    import glob

    hits = glob.glob("/app/swscale-impl/**/libswscale_candidate*", recursive=True)
    return hits[0] if hits else ""


def generate_noise_planes(fmt: int, w: int, h: int, seed: int = 99) -> list[bytes]:
    """Generate deterministic noise as plane bytes."""
    import random

    rng = random.Random(seed)
    desc = PIXFMT_DESCS[fmt]
    planes = []
    for i in range(desc.num_planes):
        pw = desc.plane_width(i, w) * desc.planes[i].bpp
        ph = desc.plane_height(i, h)
        planes.append(bytes(rng.getrandbits(8) for _ in range(pw * ph)))
    return planes


BENCH_WORKLOADS = [
    # Format-only conversions (large images for meaningful timing)
    {
        "src_fmt": PIXFMT_YUV420P,
        "dst_fmt": PIXFMT_RGB24,
        "src_w": 1920,
        "src_h": 1080,
        "dst_w": 1920,
        "dst_h": 1080,
        "algo": ALGO_BILINEAR,
        "label": "yuv420p→rgb24 1080p",
    },
    {
        "src_fmt": PIXFMT_RGB24,
        "dst_fmt": PIXFMT_YUV420P,
        "src_w": 1920,
        "src_h": 1080,
        "dst_w": 1920,
        "dst_h": 1080,
        "algo": ALGO_BILINEAR,
        "label": "rgb24→yuv420p 1080p",
    },
    {
        "src_fmt": PIXFMT_RGB24,
        "dst_fmt": PIXFMT_BGRA,
        "src_w": 1920,
        "src_h": 1080,
        "dst_w": 1920,
        "dst_h": 1080,
        "algo": ALGO_BILINEAR,
        "label": "rgb24→bgra 1080p",
    },
    {
        "src_fmt": PIXFMT_RGB24,
        "dst_fmt": PIXFMT_NV12,
        "src_w": 1920,
        "src_h": 1080,
        "dst_w": 1920,
        "dst_h": 1080,
        "algo": ALGO_BILINEAR,
        "label": "rgb24→nv12 1080p",
    },
    {
        "src_fmt": PIXFMT_RGB24,
        "dst_fmt": PIXFMT_GRAY8,
        "src_w": 1920,
        "src_h": 1080,
        "dst_w": 1920,
        "dst_h": 1080,
        "algo": ALGO_BILINEAR,
        "label": "rgb24→gray8 1080p",
    },
    # Scaling workloads
    {
        "src_fmt": PIXFMT_YUV420P,
        "dst_fmt": PIXFMT_RGB24,
        "src_w": 1920,
        "src_h": 1080,
        "dst_w": 640,
        "dst_h": 360,
        "algo": ALGO_BILINEAR,
        "label": "yuv420p→rgb24 1080p→360p bilinear",
    },
    {
        "src_fmt": PIXFMT_RGB24,
        "dst_fmt": PIXFMT_RGB24,
        "src_w": 1920,
        "src_h": 1080,
        "dst_w": 3840,
        "dst_h": 2160,
        "algo": ALGO_BILINEAR,
        "label": "rgb24 1080p→4K bilinear upscale",
    },
    {
        "src_fmt": PIXFMT_RGB24,
        "dst_fmt": PIXFMT_YUV420P,
        "src_w": 640,
        "src_h": 480,
        "dst_w": 320,
        "dst_h": 240,
        "algo": ALGO_NEAREST,
        "label": "rgb24→yuv420p 640→320 nearest",
    },
]


def bench_workload(lib, workload: dict) -> dict:
    """Benchmark a single workload, returning median time in seconds."""
    src_fmt = workload["src_fmt"]
    dst_fmt = workload["dst_fmt"]
    src_w, src_h = workload["src_w"], workload["src_h"]
    dst_w, dst_h = workload["dst_w"], workload["dst_h"]
    algo = workload["algo"]

    # Generate random source data
    src_planes = generate_noise_planes(src_fmt, src_w, src_h)
    src_data, src_stride, src_bufs = allocate_image(src_fmt, src_w, src_h)
    fill_image_from_bytes(src_fmt, src_w, src_h, src_data, src_stride, src_planes)

    dst_data, dst_stride, dst_bufs = allocate_image(dst_fmt, dst_w, dst_h)

    ctx = lib.swscale_create(src_w, src_h, src_fmt, dst_w, dst_h, dst_fmt, algo)
    if not ctx:
        return {"error": "swscale_create returned NULL"}

    # Warmup
    for _ in range(WARMUP_ITERS):
        lib.swscale_process(ctx, src_data, src_stride, dst_data, dst_stride)

    # Timed iterations
    times = []
    for _ in range(BENCH_ITERS):
        t0 = time.perf_counter()
        lib.swscale_process(ctx, src_data, src_stride, dst_data, dst_stride)
        t1 = time.perf_counter()
        times.append(t1 - t0)

    lib.swscale_destroy(ctx)

    times.sort()
    median = times[len(times) // 2]
    return {"median_s": median, "min_s": times[0], "max_s": times[-1]}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--candidate", default="")
    args = parser.parse_args()

    candidate_path = args.candidate or find_candidate_lib()
    if not candidate_path or not os.path.exists(candidate_path):
        print("ERROR: Could not find libswscale_candidate.so")
        sys.exit(1)

    if not os.path.exists(BASELINE_LIB):
        print(f"ERROR: Baseline library not found at {BASELINE_LIB}")
        sys.exit(1)

    print(f"Candidate: {candidate_path}")
    print(f"Baseline:  {BASELINE_LIB}")
    print(f"Warmup: {WARMUP_ITERS}, Bench: {BENCH_ITERS} iterations\n")

    candidate = load_swscale_library(candidate_path)
    baseline = load_swscale_library(BASELINE_LIB)

    results = []
    speedups = []

    for wl in BENCH_WORKLOADS:
        label = wl["label"]

        try:
            base_result = bench_workload(baseline, wl)
            cand_result = bench_workload(candidate, wl)
        except Exception as e:
            print(f"  [ERROR] {label}: {e}")
            results.append({"label": label, "error": str(e)})
            continue

        if "error" in base_result or "error" in cand_result:
            err = base_result.get("error") or cand_result.get("error")
            print(f"  [ERROR] {label}: {err}")
            results.append({"label": label, "error": err})
            continue

        speedup = base_result["median_s"] / max(cand_result["median_s"], 1e-15)
        speedups.append(speedup)

        base_ms = base_result["median_s"] * 1000
        cand_ms = cand_result["median_s"] * 1000
        print(f"  {label}")
        print(
            f"    baseline: {base_ms:.3f} ms  candidate: {cand_ms:.3f} ms  speedup: {speedup:.3f}x"
        )

        results.append(
            {
                "label": label,
                "baseline_median_ms": round(base_ms, 4),
                "candidate_median_ms": round(cand_ms, 4),
                "speedup": round(speedup, 4),
            }
        )

    # Geometric mean speedup
    if speedups:
        geo_mean = math.exp(sum(math.log(s) for s in speedups) / len(speedups))
    else:
        geo_mean = 0.0

    print(f"\nGeometric mean speedup: {geo_mean:.4f}x")
    print(f"({len(speedups)} workloads measured)")

    output = {
        "geometric_mean_speedup": round(geo_mean, 6),
        "workloads_measured": len(speedups),
        "results": results,
    }

    results_path = Path("/app/results/dev_benchmark.json")
    results_path.parent.mkdir(parents=True, exist_ok=True)
    with open(results_path, "w") as f:
        json.dump(output, f, indent=2)


if __name__ == "__main__":
    main()
