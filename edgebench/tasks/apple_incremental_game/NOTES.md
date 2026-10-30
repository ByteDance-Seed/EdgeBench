# apple_incremental_game

AtCoder Heuristic Contest 058 "Apple Incremental Game", in ALE-Bench style. The agent writes
`solution.py` (stdin -> stdout): 500 turns, each either strengthening one of the 4×10 machines or
doing nothing. The judge runs it on 50 fixed cases (8 at a time, 30 s wall clock each), scores each
output with `tools/bin/tester` (`round(1e5 · log2(S))`, S = apples after T turns), and sums the
per-case scores of the `OK` cases (failed cases count 0). Raw score = that sum (maximize). The
rescale is the v1 one (`piecewise_max`, baseline 45000000).

## Source

- Workspace (READMEs, `tools/bin/{gen,tester}`, `tools/src/`) and the 50 judge cases: the task
  authors' repository (not public), identical by sha256 and mode to the published v1 images. The
  tools are Python scripts.
- `environment/workspace/solution.py` (starter) and `judge/eval_apple_incremental_game.py`:
  byte-identical to v1's inline scripts and to the published v1 images. `judge/grade.py` is new and
  writes `result.json` with v1's scoring.
- `instruction.md`: v1's prompt, verbatim. Base: `bases/python310`.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. The eval script moved from `/tmp/` to `/judge/` (content unchanged).
3. If the eval script crashes without a total score, v1 recorded an unrankable score; the new
   grader returns `valid=false`. An empty submission grades the judge's starter (which does
   nothing and scores 0), as in v1.
4. The workspace git commits are identical to v1's (same hashes).

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same host, interleaved, two runs
each (more for historical 3). Raw score per run; 0..100 in brackets.

| Submission | Old | New |
|---|---|---|
| empty (starter) | 0 | 0 |
| forged tester message (Known issue 1) | 499999950 (100) | 499999950 (100) |
| historical 1 (no time check) | 268568267 / 263017440 (38.30 / 22.02) | 274004581 / 246480484 (54.24 / 18.54) |
| historical 2 | 267026999 / 267025279 (33.78 / 33.77) | 267026999 (33.78) |
| historical 3 | 274.24–275.11 M | 273.80–275.10 M |
| historical 4 | 275780260 / 275790685 (59.44 / 59.47) | 275801664 / 275729755 (59.51 / 59.29) |
| historical 5 | 281272913 / 281176057 (75.55 / 75.26) | 281520235 / 281257464 (76.27 / 75.50) |
| historical 6 | 283184363 / 283222128 (81.10 / 81.20) | 283250477 / 283205416 (81.28 / 81.16) |

Deterministic rows match exactly. Historical 1 has no time check and loses whole cases to
timeouts depending on host load, on both images. Historical 3 uses unseeded randomness; after
extra pairs of runs, both images give overlapping ranges with means 0.05 M apart. The other
time-limited searches differ by under 1 point on 0..100.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The submission can forge its score through the tester's error message.** The eval script
   takes a score from any tester output line that looks like `Score = …` and ignores the tester's
   exit code, while the tester echoes a malformed action back in its error message. A solution can
   therefore get any score (100/100) without solving the task. A fix is to require exit code 0 and
   an anchored score line.
2. **The scored cases are reproducible.** They come from the public generator with a fixed seed
   range; the instruction limits local seeds to 0..10000, but nothing enforces it.
3. **Host-dependent score.** Limits are wall-clock with no CPU pinning; strong solutions search
   until self-chosen budgets, and solutions without a time check lose whole cases to timeouts
   depending on host speed and load (one historical submission: 3/50 cases in v1, 45–50/50 here).
4. **No judge resource limits.** The README's 1 GB memory limit is not enforced, and a solution may
   use every host core.
5. **The submission can tamper with grading.** Solutions run as root next to the grader and the
   tester (the cross-task issue in `tasks/SCHEMA.md`); issue 1 is the cheap version.
6. **Failed cases are silent zeros;** the submission stays valid.
7. **Wording.** The README says "exactly T lines", but the tester accepts extra lines, blank lines
   and comments. "Limited remote submissions" describes the v1 harness's submit loop.
