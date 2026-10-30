# grid_turing_robot

AtCoder Heuristic Contest 056 "Grid Turing Robot", in ALE-Bench style. The agent writes
`solution.py` (stdin -> stdout) that prints an initial board coloring and a transition table for a
Turing-machine-style robot that must visit K destinations in order within T steps. The judge runs
it on 50 fixed cases (8 at a time, 30 s wall clock each), scores each output with
`tools/bin/tester` (C + Q if every destination is visited, else 2N⁴ + (K − V)·N²), and sums the
per-case scores. If any case is not `OK` the total is `inf`. Raw score = that sum (minimize). The
rescale is the v1 one (`piecewise_min`).

## Source

- Workspace (READMEs, `tools/bin/{gen,tester}`, `tools/src/`) and the 50 judge cases: the task
  authors' repository (not public), identical by sha256 and mode to the published v1 images. The
  tools are Python scripts.
- `environment/workspace/solution.py` (starter) and `judge/eval_grid_turing_robot.py`:
  byte-identical to v1's inline scripts and to the published v1 images. `judge/grade.py` is new and
  writes `result.json` with v1's scoring.
- `instruction.md`: v1's prompt, verbatim. Base: `bases/python310`.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. The eval script moved from `/tmp/` to `/judge/` (content unchanged).
3. **`inf` becomes invalid.** When any case fails, v1 reported score `inf`, which was not rankable;
   the new grader returns `valid=false`. Same ranking effect. An empty submission grades the
   judge's starter `solution.py` (7744909), as in v1.
4. The workspace git commits are identical to v1's (same hashes).

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same host, interleaved, two runs
each. Raw score; 0..100 in brackets.

| Submission | Old | New |
|---|---|---|
| empty (starter) | 7744909 (2.84) | same |
| historical 1 (all runtime errors) | `inf` (not rankable) | invalid |
| historical 2–4 | 4151 (26.98), 3713 (35.99), 3024 (50.17) | same |
| historical 5 | 2941 / 2939 (51.88 / 51.92) | 2940 / 2938 (51.90 / 51.95) |
| historical 6 | 2289 / 2292 (65.30 / 65.24) | 2292 / 2288 (65.24 / 65.32) |

Deterministic submissions match exactly, and summaries are identical on every run. The two
time-budgeted searches differ by no more than the old judge's own spread (about 0.1 points).

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The scored cases are reproducible.** They come from the public generator with a fixed seed
   range; the instruction says to use seeds 0..10000 only, but nothing enforces it.
2. **Host-dependent score.** Limits are wall-clock with no CPU pinning, and strong solutions search
   until self-chosen deadlines, so scores move with host speed and load.
3. **One failed case makes the whole submission unrankable,** including a timeout caused by host
   load.
4. **No judge resource limits.** The README's 512 MB memory limit is not enforced, and a solution
   may use every host core.
5. **The rescale baseline is worse than the starter.** The baseline score comes from a different
   reference solution, so the shipped starter, which does nothing, already scores 2.84/100.
6. The README says to output only rules that occur during simulation; the verifier does not check
   this (no effect on the score).
7. **The submission can tamper with grading.** Solutions run as root in the judge workspace, next
   to the cases and the tester (the cross-task issue in `tasks/SCHEMA.md`).
8. **The `task.toml` description is inaccurate.** It (from v1's task list) describes maximizing
   distinct visited cells; the objective is to visit the K destinations in order while minimizing
   colors plus states.
9. The README's "~100 remote submissions" describes the v1 harness's submit loop.
