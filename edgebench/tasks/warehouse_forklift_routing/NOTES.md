# warehouse_forklift_routing

CodeChef WAREHOUS, in ALE-Bench style. The agent writes `solution.py` (stdin -> stdout). The
judge runs it on 50 fixed inputs (each with T=5 grids, 6 ≤ R, C ≤ 20), 8 at a time with a 60 s
wall-clock limit each, scores each output with `tools/bin/tester` (the average over the 5 grids of
`(S+2)/(R+C−1) − 2RC + 20`, S = command length, printed with one decimal), and sums the 50
per-input scores. If any input is not `OK` the total is `inf`. Raw score = that sum (minimize).
The rescale is the v1 one (`piecewise_log_min`).

## Source

- Workspace (READMEs, `tools/bin/{gen,tester}`, `tools/src/`) and the 50 judge inputs: the task
  authors' repository (not public), identical by sha256 and mode to the published v1 images. The
  tools are Python scripts.
- `environment/workspace/solution.py` (starter) and `judge/eval_warehouse_manager.py`:
  byte-identical to v1's inline scripts and to the published v1 images. `judge/grade.py` is new and
  writes `result.json` with v1's scoring.
- `instruction.md`: v1's prompt, verbatim. Base: `bases/python310`.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. The eval script moved from `/tmp/` to `/judge/` (content unchanged).
3. **`inf` becomes invalid.** When any input fails (including the empty submission, whose starter
   prints empty lines), v1 reported score `inf`, which was not rankable; the new grader returns
   `valid=false`. Same ranking effect.
4. The workspace git commits are identical to v1's (same hashes).

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same host, interleaved, two runs
each. Raw score; 0..100 in brackets. The best of 310 historical submissions is 2439.8 (13.41), so
no submission covers the upper range.

| Submission | Old | New |
|---|---|---|
| empty, historical 1 (all runtime errors) | `inf` (not rankable) | invalid |
| historical 2 | 15834.7 (2.29) | same |
| historical 3 | 16782.7 (1.94) | same |
| historical 4 | 10773.3 (4.58) | same |
| historical 5 | 4491.5 / 4493.3 (9.78) | 4491.5 (9.78) |
| historical 6 | 2439.8 (13.41) | same |

Deterministic submissions give bit-identical scores. Historical 5 is a time-budgeted search and
moves slightly between runs. Historical 2 was `inf` in v1 (one input timed out) but passed every
input in all four runs here, so that timeout depended on host load.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The scored inputs are reproducible.** They come from the public generator with a fixed seed
   range; the instruction says to use seeds 0..10000 only, but nothing enforces it.
2. **Time limit mismatch.** The instruction and README say 30 s per test case; the judge allows
   60 s per input (5 test cases), and the tester gets its own 30 s.
3. **Host-dependent score.** Inputs run 8 in parallel with no CPU pinning, so time-budgeted
   searches score differently with host speed and load, and a slow host can turn a near-limit
   solution into a timeout.
4. **One failed input makes the whole submission unrankable**, including a timeout caused by host
   load.
5. **No judge resource limits.** The instruction's 1 GB memory limit is not enforced.
6. Per-input scores are rounded to one decimal before summing.
7. The score parser does not accept negative numbers; no real submission comes close, so this is
   theoretical.
8. **The submission can tamper with grading.** Solutions run as root next to the grader and the
   tester (the cross-task issue in `tasks/SCHEMA.md`).
9. **The starter does not pass.** The instruction calls `solution.py` a baseline to improve, but it
   prints empty lines that the tester rejects.
