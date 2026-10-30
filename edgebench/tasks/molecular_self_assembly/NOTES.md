# molecular_self_assembly

AtCoder Heuristic Contest 057 "Molecules", in ALE-Bench style. The agent writes `solution.py`
(stdin -> stdout). The judge runs it on 50 fixed cases (8 at a time, 30 s wall clock each), scores
each output with `tools/bin/tester` (`round(1e6 * log2(L·(N−M) / (D_sum+1)))`), and sums the
per-case scores of the `OK` cases (failed cases count 0). Raw score = that sum (maximize). The
rescale is the v1 one (`piecewise_max`).

## Source

- Workspace (READMEs, `tools/bin/{gen,tester}`, `tools/src/`) and the 50 judge cases: the task
  authors' repository (not public), identical by sha256 and mode to the published v1 images. The
  tools are Python scripts.
- `environment/workspace/solution.py` (starter) and `judge/eval_molecules.py`: byte-identical to
  v1's inline scripts and to the published v1 images. `judge/grade.py` is new and writes
  `result.json` with v1's scoring.
- `instruction.md`: v1's prompt, verbatim. Base: `bases/python310`.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. The eval script moved from `/tmp/` to `/judge/` (content unchanged).
3. If the eval script crashes without a total score, v1 recorded an unrankable score; the new
   grader returns `valid=false`. An empty submission grades the judge's starter `solution.py`, as
   in v1.
4. The workspace git commits are identical to v1's (same hashes).

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same host, interleaved, two runs
each. Raw score per run; 0..100 in brackets.

| Submission | Old | New |
|---|---|---|
| empty (starter) | 69280072 (0.01) | 69280072 (0.01) |
| historical 1 (no output, all cases fail) | 0 | 0 |
| historical 2 | 228952171 / 233649432 (19.27 / 19.83) | 233649432 (19.83) |
| historical 3 | 237575103 / 237534238 (22.34 / 22.30) | 237424836 / 237468750 (22.20 / 22.24) |
| historical 4 | 256848902 / 256764090 (40.09 / 40.01) | 256656555 / 256718945 (39.91 / 39.97) |
| historical 5 | 269124668 (51.40) | 269124668 (51.40) |
| historical 6 | 278482300 / 278320969 (60.01 / 59.86) | 278590122 / 278426666 (60.11 / 59.96) |

Deterministic rows match exactly, including summaries. Historical 2 has no time check and once
lost a case to a timeout on the old judge under heavy load. For the time-limited searches, old and
new differ by less than the old judge's own spread (about 0.1 points).

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The scored cases are reproducible.** They come from the public generator with a fixed seed
   range; the instruction limits local seeds to 0..10000, but nothing enforces it, so an agent that
   finds the seeds can tune on the exact inputs.
2. **Host-dependent score.** Limits are wall-clock with no CPU pinning. Strong solutions search
   until a self-chosen budget, and solutions without a time check lose whole cases to timeouts
   depending on host speed and load.
3. **No judge resource limits.** The README's 1 GB memory limit is not enforced, and a solution may
   use every host core.
4. **The submission can tamper with grading.** Solutions run as root next to the grader and the
   tester, while other cases write their outputs to predictable paths (the cross-task issue in
   `tasks/SCHEMA.md`). (Not tested.)
5. **Failed cases are silent zeros.** A submission that times out on some cases still ranks.
6. The README's "limited remote submissions" describes the v1 harness's submit loop.
