# wireless_electricity_layout

CodeChef WIREL "Wireless Electricity", in ALE-Bench style. The agent writes `solution.cpp`. The
judge compiles it with `g++ -std=c++17 -O2`, runs it on 50 fixed cases (5 s wall clock each, two
at a time), scores each output with `tools/bin/tester` (`Score = P + Q`), and sums the per-case
scores; a case that is not `OK` adds a penalty of 1e17. Raw score = that sum (minimize). The
rescale is the v1 one (`piecewise_log_min`).

## Source

- Workspace (README, starter `solution.cpp`, generator and tester sources) and the judge's
  `eval_wirel.sh` and `generate_cases.sh`: the task authors' repository (not public), identical by
  sha256 to the published v1 images.
- `judge/cases/` (50 cases, 10 MB): the output of `generate_cases.sh`, which v1 ran at build time;
  identical to the published judge image and regenerated identically with the new generator.
- `tools/bin/{gen,tester}` are built in the Dockerfiles with v1's command and come out
  byte-identical to v1's binaries.
- `judge/run.sh`: new; it runs `eval_wirel.sh` and writes `result.json` with v1's scoring.
- `instruction.md`: v1's prompt, verbatim. Base: `bases/cpp`.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. The eval script moved from `/tmp/` to `/judge/` (content unchanged); `generate_cases.sh` is kept
   for provenance but not installed (its output is committed).
3. If the eval script dies without a total score, v1 recorded an unrankable score; the new grader
   returns `valid=false`. Compile errors and a missing `solution.cpp` score `1e17`, as in v1.
4. v1 parsed the score as a float, rounding sums above 2^53; `result.json` carries the exact
   integer. The 0..100 value is the same.
5. The judge image no longer has the unused git commit v1 made in its workspace. The work-image
   commit is identical to v1's (same hash).

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same shared host, interleaved,
two or more runs each. Raw score; 0..100 in brackets.

| Submission | Old | New |
|---|---|---|
| empty (grades the starter) | 6.631007e17 (0) | 663100735542396309 (0) |
| compile error (synthetic), historical 1 (compile error) | 1e17 (0) | 1e17 (0) |
| historical 2 | 3652337368022970 (16.61) | same |
| historical 3 | 2.79265e15 (18.88) | same |
| historical 4 | 2.79548e15 (18.87) x2 | 2.79548e15 (18.87); 2.02684e17 (0, 2 timeouts) |
| historical 5 | 2.78685e15 (18.89); 3.10e18, 3.80e18 (0, many timeouts under load) | 5.03e17, 3.60e18, 4.00e18 (0, timeouts under load) |

Deterministic rows and every case that finishes in time match exactly. Historical 3–5 run about
4.2–4.6 s per case, just under the limit, so their totals depend only on how many cases time out
under host load, on both judges alike. The compiled solution and runtime libraries are
byte-identical in both images.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **A compile error beats many real solutions.** A compile error scores a single 1e17, while each
   failed case of a compiled solution adds 1e17 and the starter scores 6.6e17. All of these rescale
   to 0, so 0..100 scores are unaffected, but raw-score ranking is.
2. **Empty submission = starter.** A submission without `solution.cpp` is graded as the starter.
3. **Host-dependent score.** Limits are wall-clock (5 s per case, 10 s for the tester) with no CPU
   pinning, so solutions near the limit change score with host speed and load; a timeout costs 1e17.
4. **No judge resource limits.** The README's 1 GB memory limit is not enforced, and a solution may
   use every host core.
5. **The submission can tamper with grading.** The solution runs as root next to the per-case result
   files the eval script trusts and next to the final result (the cross-task issue in
   `tasks/SCHEMA.md`). (Not tested here.)
6. **Wording.** "Wire lengths: L in {8000, …, 16000}" is a per-case coordinate bound, not a length,
   and the README's baseline hint holds only conditionally.
7. The judge seeds are in `judge/generate_cases.sh`, public with the task directory like all
   hidden tests.
