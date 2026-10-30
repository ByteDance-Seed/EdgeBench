#!/usr/bin/env python3
"""
prepare_media.py — Generate synthetic test images at Docker build time.

Creates raw pixel-data files for agent development and verifier testing.
Run during `docker build` after FFmpeg is installed.
"""

from __future__ import annotations

import json
import os
import subprocess
from pathlib import Path

MEDIA_DIR = Path("/app/media")
VERIFIER_MEDIA_DIR = Path("/verifier-data/media")


def generate_gradient_rgb24(width: int, height: int) -> bytes:
    """Horizontal R gradient, vertical G gradient, diagonal B."""
    pixels = bytearray(width * height * 3)
    for y in range(height):
        for x in range(width):
            off = (y * width + x) * 3
            pixels[off + 0] = int(255 * x / max(width - 1, 1))  # R
            pixels[off + 1] = int(255 * y / max(height - 1, 1))  # G
            pixels[off + 2] = int(255 * (x + y) / max(width + height - 2, 1))  # B
    return bytes(pixels)


def generate_colorbars_rgb24(width: int, height: int) -> bytes:
    """SMPTE-style colour bars (simplified 8-bar pattern)."""
    bars = [
        (192, 192, 192),  # white
        (192, 192, 0),  # yellow
        (0, 192, 192),  # cyan
        (0, 192, 0),  # green
        (192, 0, 192),  # magenta
        (192, 0, 0),  # red
        (0, 0, 192),  # blue
        (0, 0, 0),  # black
    ]
    pixels = bytearray(width * height * 3)
    bar_w = width // len(bars)
    for y in range(height):
        for x in range(width):
            bar_idx = min(x // max(bar_w, 1), len(bars) - 1)
            off = (y * width + x) * 3
            pixels[off + 0] = bars[bar_idx][0]
            pixels[off + 1] = bars[bar_idx][1]
            pixels[off + 2] = bars[bar_idx][2]
    return bytes(pixels)


def generate_noise_rgb24(width: int, height: int, seed: int = 42) -> bytes:
    """Deterministic pseudo-random noise pattern."""
    import random

    rng = random.Random(seed)
    return bytes(rng.getrandbits(8) for _ in range(width * height * 3))


def rgb24_to_rawfile(data: bytes, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)


def convert_with_ffmpeg(
    ffmpeg: str,
    src: Path,
    src_fmt: str,
    src_w: int,
    src_h: int,
    dst: Path,
    dst_fmt: str,
    dst_w: int | None = None,
    dst_h: int | None = None,
) -> None:
    """Use the reference FFmpeg binary to convert raw pixel data."""
    cmd = [
        ffmpeg,
        "-y",
        "-f",
        "rawvideo",
        "-pix_fmt",
        src_fmt,
        "-s",
        f"{src_w}x{src_h}",
        "-i",
        str(src),
    ]
    if dst_w and dst_h:
        cmd += ["-s", f"{dst_w}x{dst_h}"]
    cmd += [
        "-f",
        "rawvideo",
        "-pix_fmt",
        dst_fmt,
        str(dst),
    ]
    subprocess.run(cmd, check=True, capture_output=True)


def main() -> None:
    ffmpeg = "/reference/ffmpeg"
    if not os.path.exists(ffmpeg):
        ffmpeg = "ffmpeg"

    MEDIA_DIR.mkdir(parents=True, exist_ok=True)
    VERIFIER_MEDIA_DIR.mkdir(parents=True, exist_ok=True)

    manifest = []

    # ── Public test media (agent-visible) ──────────────────────────────

    # 1. 640x480 RGB24 gradient
    rgb_data = generate_gradient_rgb24(640, 480)
    p = MEDIA_DIR / "gradient_640x480_rgb24.raw"
    rgb24_to_rawfile(rgb_data, p)
    manifest.append(
        {"name": "gradient_640x480", "path": str(p), "fmt": "rgb24", "w": 640, "h": 480}
    )

    # Convert gradient to other formats
    for dst_fmt in ["yuv420p", "yuv422p", "bgra", "nv12", "gray8"]:
        dst = MEDIA_DIR / f"gradient_640x480_{dst_fmt}.raw"
        convert_with_ffmpeg(ffmpeg, p, "rgb24", 640, 480, dst, dst_fmt)
        manifest.append(
            {
                "name": f"gradient_640x480_{dst_fmt}",
                "path": str(dst),
                "fmt": dst_fmt,
                "w": 640,
                "h": 480,
            }
        )

    # 2. 1920x1080 colour bars
    bars_data = generate_colorbars_rgb24(1920, 1080)
    p = MEDIA_DIR / "colorbars_1920x1080_rgb24.raw"
    rgb24_to_rawfile(bars_data, p)
    manifest.append(
        {
            "name": "colorbars_1920x1080",
            "path": str(p),
            "fmt": "rgb24",
            "w": 1920,
            "h": 1080,
        }
    )

    for dst_fmt in ["yuv420p", "nv12", "rgba"]:
        dst = MEDIA_DIR / f"colorbars_1920x1080_{dst_fmt}.raw"
        convert_with_ffmpeg(ffmpeg, p, "rgb24", 1920, 1080, dst, dst_fmt)
        manifest.append(
            {
                "name": f"colorbars_1920x1080_{dst_fmt}",
                "path": str(dst),
                "fmt": dst_fmt,
                "w": 1920,
                "h": 1080,
            }
        )

    # 3. 320x240 noise
    noise_data = generate_noise_rgb24(320, 240, seed=42)
    p = MEDIA_DIR / "noise_320x240_rgb24.raw"
    rgb24_to_rawfile(noise_data, p)
    manifest.append(
        {"name": "noise_320x240", "path": str(p), "fmt": "rgb24", "w": 320, "h": 240}
    )

    # Scaled version
    for dst_fmt in ["yuv420p"]:
        dst = MEDIA_DIR / f"noise_320x240_{dst_fmt}.raw"
        convert_with_ffmpeg(ffmpeg, p, "rgb24", 320, 240, dst, dst_fmt)
        manifest.append(
            {
                "name": f"noise_320x240_{dst_fmt}",
                "path": str(dst),
                "fmt": dst_fmt,
                "w": 320,
                "h": 240,
            }
        )

    # Write manifest
    with open(MEDIA_DIR / "manifest.json", "w") as f:
        json.dump(manifest, f, indent=2)

    # ── Verifier-only hidden media ─────────────────────────────────────

    hidden_manifest = []

    # Different sizes and patterns not in the public set
    sizes = [
        (800, 600, 101),
        (1280, 720, 202),
        (1920, 1080, 303),
        (3840, 2160, 404),
        (720, 576, 505),  # PAL
        (352, 288, 606),  # CIF
        (1001, 751, 707),  # Odd dimensions
    ]

    for w, h, seed in sizes:
        rgb_data = generate_noise_rgb24(w, h, seed=seed)
        p = VERIFIER_MEDIA_DIR / f"hidden_{w}x{h}_rgb24.raw"
        rgb24_to_rawfile(rgb_data, p)
        hidden_manifest.append(
            {"name": f"hidden_{w}x{h}", "path": str(p), "fmt": "rgb24", "w": w, "h": h}
        )

        # Also store YUV420P version
        dst = VERIFIER_MEDIA_DIR / f"hidden_{w}x{h}_yuv420p.raw"
        convert_with_ffmpeg(ffmpeg, p, "rgb24", w, h, dst, "yuv420p")
        hidden_manifest.append(
            {
                "name": f"hidden_{w}x{h}_yuv420p",
                "path": str(dst),
                "fmt": "yuv420p",
                "w": w,
                "h": h,
            }
        )

    with open(VERIFIER_MEDIA_DIR / "manifest.json", "w") as f:
        json.dump(hidden_manifest, f, indent=2)

    print(f"Generated {len(manifest)} public media files in {MEDIA_DIR}")
    print(
        f"Generated {len(hidden_manifest)} hidden media files in {VERIFIER_MEDIA_DIR}"
    )


if __name__ == "__main__":
    main()
