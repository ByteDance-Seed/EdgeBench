#!/usr/bin/env python3
"""
Correctness-gated verifier for the FFmpeg libswscale re-implementation task.

The reported score is the geometric-mean paired speedup versus the FFmpeg
C scalar baseline on hidden workloads.  Correctness is checked via per-plane
PSNR thresholds.  Any correctness failure or anti-cheat violation → score 0.
"""

from __future__ import annotations

import argparse
import json
import math
import random
import statistics
import sys
import time
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, "/app")
from pixel_formats import (  # noqa: E402
    PIXFMT_DESCS,
    PIXFMT_NAMES,
    ALGO_NEAREST,
    ALGO_BILINEAR,
    ALGO_BICUBIC,
    load_swscale_library,
    allocate_image,
    image_to_bytes,
    fill_image_from_bytes,
)

# ── Thresholds ───────────────────────────────────────────────────────────────

PSNR_THRESHOLD_CONVERT = 60.0  # same-size format conversion
PSNR_THRESHOLD_SCALE = 40.0  # with scaling

WARMUP_ITERS = 10
BENCH_ITERS = 100


# ── Core helpers ─────────────────────────────────────────────────────────────


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--candidate", default="")
    parser.add_argument("--baseline", default="/verifier-data/libswscale_baseline.so")
    parser.add_argument("--output-dir", required=True)
    parser.add_argument("--total-time-ms", type=int, default=0)
    parser.add_argument("--oracle", action="store_true")
    parser.add_argument("--fail", type=str, default=None)
    return parser.parse_args()


def emit_reward(
    output_dir: str,
    score: float,
    reason: str,
    total_time_ms: int,
    subscores: list[dict] | None = None,
    additional_data: dict | None = None,
) -> None:
    payload = {
        "score": score,
        "reward": score,
        "subscores": subscores or [],
        "additional_data": {
            **(additional_data or {}),
            "reason": reason,
            "total_time_ms": total_time_ms,
        },
    }
    out_dir = Path(output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    with open(out_dir / "reward.json", "w") as f:
        json.dump(payload, f, indent=2)
    with open(out_dir / "reward.txt", "w") as f:
        f.write(f"{score}\n")
    print(json.dumps(payload, indent=2))


def compute_psnr(data_a: bytes, data_b: bytes) -> float:
    """PSNR between two equal-length byte sequences."""
    if len(data_a) != len(data_b):
        return 0.0
    if data_a == data_b:
        return float("inf")
    try:
        import numpy as np

        a = np.frombuffer(data_a, dtype=np.uint8).astype(np.float64)
        b = np.frombuffer(data_b, dtype=np.uint8).astype(np.float64)
        mse = float(np.mean((a - b) ** 2))
    except ImportError:
        n = len(data_a)
        mse = sum((a - b) ** 2 for a, b in zip(data_a, data_b)) / n
    if mse == 0:
        return float("inf")
    return 10.0 * math.log10(255.0 * 255.0 / mse)


def generate_noise_planes(fmt: int, w: int, h: int, rng: random.Random) -> list[bytes]:
    """Generate random pixel data for a given format."""
    desc = PIXFMT_DESCS[fmt]
    planes = []
    for i in range(desc.num_planes):
        pw = desc.plane_width(i, w) * desc.planes[i].bpp
        ph = desc.plane_height(i, h)
        size = pw * ph
        planes.append(rng.randbytes(size))
    return planes


# ── Hidden workload generation ───────────────────────────────────────────────


def sample_correctness_workloads(rng: random.Random) -> list[dict]:
    """Generate hidden correctness workloads — different from public set."""
    from pixel_formats import (
        PIXFMT_YUV420P,
        PIXFMT_YUV422P,
        PIXFMT_YUV444P,
        PIXFMT_NV12,
        PIXFMT_NV21,
        PIXFMT_RGB24,
        PIXFMT_BGR24,
        PIXFMT_RGBA,
        PIXFMT_BGRA,
        PIXFMT_GRAY8,
    )

    workloads = []

    # Format-only conversions (same size)
    convert_pairs = [
        (PIXFMT_YUV420P, PIXFMT_RGB24),
        (PIXFMT_YUV420P, PIXFMT_BGRA),
        (PIXFMT_RGB24, PIXFMT_YUV420P),
        (PIXFMT_RGB24, PIXFMT_BGR24),
        (PIXFMT_RGB24, PIXFMT_RGBA),
        (PIXFMT_RGB24, PIXFMT_GRAY8),
        (PIXFMT_RGBA, PIXFMT_YUV420P),
        (PIXFMT_BGRA, PIXFMT_RGB24),
        (PIXFMT_YUV422P, PIXFMT_RGB24),
        (PIXFMT_YUV444P, PIXFMT_RGB24),
        (PIXFMT_NV12, PIXFMT_RGB24),
        (PIXFMT_NV21, PIXFMT_RGB24),
        (PIXFMT_RGB24, PIXFMT_NV12),
        (PIXFMT_RGB24, PIXFMT_NV21),
        (PIXFMT_GRAY8, PIXFMT_RGB24),
        (PIXFMT_YUV420P, PIXFMT_NV12),
        (PIXFMT_NV12, PIXFMT_YUV420P),
        (PIXFMT_RGBA, PIXFMT_BGRA),
        # Coverage gaps identified in review:
        (PIXFMT_BGR24, PIXFMT_RGB24),  # BGR24 as source
        (PIXFMT_BGR24, PIXFMT_YUV420P),  # BGR24 as source to YUV
        (PIXFMT_YUV444P, PIXFMT_YUV420P),  # YUV-to-YUV (chroma resampling)
        (PIXFMT_YUV420P, PIXFMT_GRAY8),  # YUV-to-GRAY8 (luma extraction)
        (PIXFMT_RGB24, PIXFMT_YUV422P),  # YUV422P as destination
    ]

    # Use hidden sizes (different from public 640x480, 1920x1080, 320x240)
    hidden_sizes = [
        (800, 600),
        (1280, 720),
        (720, 576),
        (352, 288),
    ]

    for src_fmt, dst_fmt in convert_pairs:
        w, h = hidden_sizes[rng.randrange(len(hidden_sizes))]
        # YUV formats need even dimensions
        if src_fmt in (
            PIXFMT_YUV420P,
            PIXFMT_YUV422P,
            PIXFMT_NV12,
            PIXFMT_NV21,
        ) or dst_fmt in (PIXFMT_YUV420P, PIXFMT_YUV422P, PIXFMT_NV12, PIXFMT_NV21):
            w = w & ~1
            h = h & ~1
        workloads.append(
            {
                "src_fmt": src_fmt,
                "dst_fmt": dst_fmt,
                "src_w": w,
                "src_h": h,
                "dst_w": w,
                "dst_h": h,
                "algo": ALGO_BILINEAR,
                "seed": rng.randrange(10**6, 10**9),
                "label": f"{PIXFMT_NAMES[src_fmt]}→{PIXFMT_NAMES[dst_fmt]} {w}x{h}",
            }
        )

    # Scaling workloads
    scale_configs = [
        (PIXFMT_RGB24, PIXFMT_RGB24, 1280, 720, 640, 360, ALGO_BILINEAR),
        (PIXFMT_RGB24, PIXFMT_RGB24, 640, 480, 1280, 960, ALGO_BILINEAR),
        (PIXFMT_YUV420P, PIXFMT_RGB24, 1280, 720, 640, 360, ALGO_BILINEAR),
        (PIXFMT_RGB24, PIXFMT_YUV420P, 800, 600, 400, 300, ALGO_BILINEAR),
        (PIXFMT_RGB24, PIXFMT_RGB24, 720, 576, 360, 288, ALGO_NEAREST),
        (PIXFMT_RGB24, PIXFMT_RGB24, 352, 288, 704, 576, ALGO_BICUBIC),
        (PIXFMT_RGBA, PIXFMT_RGBA, 1280, 720, 960, 540, ALGO_BILINEAR),
    ]

    for src_fmt, dst_fmt, sw, sh, dw, dh, algo in scale_configs:
        workloads.append(
            {
                "src_fmt": src_fmt,
                "dst_fmt": dst_fmt,
                "src_w": sw,
                "src_h": sh,
                "dst_w": dw,
                "dst_h": dh,
                "algo": algo,
                "seed": rng.randrange(10**6, 10**9),
                "label": f"{PIXFMT_NAMES[src_fmt]}→{PIXFMT_NAMES[dst_fmt]} {sw}x{sh}→{dw}x{dh} {['nearest', 'bilinear', 'bicubic'][algo]}",
            }
        )

    return workloads


def sample_benchmark_workloads(rng: random.Random) -> list[dict]:
    """Generate hidden benchmark workloads — focus on large images for timing."""
    from pixel_formats import (
        PIXFMT_YUV420P,
        PIXFMT_RGB24,
        PIXFMT_BGRA,
        PIXFMT_NV12,
        PIXFMT_RGBA,
    )

    workloads = [
        # Large format conversions
        {
            "src_fmt": PIXFMT_YUV420P,
            "dst_fmt": PIXFMT_RGB24,
            "src_w": 1920,
            "src_h": 1080,
            "dst_w": 1920,
            "dst_h": 1080,
            "algo": ALGO_BILINEAR,
            "seed": rng.randrange(10**6, 10**9),
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
            "seed": rng.randrange(10**6, 10**9),
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
            "seed": rng.randrange(10**6, 10**9),
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
            "seed": rng.randrange(10**6, 10**9),
            "label": "rgb24→nv12 1080p",
        },
        {
            "src_fmt": PIXFMT_RGBA,
            "dst_fmt": PIXFMT_RGB24,
            "src_w": 3840,
            "src_h": 2160,
            "dst_w": 3840,
            "dst_h": 2160,
            "algo": ALGO_BILINEAR,
            "seed": rng.randrange(10**6, 10**9),
            "label": "rgba→rgb24 4K",
        },
        # Scaling — bilinear
        {
            "src_fmt": PIXFMT_YUV420P,
            "dst_fmt": PIXFMT_RGB24,
            "src_w": 3840,
            "src_h": 2160,
            "dst_w": 1920,
            "dst_h": 1080,
            "algo": ALGO_BILINEAR,
            "seed": rng.randrange(10**6, 10**9),
            "label": "yuv420p→rgb24 4K→1080p bilinear",
        },
        {
            "src_fmt": PIXFMT_RGB24,
            "dst_fmt": PIXFMT_RGB24,
            "src_w": 1920,
            "src_h": 1080,
            "dst_w": 3840,
            "dst_h": 2160,
            "algo": ALGO_BILINEAR,
            "seed": rng.randrange(10**6, 10**9),
            "label": "rgb24 1080p→4K bilinear upscale",
        },
        {
            "src_fmt": PIXFMT_RGB24,
            "dst_fmt": PIXFMT_YUV420P,
            "src_w": 1920,
            "src_h": 1080,
            "dst_w": 640,
            "dst_h": 360,
            "algo": ALGO_BILINEAR,
            "seed": rng.randrange(10**6, 10**9),
            "label": "rgb24→yuv420p 1080p→360p bilinear",
        },
        # Scaling — nearest and bicubic (ensure all algorithms are benchmarked)
        {
            "src_fmt": PIXFMT_RGB24,
            "dst_fmt": PIXFMT_RGB24,
            "src_w": 1920,
            "src_h": 1080,
            "dst_w": 640,
            "dst_h": 360,
            "algo": ALGO_NEAREST,
            "seed": rng.randrange(10**6, 10**9),
            "label": "rgb24 1080p→360p nearest",
        },
        {
            "src_fmt": PIXFMT_RGB24,
            "dst_fmt": PIXFMT_RGB24,
            "src_w": 1280,
            "src_h": 720,
            "dst_w": 1920,
            "dst_h": 1080,
            "algo": ALGO_BICUBIC,
            "seed": rng.randrange(10**6, 10**9),
            "label": "rgb24 720p→1080p bicubic upscale",
        },
    ]
    return workloads


# ── Correctness checking ─────────────────────────────────────────────────────


def check_correctness(
    candidate_lib, baseline_lib, workloads: list[dict]
) -> tuple[bool, list[dict]]:
    """Run correctness checks on all workloads. Returns (all_ok, results)."""
    results = []
    all_ok = True

    for wl in workloads:
        src_fmt = wl["src_fmt"]
        dst_fmt = wl["dst_fmt"]
        src_w, src_h = wl["src_w"], wl["src_h"]
        dst_w, dst_h = wl["dst_w"], wl["dst_h"]
        algo = wl["algo"]
        seed = wl["seed"]
        label = wl["label"]

        rng = random.Random(seed)
        src_planes = generate_noise_planes(src_fmt, src_w, src_h, rng)

        # Run baseline
        src_data_b, src_stride_b, src_bufs_b = allocate_image(src_fmt, src_w, src_h)
        dst_data_b, dst_stride_b, dst_bufs_b = allocate_image(dst_fmt, dst_w, dst_h)
        fill_image_from_bytes(
            src_fmt, src_w, src_h, src_data_b, src_stride_b, src_planes
        )

        ctx_b = baseline_lib.swscale_create(
            src_w, src_h, src_fmt, dst_w, dst_h, dst_fmt, algo
        )
        if not ctx_b:
            results.append(
                {"label": label, "status": "error", "reason": "baseline create failed"}
            )
            all_ok = False
            continue
        ret_b = baseline_lib.swscale_process(
            ctx_b, src_data_b, src_stride_b, dst_data_b, dst_stride_b
        )
        baseline_lib.swscale_destroy(ctx_b)
        if ret_b != 0:
            results.append(
                {
                    "label": label,
                    "status": "error",
                    "reason": f"baseline process returned {ret_b}",
                }
            )
            all_ok = False
            continue

        baseline_planes = image_to_bytes(
            dst_fmt, dst_w, dst_h, dst_data_b, dst_stride_b
        )

        # Run candidate
        src_data_c, src_stride_c, src_bufs_c = allocate_image(src_fmt, src_w, src_h)
        dst_data_c, dst_stride_c, dst_bufs_c = allocate_image(dst_fmt, dst_w, dst_h)
        fill_image_from_bytes(
            src_fmt, src_w, src_h, src_data_c, src_stride_c, src_planes
        )

        try:
            ctx_c = candidate_lib.swscale_create(
                src_w, src_h, src_fmt, dst_w, dst_h, dst_fmt, algo
            )
            if not ctx_c:
                results.append(
                    {
                        "label": label,
                        "status": "fail",
                        "reason": "candidate create returned NULL",
                    }
                )
                all_ok = False
                continue
            ret_c = candidate_lib.swscale_process(
                ctx_c, src_data_c, src_stride_c, dst_data_c, dst_stride_c
            )
            candidate_lib.swscale_destroy(ctx_c)
        except Exception as e:
            results.append(
                {"label": label, "status": "fail", "reason": f"candidate crashed: {e}"}
            )
            all_ok = False
            continue

        if ret_c != 0:
            results.append(
                {
                    "label": label,
                    "status": "fail",
                    "reason": f"candidate process returned {ret_c}",
                }
            )
            all_ok = False
            continue

        candidate_planes = image_to_bytes(
            dst_fmt, dst_w, dst_h, dst_data_c, dst_stride_c
        )

        # Compare
        is_scaling = (src_w != dst_w) or (src_h != dst_h)
        threshold = PSNR_THRESHOLD_SCALE if is_scaling else PSNR_THRESHOLD_CONVERT

        desc = PIXFMT_DESCS[dst_fmt]
        plane_psnrs = []
        ok = True

        for i in range(desc.num_planes):
            if i < len(baseline_planes) and i < len(candidate_planes):
                psnr = compute_psnr(baseline_planes[i], candidate_planes[i])
                plane_psnrs.append(psnr)
                if psnr < threshold:
                    ok = False
            else:
                plane_psnrs.append(0.0)
                ok = False

        if not ok:
            all_ok = False

        results.append(
            {
                "label": label,
                "status": "pass" if ok else "fail",
                "min_psnr": round(min(plane_psnrs) if plane_psnrs else 0.0, 2),
                "plane_psnrs": [round(p, 2) for p in plane_psnrs],
                "threshold": threshold,
            }
        )

    return all_ok, results


# ── Performance benchmarking ─────────────────────────────────────────────────


def benchmark_workloads(
    candidate_lib, baseline_lib, workloads: list[dict]
) -> tuple[list[float], list[dict]]:
    """Benchmark candidate vs baseline. Returns (speedup_list, results)."""
    speedups = []
    results = []

    for wl in workloads:
        src_fmt = wl["src_fmt"]
        dst_fmt = wl["dst_fmt"]
        src_w, src_h = wl["src_w"], wl["src_h"]
        dst_w, dst_h = wl["dst_w"], wl["dst_h"]
        algo = wl["algo"]
        seed = wl["seed"]
        label = wl["label"]

        rng = random.Random(seed)
        src_planes = generate_noise_planes(src_fmt, src_w, src_h, rng)

        def bench_lib(lib, lib_name):
            src_data, src_stride, src_bufs = allocate_image(src_fmt, src_w, src_h)
            dst_data, dst_stride, dst_bufs = allocate_image(dst_fmt, dst_w, dst_h)
            fill_image_from_bytes(
                src_fmt, src_w, src_h, src_data, src_stride, src_planes
            )

            ctx = lib.swscale_create(src_w, src_h, src_fmt, dst_w, dst_h, dst_fmt, algo)
            if not ctx:
                return None

            # Warmup
            for _ in range(WARMUP_ITERS):
                lib.swscale_process(ctx, src_data, src_stride, dst_data, dst_stride)

            # Bench
            times = []
            for _ in range(BENCH_ITERS):
                t0 = time.perf_counter()
                lib.swscale_process(ctx, src_data, src_stride, dst_data, dst_stride)
                t1 = time.perf_counter()
                times.append(t1 - t0)

            lib.swscale_destroy(ctx)

            times.sort()
            return statistics.median(times)

        try:
            base_time = bench_lib(baseline_lib, "baseline")
            cand_time = bench_lib(candidate_lib, "candidate")
        except Exception as e:
            # Crashed workloads count as zero speedup (not excluded from mean)
            results.append({"label": label, "error": str(e), "speedup": 0.0})
            speedups.append(0.0)
            continue

        if base_time is None or cand_time is None:
            results.append({"label": label, "error": "create returned NULL", "speedup": 0.0})
            speedups.append(0.0)
            continue

        speedup = base_time / max(cand_time, 1e-15)
        speedups.append(speedup)

        results.append(
            {
                "label": label,
                "baseline_ms": round(base_time * 1000, 4),
                "candidate_ms": round(cand_time * 1000, 4),
                "speedup": round(speedup, 4),
            }
        )

    return speedups, results


# ── Main ─────────────────────────────────────────────────────────────────────


def main():
    args = parse_args()

    # Quick-fail mode (called from test.sh on integrity failures)
    if args.fail:
        emit_reward(args.output_dir, 0.0, f"HARD FAIL: {args.fail}", args.total_time_ms)
        return 0

    # Load libraries
    try:
        candidate_lib = load_swscale_library(args.candidate)
    except Exception as e:
        emit_reward(
            args.output_dir, 0.0, f"Failed to load candidate: {e}", args.total_time_ms
        )
        return 0

    try:
        baseline_lib = load_swscale_library(args.baseline)
    except Exception as e:
        emit_reward(
            args.output_dir, 0.0, f"Failed to load baseline: {e}", args.total_time_ms
        )
        return 0

    # Seed RNG deterministically
    rng = random.Random(0xDEADBEEF_CAFEBABE)

    # Top-level try/except: any unhandled crash still emits reward=0
    try:
        return _run_scoring(args, candidate_lib, baseline_lib, rng)
    except Exception as e:
        import traceback

        traceback.print_exc()
        emit_reward(args.output_dir, 0.0, f"Verifier crashed: {e}", args.total_time_ms)
        return 0


def _run_scoring(args, candidate_lib, baseline_lib, rng):
    # ── Correctness ──────────────────────────────────────────────────────
    print("=== Correctness checks ===")
    correctness_workloads = sample_correctness_workloads(rng)
    correctness_ok, correctness_results = check_correctness(
        candidate_lib, baseline_lib, correctness_workloads
    )

    passed = sum(1 for r in correctness_results if r.get("status") == "pass")
    total = len(correctness_results)
    print(f"Correctness: {passed}/{total} workloads passed")

    for r in correctness_results:
        status = r.get("status", "?")
        icon = "PASS" if status == "pass" else "FAIL"
        psnr = r.get("min_psnr", "N/A")
        reason = r.get("reason", "")
        extra = f"  PSNR={psnr}" if psnr != "N/A" else f"  {reason}"
        print(f"  [{icon}] {r['label']}{extra}")

    if not correctness_ok:
        emit_reward(
            args.output_dir,
            0.0,
            f"Correctness failed: {passed}/{total} workloads passed",
            args.total_time_ms,
            subscores=[
                {
                    "name": "correctness",
                    "score": round(passed / max(total, 1), 4),
                }
            ],
            additional_data={
                "correctness_passed": passed,
                "correctness_total": total,
                "correctness_results": correctness_results,
            },
        )
        return 0

    # ── Performance ──────────────────────────────────────────────────────
    print("\n=== Performance benchmark ===")
    benchmark_workloads_list = sample_benchmark_workloads(rng)
    speedups, bench_results = benchmark_workloads(
        candidate_lib, baseline_lib, benchmark_workloads_list
    )

    for r in bench_results:
        if "error" in r:
            print(f"  [ERROR] {r['label']}: {r['error']}")
        else:
            print(
                f"  {r['label']}: baseline={r['baseline_ms']:.3f}ms "
                f"candidate={r['candidate_ms']:.3f}ms "
                f"speedup={r['speedup']:.3f}x"
            )

    if speedups:
        safe_speedups = [max(s, 1e-15) for s in speedups]
        geo_mean = math.exp(
            sum(math.log(s) for s in safe_speedups) / len(safe_speedups)
        )
    else:
        geo_mean = 0.0

    score = round(geo_mean, 6)

    print(f"\nGeometric mean speedup: {geo_mean:.4f}x")
    print(f"Score: {score}")

    emit_reward(
        args.output_dir,
        score,
        f"Correctness OK ({passed}/{total}), geometric mean speedup {geo_mean:.4f}x",
        args.total_time_ms,
        subscores=[
            {"name": "correctness", "score": round(passed / max(total, 1), 4)},
            {"name": "speedup", "score": round(geo_mean, 4)},
        ],
        additional_data={
            "correctness_passed": passed,
            "correctness_total": total,
            "geometric_mean_speedup": round(geo_mean, 6),
            "workloads_benchmarked": len(speedups),
            "per_workload_speedups": [round(s, 4) for s in speedups],
            "benchmark_results": bench_results,
            "correctness_results": correctness_results,
        },
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
