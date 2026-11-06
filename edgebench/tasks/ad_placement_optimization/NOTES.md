# ad_placement_optimization

AtCoder Heuristic Contest 001 "AtCoder Ad", in ALE-Bench style. The agent writes `solution.cpp`.
The judge compiles it with `g++ -std=c++17 -O2`, runs it on 50 fixed cases (5 s wall clock each,
at most 2 in parallel), scores each output with `tools/bin/tester`, and sums the scores of the
`OK` cases. Raw score = that sum (maximize); the 0..100 rescale is the v1 one (`piecewise_max`).

## Source

- Workspace (`solution.cpp`, assets, the Rust source of `gen`/`tester`) and the 50 judge cases:
  the task authors' repository (not public), unchanged since v1 and identical by sha256 to the
  published v1 images.
- `environment/workspace/README.md` and `tools/README.md`: the English versions shipped in the
  published v1 work image (the authors' repository only has Chinese versions).
- `judge/eval_ahc.sh`: byte-identical to v1's eval script. `judge/run.sh` is new and writes
  `result.json` with v1's scoring logic.
- `instruction.md`: v1's prompt, verbatim.
- Base `bases/cpp`: `ubuntu:jammy-20260509` (the same image under v1) with apt from the Ubuntu
  snapshot of 2026-06-17, so every package version matches v1.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3). Workspace files are owned by root.
2. `tools/bin/gen` and `tools/bin/tester` are rebuilt from the committed source with Rust 1.93.0
   (the v1 compiler). They are not byte-identical to v1's binaries but behave identically: `gen`
   matches on 3,000 seeds and `tester` on 1,550 outputs (valid, corrupted and historical), and
   `gen` reproduces the 50 judge cases exactly.
3. The workspace git commit keeps v1's author, message and dates; its hash differs only because
   of the rebuilt binaries. Submissions are archived without `.git`, so grading is unaffected.
4. The eval script moved from `/tmp/eval_ahc.sh` to `/judge/eval_ahc.sh` (content unchanged).
5. If the grader prints no total score (only when `eval_ahc.sh` dies early), v1 recorded an
   unrankable score; the new grader returns `valid=false`. Empty and non-compiling submissions
   score `valid=true, 0`, as in v1.
6. `/etc/apt/sources.list` points at the dated snapshot.

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same host, interleaved, two runs
each. Raw score; 0..100 in brackets.

| Submission | Old | New |
|---|---|---|
| empty, compile error | 0 | 0 |
| starter `solution.cpp` | 826577 | 826577 |
| historical 1 (all cases WA) | 0 | 0 |
| historical 2 | 46289792011 – 46351403805 (19.63–19.65) | 46322113007 – 46339157001 (19.64–19.65) |
| historical 3 | 49176470087 – 49179153278 (67.54–67.60) | 49161147049 – 49188765059 (67.17–67.83) |
| historical 4 | 49314483824 – 49323162096 (70.81–71.01) | 49316508892 – 49321424250 (70.85–70.97) |
| historical 5 | 49673805429 – 49675480037 (79.32–79.36) | 49678261923 – 49678987894 (79.42–79.44) |

Deterministic rows match exactly, including the per-case details. The time-limited searches
differ by less than the old judge's own run-to-run spread (up to 0.7 points). An independent
second review re-judged four more historical submissions and nine adversarial ones with the
same result.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The scored cases are not hidden.** They are the generator's seeds 0..49, so the agent can
   reproduce the exact scored inputs from its workspace, although the README calls them hidden.
2. **Host-dependent score.** Limits are wall-clock with no CPU pinning, and most strong solutions
   search until the deadline, so the score moves with host speed and load (up to about 2.6 points
   between runs). Solutions close to the 5 s limit can lose cases to timeouts under load.
3. **README limits are not enforced.** The 1 GB memory limit is not applied, and a solution may
   use every host core.
4. **The file name is implicit.** The prompt asks for "a single C++ file" without naming it; only
   `solution.cpp` is submitted, so any other name scores 0 as a compile error.
5. **Stale harness wording.** The README's "~100 remote judging attempts" describes a v1 harness
   policy that this task does not enforce.
6. **The submission can tamper with grading.** Submitted code runs as root next to the grader and
   can alter its intermediate and final results. This is the cross-task issue in `tasks/SCHEMA.md`;
   the fix is to run the submission as an unprivileged user.
