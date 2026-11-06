# FFmpeg libswscale Re-implementation

You are a systems engineer. Your goal is to re-implement FFmpeg's **libswscale**
image scaling and pixel-format conversion library in **Zig or Rust**, producing
a C-compatible shared library that matches or exceeds FFmpeg's C scalar
reference performance using portable SIMD.

## Setup

1. FFmpeg source (libswscale + libavutil) is at `/reference/ffmpeg-src/`.
   Study the scalar C implementation — this is what you are reimplementing.
2. A full FFmpeg binary (with ASM optimisations) is at `/reference/ffmpeg`.
   Use it to generate test inputs/outputs and verify your understanding.
3. The public performance baseline library is at `/app/libswscale_public_baseline.so`.
   This wraps FFmpeg's C-only code (compiled with `--disable-asm`). Your
   implementation is benchmarked against this baseline.
4. Your workspace is `/app/swscale-impl/`. Scaffold templates for both Zig
   and Rust are provided — pick one and build from there.
5. The C API you must implement is defined in `/app/swscale_api.h`.

```bash
cat /app/.timer/remaining_secs   # check time remaining
cat /app/.timer/elapsed_secs     # check time elapsed
```

## Deliverable

Source code at `/app/swscale-impl/` that compiles to a shared library named
`libswscale_candidate.so`, exporting these three C-linkage functions:

```c
void *swscale_create(int src_w, int src_h, int src_fmt,
                     int dst_w, int dst_h, int dst_fmt, int algo);
int   swscale_process(void *ctx,
                      const uint8_t *const src[4], const int src_stride[4],
                      uint8_t *const dst[4], const int dst_stride[4]);
void  swscale_destroy(void *ctx);
```

The verifier will **rebuild your library from source** before testing.
Pre-built binaries without source will be rejected.

### Build commands the verifier tries (in order):

1. If `build.zig` exists: `zig build -Doptimize=ReleaseFast`
2. If `Cargo.toml` exists: `cargo build --release`
3. If `Makefile` exists: `make release`

The output library must be discoverable at one of:
- `zig-out/lib/libswscale_candidate.so`
- `target/release/libswscale_candidate.so`
- `./libswscale_candidate.so`

## Supported Pixel Formats

Your library must handle conversions between any pair of these formats:

| ID | Name     | Layout                          |
|----|----------|---------------------------------|
| 0  | YUV420P  | Planar YUV 4:2:0 (3 planes)    |
| 1  | YUV422P  | Planar YUV 4:2:2 (3 planes)    |
| 2  | YUV444P  | Planar YUV 4:4:4 (3 planes)    |
| 3  | NV12     | Semi-planar Y + UV (2 planes)   |
| 4  | NV21     | Semi-planar Y + VU (2 planes)   |
| 5  | RGB24    | Packed R,G,B (1 plane)          |
| 6  | BGR24    | Packed B,G,R (1 plane)          |
| 7  | RGBA     | Packed R,G,B,A (1 plane)        |
| 8  | BGRA     | Packed B,G,R,A (1 plane)        |
| 9  | GRAY8    | Single-plane grayscale          |

## Supported Scaling Algorithms

| ID | Name      | Description                |
|----|-----------|----------------------------|
| 0  | Nearest   | Nearest-neighbour sampling |
| 1  | Bilinear  | Bilinear interpolation     |
| 2  | Bicubic   | Bicubic interpolation      |

When `src_w == dst_w` and `src_h == dst_h`, only pixel-format conversion is
needed (no scaling). This is the most common fast path.

**Buffer alignment**: The verifier allocates all source and destination plane
buffers with 32-byte alignment. You may assume aligned loads/stores in your
SIMD code. All dimensions for subsampled formats (YUV420P, YUV422P, NV12,
NV21) will have even width and height.

## What Has to Stay Correct

The verifier checks output quality on hidden workloads:

- **Format-only conversion** (same dimensions): PSNR ≥ 60 dB per plane,
  or exact byte match for mathematically lossless paths (e.g. RGB↔BGR channel swap).
- **Scaling conversion** (different dimensions): PSNR ≥ 40 dB per plane.
- If correctness fails on any hidden workload, the score is **zero**.

## Scoring

```
if not build_ok or not correctness_ok or anti_cheat_violated:
    reward = 0.0
else:
    reward = geometric_mean(baseline_time / candidate_time)
```

A reward of 1.0 means you match FFmpeg's C scalar speed exactly.
Above 1.0 means you are faster. The SIMD opportunity is significant —
FFmpeg's own recent swscale rewrite achieved 2.6× overall speedup through
x86 SIMD backends.

## How to Work

### Build and test cycle:

```bash
# Pick your language and start from the scaffold
cp -r /app/scaffold/zig/* /app/swscale-impl/   # or /app/scaffold/rust/*

# Build
cd /app/swscale-impl
zig build -Doptimize=ReleaseFast               # or: cargo build --release

# Test correctness against FFmpeg reference
python3 /app/verify_correctness.py

# Benchmark against the public baseline
python3 /app/run_dev_bench.py
```

### Pre-generated test media:

Test images are pre-generated at `/app/media/` in various formats and sizes
(gradients, colour bars, noise). Use these for quick iteration:

```bash
ls /app/media/             # See available test images
cat /app/media/manifest.json  # Format, size, path metadata
```

### Use the reference FFmpeg binary for experiments:

```bash
# Generate a test pattern
/reference/ffmpeg -f lavfi -i testsrc=duration=1:size=1920x1080:rate=1 \
    -frames:v 1 -f rawvideo -pix_fmt yuv420p /tmp/test_yuv420p.raw

# Convert between formats (use pre-generated media or your own)
/reference/ffmpeg -f rawvideo -pix_fmt yuv420p -s 640x480 \
    -i /app/media/gradient_640x480_yuv420p.raw \
    -f rawvideo -pix_fmt rgb24 /tmp/gradient_rgb24.raw
```

**Note:** `verify_correctness.py` is a development-only tool that uses
`/reference/ffmpeg` to generate golden outputs. The reference binary is
deleted before final scoring — the actual verifier compares your output
against the baseline library instead.

### Study the FFmpeg source:

```bash
# The scalar C implementation you are competing against
ls /reference/ffmpeg-src/libswscale/
# Start with: swscale.c (entry point), swscale_internal.h (structures)
# Look for the pixel conversion and scaling functions in the directory
```

### Key reference files:

- `/app/swscale_api.h` — The C API your library must export
- `/app/pixel_formats.py` — Pixel format metadata, plane geometry helpers,
  and the ctypes loading code the verifier uses to call your library

## Constraints

You CAN:
- Use Zig's `@Vector` SIMD or Rust's `std::simd` / `std::arch` intrinsics
- Use any algorithm or data structure for the conversion
- Create helper files and modules
- Pre-compute lookup tables and filter coefficients in `swscale_create`

You CANNOT:
- Wrap, exec, or dlopen the reference FFmpeg binary or its libraries
  (the reference is **deleted before verification**)
- Access `/tests/` or any hidden verifier files
- Use inline assembly (the task tests portable SIMD, not hand-tuned ASM)
- Download external code (no internet access)

## Time Budget

Your wall-clock budget is enforced by Harbor and exposed through a timer daemon:

```bash
cat /app/.timer/remaining_secs
cat /app/.timer/elapsed_secs
test -f /app/.timer/alert_30min
test -f /app/.timer/alert_10min
test -f /app/.timer/alert_5min
```

You have a fixed wall-clock budget for this task. Plan your work to make effective use of the available time.

### Suggested phases:
- Study FFmpeg scalar source, understand YUV↔RGB maths and scaling filter
  generation, and set up your project scaffold.
- Implement core format conversions (YUV420P↔RGB24 first) and get
  `verify_correctness.py` passing for basic cases.
- Add scaling (bilinear at minimum), then SIMD optimisation of hot conversion
  loops.
- Expand format coverage and benchmark against the baseline.
- Finish with a final correctness sweep, edge cases, and cleanup.

Keep a **building and working** library at all times. A library that handles
60% of conversions correctly at 1.2× speed is much better than one that
doesn't compile.

## Behavioral Rules

- Never stop to ask. Work autonomously until interrupted.
- Check time regularly before starting large refactors.
- Keep your library buildable at all times.
- Test against the reference FFmpeg frequently.
- Optimise for breadth of format coverage first, then depth of SIMD optimisation.
