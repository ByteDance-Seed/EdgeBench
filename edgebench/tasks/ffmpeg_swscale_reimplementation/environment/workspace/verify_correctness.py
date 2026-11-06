#!/usr/bin/env python3
"""
verify_correctness.py — Agent development tool.

Loads the candidate shared library, runs a set of public conversion workloads,
and compares outputs against the public scalar baseline. Reports per-workload
PSNR and overall pass/fail.

Usage:
    python3 /app/verify_correctness.py [--candidate /path/to/libswscale_candidate.so]
"""

from __future__ import annotations

import argparse
import json
import math
import os
import subprocess
import sys
import tempfile
from pathlib import Path

# Add /app to path so pixel_formats is importable
sys.path.insert(0, "/app")
from pixel_formats import (
    PIXFMT_DESCS,
    PIXFMT_NAMES,
    FFMPEG_PIXFMT,
    ALGO_NEAREST,
    ALGO_BILINEAR,
    ALGO_BICUBIC,
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
    load_swscale_library,
    allocate_image,
    image_to_bytes,
    fill_image_from_bytes,
)

FFMPEG_BIN = "/reference/ffmpeg"
BASELINE_LIB = "/app/libswscale_public_baseline.so"
MEDIA_DIR = Path("/app/media")

PSNR_THRESHOLD_CONVERT = 60.0  # format conversion only (same size)
PSNR_THRESHOLD_SCALE = 40.0  # with scaling


def find_candidate_lib() -> str:
    """Search common locations for the candidate shared library."""
    candidates = [
        "/app/swscale-impl/zig-out/lib/libswscale_candidate.so",
        "/app/swscale-impl/target/release/libswscale_candidate.so",
        "/app/swscale-impl/libswscale_candidate.so",
        "/app/swscale-impl/zig-out/lib/libswscale_candidate.so.0",
    ]
    for p in candidates:
        if os.path.exists(p):
            return p
    # Glob fallback
    import glob

    hits = glob.glob("/app/swscale-impl/**/libswscale_candidate*", recursive=True)
    if hits:
        return hits[0]
    return ""


def compute_psnr(data_a: bytes, data_b: bytes) -> float:
    """Compute PSNR between two byte sequences (treating each byte as a sample)."""
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


def generate_reference_output(reference, workload: dict, src_planes: list[bytes]) -> list[bytes]:
    """Use the public C-only baseline, with the same C ABI as the candidate.

    The CLI binary enables assembly and uses different rounding on some paths.
    Separate source buffers also prevent a candidate that mutates its input from
    changing the reference output.
    """
    src_fmt, dst_fmt = workload["src_fmt"], workload["dst_fmt"]
    src_w, src_h = workload["src_w"], workload["src_h"]
    dst_w, dst_h = workload["dst_w"], workload["dst_h"]
    src_data, src_stride, src_bufs = allocate_image(src_fmt, src_w, src_h)
    dst_data, dst_stride, dst_bufs = allocate_image(dst_fmt, dst_w, dst_h)
    fill_image_from_bytes(src_fmt, src_w, src_h, src_data, src_stride, src_planes)
    ctx = reference.swscale_create(
        src_w, src_h, src_fmt, dst_w, dst_h, dst_fmt, workload["algo"]
    )
    if not ctx:
        raise RuntimeError("Scalar reference swscale_create returned NULL")
    try:
        ret = reference.swscale_process(ctx, src_data, src_stride, dst_data, dst_stride)
        if ret != 0:
            raise RuntimeError(f"Scalar reference swscale_process returned {ret}")
        return image_to_bytes(dst_fmt, dst_w, dst_h, dst_data, dst_stride)
    finally:
        reference.swscale_destroy(ctx)


def load_raw_planes(path: Path, fmt: int, w: int, h: int) -> list[bytes]:
    """Load a raw file into per-plane byte sequences."""
    desc = PIXFMT_DESCS[fmt]
    data = path.read_bytes()
    planes = []
    offset = 0
    for i in range(desc.num_planes):
        pw = desc.plane_width(i, w) * desc.planes[i].bpp
        ph = desc.plane_height(i, h)
        plane_size = pw * ph
        planes.append(data[offset : offset + plane_size])
        offset += plane_size
    return planes


# ── Public workloads ─────────────────────────────────────────────────────────

PUBLIC_WORKLOADS = [
    # Format conversion only (same size)
    {
        "src_fmt": PIXFMT_YUV420P,
        "dst_fmt": PIXFMT_RGB24,
        "src_w": 640,
        "src_h": 480,
        "dst_w": 640,
        "dst_h": 480,
        "algo": ALGO_BILINEAR,
        "label": "yuv420p→rgb24 640x480",
    },
    {
        "src_fmt": PIXFMT_RGB24,
        "dst_fmt": PIXFMT_YUV420P,
        "src_w": 640,
        "src_h": 480,
        "dst_w": 640,
        "dst_h": 480,
        "algo": ALGO_BILINEAR,
        "label": "rgb24→yuv420p 640x480",
    },
    {
        "src_fmt": PIXFMT_RGB24,
        "dst_fmt": PIXFMT_BGRA,
        "src_w": 640,
        "src_h": 480,
        "dst_w": 640,
        "dst_h": 480,
        "algo": ALGO_BILINEAR,
        "label": "rgb24→bgra 640x480",
    },
    {
        "src_fmt": PIXFMT_RGB24,
        "dst_fmt": PIXFMT_GRAY8,
        "src_w": 640,
        "src_h": 480,
        "dst_w": 640,
        "dst_h": 480,
        "algo": ALGO_BILINEAR,
        "label": "rgb24→gray8 640x480",
    },
    {
        "src_fmt": PIXFMT_RGB24,
        "dst_fmt": PIXFMT_NV12,
        "src_w": 640,
        "src_h": 480,
        "dst_w": 640,
        "dst_h": 480,
        "algo": ALGO_BILINEAR,
        "label": "rgb24→nv12 640x480",
    },
    # Additional format coverage (agents need dev feedback on all tested formats)
    {
        "src_fmt": PIXFMT_RGB24,
        "dst_fmt": PIXFMT_BGR24,
        "src_w": 640,
        "src_h": 480,
        "dst_w": 640,
        "dst_h": 480,
        "algo": ALGO_BILINEAR,
        "label": "rgb24→bgr24 640x480",
    },
    {
        "src_fmt": PIXFMT_RGB24,
        "dst_fmt": PIXFMT_RGBA,
        "src_w": 640,
        "src_h": 480,
        "dst_w": 640,
        "dst_h": 480,
        "algo": ALGO_BILINEAR,
        "label": "rgb24→rgba 640x480",
    },
    {
        "src_fmt": PIXFMT_RGB24,
        "dst_fmt": PIXFMT_NV21,
        "src_w": 640,
        "src_h": 480,
        "dst_w": 640,
        "dst_h": 480,
        "algo": ALGO_BILINEAR,
        "label": "rgb24→nv21 640x480",
    },
    {
        "src_fmt": PIXFMT_YUV422P,
        "dst_fmt": PIXFMT_RGB24,
        "src_w": 640,
        "src_h": 480,
        "dst_w": 640,
        "dst_h": 480,
        "algo": ALGO_BILINEAR,
        "label": "yuv422p→rgb24 640x480",
    },
    {
        "src_fmt": PIXFMT_YUV444P,
        "dst_fmt": PIXFMT_RGB24,
        "src_w": 640,
        "src_h": 480,
        "dst_w": 640,
        "dst_h": 480,
        "algo": ALGO_BILINEAR,
        "label": "yuv444p→rgb24 640x480",
    },
    # With scaling
    {
        "src_fmt": PIXFMT_RGB24,
        "dst_fmt": PIXFMT_YUV420P,
        "src_w": 1920,
        "src_h": 1080,
        "dst_w": 640,
        "dst_h": 360,
        "algo": ALGO_BILINEAR,
        "label": "rgb24→yuv420p 1080p→360p bilinear",
    },
    {
        "src_fmt": PIXFMT_RGB24,
        "dst_fmt": PIXFMT_RGB24,
        "src_w": 640,
        "src_h": 480,
        "dst_w": 320,
        "dst_h": 240,
        "algo": ALGO_NEAREST,
        "label": "rgb24→rgb24 640x480→320x240 nearest",
    },
    {
        "src_fmt": PIXFMT_RGB24,
        "dst_fmt": PIXFMT_RGB24,
        "src_w": 320,
        "src_h": 240,
        "dst_w": 640,
        "dst_h": 480,
        "algo": ALGO_BICUBIC,
        "label": "rgb24→rgb24 320x240→640x480 bicubic",
    },
]


def run_workload(lib, workload: dict, reference=None) -> dict:
    """Run a single conversion workload and return result dict."""
    label = workload["label"]
    src_fmt = workload["src_fmt"]
    dst_fmt = workload["dst_fmt"]
    src_w, src_h = workload["src_w"], workload["src_h"]
    dst_w, dst_h = workload["dst_w"], workload["dst_h"]
    algo = workload["algo"]

    # Find or generate source data
    src_name = PIXFMT_NAMES[src_fmt]
    src_file = MEDIA_DIR / f"gradient_{src_w}x{src_h}_{src_name}.raw"
    if not src_file.exists():
        src_file = MEDIA_DIR / f"colorbars_{src_w}x{src_h}_{src_name}.raw"
    if not src_file.exists():
        src_file = MEDIA_DIR / f"noise_{src_w}x{src_h}_{src_name}.raw"
    if not src_file.exists():
        # Generate from RGB24 source using FFmpeg
        rgb_src = MEDIA_DIR / f"gradient_{src_w}x{src_h}_rgb24.raw"
        if not rgb_src.exists():
            rgb_src = MEDIA_DIR / f"colorbars_{src_w}x{src_h}_rgb24.raw"
        if not rgb_src.exists():
            return {"label": label, "status": "skip", "reason": "no source media"}
        with tempfile.NamedTemporaryFile(suffix=".raw", delete=False) as f:
            tmp_path = f.name
        try:
            cmd = [
                FFMPEG_BIN,
                "-y",
                "-f",
                "rawvideo",
                "-pix_fmt",
                "rgb24",
                "-s",
                f"{src_w}x{src_h}",
                "-i",
                str(rgb_src),
                "-f",
                "rawvideo",
                "-pix_fmt",
                FFMPEG_PIXFMT[src_fmt],
                tmp_path,
            ]
            subprocess.run(cmd, check=True, capture_output=True)
            src_planes = load_raw_planes(Path(tmp_path), src_fmt, src_w, src_h)
        finally:
            os.unlink(tmp_path)
    else:
        src_planes = load_raw_planes(src_file, src_fmt, src_w, src_h)

    if reference is None:
        reference = load_swscale_library(BASELINE_LIB)
    ref_planes = generate_reference_output(reference, workload, src_planes)

    # Allocate independent candidate buffers
    src_data, src_stride, src_bufs = allocate_image(src_fmt, src_w, src_h)
    dst_data, dst_stride, dst_bufs = allocate_image(dst_fmt, dst_w, dst_h)

    # Fill source
    fill_image_from_bytes(src_fmt, src_w, src_h, src_data, src_stride, src_planes)

    # Create context and process
    ctx = lib.swscale_create(src_w, src_h, src_fmt, dst_w, dst_h, dst_fmt, algo)
    if not ctx:
        return {
            "label": label,
            "status": "fail",
            "reason": "swscale_create returned NULL",
        }

    ret = lib.swscale_process(ctx, src_data, src_stride, dst_data, dst_stride)
    lib.swscale_destroy(ctx)

    if ret != 0:
        return {
            "label": label,
            "status": "fail",
            "reason": f"swscale_process returned {ret}",
        }

    # Extract candidate output
    candidate_planes = image_to_bytes(dst_fmt, dst_w, dst_h, dst_data, dst_stride)

    ref_desc = PIXFMT_DESCS[dst_fmt]

    # Compute PSNR per plane
    is_scaling = (src_w != dst_w) or (src_h != dst_h)
    threshold = PSNR_THRESHOLD_SCALE if is_scaling else PSNR_THRESHOLD_CONVERT
    plane_psnrs = []
    ok = True

    for i in range(ref_desc.num_planes):
        if i < len(candidate_planes) and i < len(ref_planes):
            psnr = compute_psnr(ref_planes[i], candidate_planes[i])
            plane_psnrs.append(psnr)
            if psnr < threshold:
                ok = False
        else:
            plane_psnrs.append(0.0)
            ok = False

    min_psnr = min(plane_psnrs) if plane_psnrs else 0.0
    status = "pass" if ok else "fail"

    return {
        "label": label,
        "status": status,
        "min_psnr": round(min_psnr, 2),
        "plane_psnrs": [round(p, 2) for p in plane_psnrs],
        "threshold": threshold,
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--candidate", default="", help="Path to libswscale_candidate.so"
    )
    args = parser.parse_args()

    candidate_path = args.candidate or find_candidate_lib()
    if not candidate_path or not os.path.exists(candidate_path):
        print("ERROR: Could not find libswscale_candidate.so")
        print("Build your project first, then re-run this script.")
        print("Searched:", find_candidate_lib() or "(nothing found)")
        sys.exit(1)

    if not os.path.exists(BASELINE_LIB):
        print(f"ERROR: Scalar baseline library not found at {BASELINE_LIB}")
        sys.exit(1)

    print(f"Loading candidate: {candidate_path}")
    lib = load_swscale_library(candidate_path)
    reference = load_swscale_library(BASELINE_LIB)
    print(f"Scalar reference: {BASELINE_LIB}")

    results = []
    passed = 0
    total = 0

    for wl in PUBLIC_WORKLOADS:
        total += 1
        try:
            result = run_workload(lib, wl, reference)
        except Exception as e:
            result = {"label": wl["label"], "status": "error", "reason": str(e)}
        results.append(result)

        status_icon = "PASS" if result["status"] == "pass" else "FAIL"
        if result.get("reason"):
            detail = result["reason"]
        elif result.get("min_psnr") is not None:
            detail = f"PSNR={result['min_psnr']}"
        else:
            detail = result.get("status", "?")
        print(f"  [{status_icon}] {result['label']}  ({detail})")

        if result["status"] == "pass":
            passed += 1

    print(f"\n{passed}/{total} workloads passed")

    # Write results
    results_path = Path("/app/results/correctness.json")
    results_path.parent.mkdir(parents=True, exist_ok=True)
    with open(results_path, "w") as f:
        json.dump({"passed": passed, "total": total, "results": results}, f, indent=2)

    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
