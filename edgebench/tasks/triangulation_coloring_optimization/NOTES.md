# triangulation_coloring_optimization

CodeChef TRICOL, in ALE-Bench style. The agent writes `solution.py` (stdin -> stdout). The judge
runs it on 10 fixed N=512 cases (8 at a time, 30 s wall clock each), scores each output with
`tools/bin/tester` (G = X·C + Y·F + U²), and sums the per-case scores. If any case is not `OK` the
total is `inf`. Raw score = that sum (minimize). The rescale is the v1 one (`piecewise_log_min`).

## Source

- Workspace (README, sample data and its eval script, `tools/bin/tester`, `tools/src/`) and the 10
  judge cases: the task authors' repository (not public), identical by sha256 and mode to the
  published v1 images. The tester is a Python script.
- `environment/workspace/solution.py` (starter) and `judge/eval_triangulation_coloring.py`:
  byte-identical to v1's inline scripts and to the published v1 images. `judge/grade.py` is new and
  writes `result.json` with v1's scoring.
- `instruction.md`: v1's prompt, verbatim. Base: `bases/python310`.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. The eval script moved from `/tmp/` to `/judge/` (content unchanged).
3. **`inf` becomes invalid.** When any case fails, v1 reported score `inf`, which was not rankable;
   the new grader returns `valid=false`. Same ranking effect. An empty submission grades the
   judge's starter `solution.py`, as in v1.
4. The workspace git commits are identical to v1's (same hashes).

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same host, interleaved, two runs
each. Raw score per run; 0..100 in brackets.

| Submission | Old | New |
|---|---|---|
| empty (starter) | 6092430 (0.06) | 6092430 (0.06) |
| historical 1 (all runtime errors) | `inf` (not rankable) | invalid |
| historical 2 | 290889 / 288823 (72.05 / 72.20) | 289427 / 295495 (72.15 / 71.71) |
| historical 3 | 855390 / 730338 (49.14 / 52.49) | 740629 / 859437 (52.20 / 49.04) |
| historical 4 | 416773 / 441372 (64.41 / 63.19) | 420013 / 421459 (64.24 / 64.17) |
| historical 5 | 296939 / 295719 (71.61 / 71.70) | 298881 / 302496 (71.47 / 71.22) |
| historical 6 | 238803 / 243421 (76.24 / 75.83) | 241564 / 244939 (75.99 / 75.70) |
| historical 7 | 234893 / 235207 (76.59 / 76.56) | 234831 / 235163 (76.59 / 76.56) |

The deterministic starter matches exactly. For the time-limited searches, old and new differ by
less than the old judge's own run-to-run spread.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The hidden cases are reproducible.** The generator is in the workspace and the sample-data
   README states where the judge seeds start, so an agent can regenerate the exact scored inputs.
   The instruction forbids calling the generator, but nothing enforces it.
2. **Host-dependent score.** Limits are wall-clock with no CPU pinning, and strong solutions search
   until a self-chosen deadline (some with `multiprocessing`), so scores move with host speed and
   load.
3. **One failed case makes the whole submission unrankable,** including a timeout caused by host
   load; one historical submission was `inf` in v1 but passed all cases in four re-runs.
4. **No judge resource limits.** The problem's 512 MiB memory limit is not enforced, and a solution
   may use every host core.
5. **The submission can tamper with grading.** Solutions run as root next to the grader and the
   tester (the cross-task issue in `tasks/SCHEMA.md`).
6. **The `task.toml` description is inaccurate.** It calls ugly triangles "monochromatic"; the
   statement defines them as having at least two vertices of the same color.
7. The instruction's "submit when promising" describes the v1 harness's submit loop.
