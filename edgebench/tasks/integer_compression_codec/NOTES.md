# integer_compression_codec

The agent improves a uint32 integer codec (`libintcompress.so`, C ABI in `include/intcompress.h`:
`ic_encode`, `ic_decode`, `ic_decode_block`). The judge builds the submission with `make -j4`,
checks its dynamic symbols against a denylist, then encodes and decodes 8 fixed datasets (450 M
integers, 1.8 GB). Per dataset `S_i = min(bpi_base/bpi, 8) * min(GB/s / GB/s_base, 40)` (decode
throughput = best of 5 decodes). Raw score = weighted mean of `S_i` (weights 2, 1.5, 1.5, 1, 1,
1, 1, 1), maximize. The rescale is the v1 one (`linear` 0..100, clipped).

## Source

- Workspace (codec source, header, Makefile, tools) and the judge bundle (`runner_judge.py`,
  evaluation server, baseline): the task authors' repository (not public), identical by sha256 to
  the published v1 images.
- The English documents (`README.md`, `problem.md`, `scoring_scheme.md` and others, plus four
  judge-side READMEs): the versions shipped in the published v1 images (the repository has Chinese
  versions).
- The datasets are generated at build time by `tools/gen_data.py`, as in v1, and checked against
  v1's sha256 (`environment/datasets.sha256`, `judge/data.sha256`); the bytes depend on numpy, which
  is pinned to v1's 1.21.5. python3 3.10.12 and numpy come from the base's Ubuntu snapshot at v1's
  versions. Base: `bases/cpp`.
- `judge/run.sh`, `judge/emit_result.py`: new; they run v1's eval command unchanged and write
  `result.json` with v1's structured-result logic.
- `instruction.md`: v1's published prompt, verbatim (see Known issue 1).

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. Eight packages of the shared base (ca-certificates, openssl, sed, xz-utils and a few
   libraries) are at the base's slightly newer versions. None is used by the grader; compiler,
   binutils, libc, libstdc++ and Python are identical.
3. If the runner is killed before printing its result, v1 recorded an unrankable score; the new
   grader returns `valid=false`. Compile errors and denied symbols score `valid=true, 0`, as in v1.
4. The workspace git commit is identical to v1's (same hash).

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same shared host, interleaved,
five runs per side (host load varied from 13 to 143). Raw score (= 0..100 here), mean with the
range of runs.

| Submission | Old | New |
|---|---|---|
| empty (starter codec) | 0.28 (0.22–0.30) | 0.28 (0.25–0.30) |
| historical 1 (compile error) | 0 | 0 |
| historical 2 | 25.21 (20.72–29.53) | 27.23 (25.33–28.98) |
| historical 3 | 62.71 (50.42–67.26) | 63.44 (57.09–66.98) |
| historical 4 | 70.35 (65.88–71.83) | 68.90 (62.01–71.67) |
| historical 5 | 71.33 (70.80–71.85) | 71.10 (69.72–71.72) |
| historical 6 | 63.69 (51.18–73.80) | 66.09 (51.28–73.80) |

The deterministic part (status and, per dataset, encoded size and round-trip result) is identical
for every submission. Only decode throughput varies, on both sides alike when the host is busy;
every mean difference (at most 2.4) is smaller than the old judge's own range.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The instruction contains literal `\n` sequences.** v1's published prompt is one line with
   backslash-n separators; `instruction.md` reproduces it verbatim.
2. **Host-dependent score.** Throughput is compared with a fixed baseline measured on other
   hardware (a pinned 4-vCPU machine), and the judge sets no CPU pinning or limit, so scores move
   with host CPU and load. The docs say the starter scores 1.0; it scores about 0.3 here.
3. **No CPU limit.** Multithreaded decoders profit from all host cores, while the docs describe a
   4-vCPU evaluator.
4. **The symbol denylist is easy to bypass.** It rejects only some imported functions, so a
   decoder could read the original data instead of decoding it. (Found by reading the code; not
   tested.)
5. **The submission can tamper with grading.** The submitted `Makefile` runs as root in the judge
   before the runners are used (the cross-task issue in `tasks/SCHEMA.md`).
6. **The hidden data is public by design.** The workspace generator reproduces the exact judge
   datasets. The 8x/40x caps bound what memorization can gain, but an encoder could recognize them.
7. **The 0..100 scale saturates early.** Raw scores can reach 320 (8 x 40), but the rescale clips
   at 100.
8. Minor doc mismatches: the workspace mentions gcc-12/clang-15 while the images have g++ 11.4,
   and "GB/s" is computed with 2^30 bytes.
