# ffmpeg_swscale_reimplementation

The agent re-implements FFmpeg's libswscale (10 pixel formats; nearest, bilinear and bicubic
scaling) as a C-ABI shared library `libswscale_candidate.so`, in Rust (the provided scaffold,
already 30/30 correct) or Zig. The judge removes the reference FFmpeg, runs anti-cheat checks,
rebuilds the library from source, checks 30 hidden workloads against a baseline built from
FFmpeg's C code (`--disable-asm`) by per-plane PSNR, and if all pass benchmarks 10 workloads
(median of 100 runs each). Raw score = geometric-mean speedup over the baseline, 0 if any gate
fails (maximize). The rescale is the v1 one (`log_anchor`, anchor 14.155 -> 43).

## Source

- Workspace files, scaffolds and the judge's `tests/` (`test.sh`, `compute_reward.py`): the task
  authors' copy of the public frontier-swe task `ffmpeg-swscale-rewrite`, identical by sha256 to
  the published v1 images. The Rust scaffold `lib.rs`, the Zig `build.zig` fix and
  `pytest_shim.sh` come from v1's build recipe, also byte-identical.
- `judge/eval.sh`: v1's eval command, wrapped exactly as the v1 harness wrapped it.
  `judge/run.sh` and `judge/grade.py` are new and write `result.json` with v1's parsing.
- FFmpeg n7.1 (upstream commit `b08d7969…`) from its GitHub archive, sha256-checked. Zig 0.14.0
  and rustup 1.29.0 sha256-checked; Rust stable and nightly pinned to the dated channels of v1's
  build day (rustc 1.96.0 and 1.98.0-nightly 2026-06-09). Task apt packages from the Ubuntu
  snapshot of v1's build day, at v1's versions. Base: `bases/cpp`.
- The reference FFmpeg build, the baseline library, all toolchains and the generated media are
  byte-identical to the published v1 images.
- `instruction.md`: v1's prompt, verbatim.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. `/app` is a symlink to `/home/workspace`, as v1's build recipe made it. The published v1 image
   had a stale directory copy there instead, so the dev tools and the instruction's
   `/app/results/...` paths did not see the agent's work. Grading never reads `/app`.
3. Eight packages of the shared base (ca-certificates, openssl, sed, xz-utils and a few
   libraries) are at the base's slightly newer versions. FFmpeg, the baseline and every
   toolchain file are byte-identical.
4. v1's helper files under `/tmp` moved to `/judge/`, with the eval script's import path changed
   to match. The empty `/tmp/verifier` directory is created at run time instead of shipped.
5. If no total score is printed (only when the eval script dies early), v1 recorded an
   unrankable score; the new grader returns `valid=false`. Empty submissions and gate failures
   score `valid=true, 0`, as in v1.
6. The workspace git commit is identical to v1's (same hash).

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same host, interleaved; 2–7 runs
per side under varying host load. Raw score (mean, with the range of runs); 0..100 of the mean in
brackets.

| Submission | Old | New |
|---|---|---|
| empty, historical 1 (29/30 correct) | 0 | 0 |
| starter scaffold | 0.502 (0.487–0.509) | 0.511 (0.507–0.521) |
| historical 2 | 1.70 (1.68–1.76) [8.62] | 1.66 (1.57–1.71) [8.25] |
| historical 3 | 9.67 (7.53–10.84) [36.72] | 9.46 (8.49–11.92) [36.36] |
| historical 4 | 9.25 (7.99–10.15) [36.03] | 9.13 (8.62–10.32) [35.84] |
| historical 5 | 16.23 (10.82–21.18) [44.83] | 15.58 (13.02–20.63) [44.37] |
| historical 6 | 46.4 (38.6–59.8) [62.09] | 44.9 (41.9–49.6) [61.71] |
| forged build output (Known issue 1) | 1000 | 1000 |

Every gate outcome, pass count and summary matches. Speedups are wall-clock ratios that move by
up to ±25% between runs of the old judge alone; the mean difference is under 0.5 points on 0..100
for every row, well inside that spread.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The submission can inject a score through its build output.** The judge prints the build log
   before the real score line and the first `TOTAL_SCORE` in the output wins, so a submission
   whose build prints a score line gets that score even if its library fails every workload. A fix
   is to read the reward file the grader writes instead of the log.
2. **The eval script's failure hints never appear.** The v1 harness appended `2>&1` to the
   heredoc terminator of the eval command, so its final failure-category step fails. No score
   effect; reproduced as is.
3. **Rust works only in login shells.** The image environment has no `CARGO_HOME`/`RUSTUP_HOME`,
   so `cargo` fails in a non-login shell, including the instruction's first command; `bash -l`
   works. The judge sets the variables itself.
4. **Host-dependent score.** Speedups are measured without a CPU limit, multi-threaded candidates
   scale with the host's free cores, and several historical submissions build with
   `target-cpu=native`. Scores move with host and load, and historical scores are not exactly
   reproducible on another host.
5. **Hidden workloads are fixed.** The workload generator uses a constant seed, the instruction
   names four of the workloads, and the work image contains the "verifier-only" media (unused by
   the grader).
6. **Contradictory instruction.** One section says the scaffold reaches 26/30 and lists failures
   to fix; another says it already passes 30/30 (it does). It also says not to switch to Zig but
   shows a command that copies the Zig scaffold.
7. **Anti-cheat is pattern-based.** The source scan matches strings and `nm -D` checks only
   exported symbols. Re-implementing FFmpeg code statically is allowed by design.
8. **The submission can tamper with grading.** Its build scripts run as root in the judge
   container before scoring (the cross-task issue in `tasks/SCHEMA.md`).
9. **The dev tool disagrees with the judge.** `verify_correctness.py` compares against the
   assembly-optimized reference, the judge against the C-only baseline; the scaffold, which passes
   all 30 hidden workloads, shows 9/13 on the public tool.
10. `language = "C++"` in the task metadata; the deliverable is Rust or Zig.
