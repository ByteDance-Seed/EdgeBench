# treant_forest

AtCoder Heuristic Contest 054 "Treant's Forest", adapted to batch mode in ALE-Bench style. The
agent writes `solution.py`. The judge runs `python3 solution.py` on 50 fixed cases (at most 8 in
parallel, 120 s wall clock each), replays each output with `tools/bin/tester`, and sums the
per-case scores (turns taken by the adventurer) of the `OK` cases. Raw score = that sum
(maximize). The rescale is the v1 one (`piecewise_max`).

## Source

- Workspace (READMEs, `tools/bin/{gen,tester}`, `tools/src/`) and the 50 judge cases: the task
  authors' repository (not public), identical by sha256 and mode to the published v1 images.
  `gen` and `tester` are Python scripts.
- `environment/workspace/solution.py` (starter) and `judge/eval_treants_forest.py`: byte-identical
  to v1's inline scripts and to the published v1 images. `judge/run.sh` is new and writes
  `result.json` with v1's scoring.
- `instruction.md`: v1's prompt, verbatim. Base: `bases/python310`.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. The eval script moved from `/tmp/` to `/judge/` (content unchanged).
3. If the eval script dies without a total score, v1 recorded an unrankable score; the new grader
   returns `valid=false`. An empty submission grades the judge's starter `solution.py` (3418), as in
   v1.
4. The workspace git commits are identical to v1's (same hashes).

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same host, interleaved, two runs
each. Raw score; 0..100 in brackets.

| Submission | Old | New |
|---|---|---|
| empty (starter) | 3418 | 3418 |
| wrong output, historical 1 (all runtime errors) | 0 | 0 |
| historical 2 | 23467 (4.37) | 23467 |
| historical 3 | 68122 / 68050 (15.15 / 15.14) | 67899 / 68122 (15.10 / 15.15) |
| historical 4 | 77067 / 76925 (17.31 / 17.28) | 77103 / 77122 (17.32 / 17.33) |
| historical 5 | 91925 / 91999 (20.93 / 20.94) | 91946 / 91996 (20.93 / 20.94) |

Deterministic rows match exactly, including summaries. The time-bounded submissions differ by at
most 0.05 points on 0..100, within the run-to-run spread of either image.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **Undocumented turn cap: the task saturates at 21/100.** The tester stops each replay at
   `2·N²` turns, which no document mentions, so the raw score cannot exceed 92304 (21.02 on 0..100).
   The rescale anchors (rank 1 = 330195) are unreachable, and the top of the leaderboard cannot be
   separated; one historical submission already hits the cap on every case.
2. **The "random" destinations are given to the solution.** Each input contains the full
   destination list, so the adventurer is deterministic, although the README says its choice is
   random.
3. **The scored cases are reproducible.** They come from the public generator with a fixed seed
   range; the instruction asks agents to use seeds 0..10000 only, but nothing enforces it.
4. **Time and memory wording.** The README says 60 s per case and 1 GB; the judge allows 120 s
   wall clock and enforces no memory limit. Cases run 8 in parallel with no CPU pinning, so
   time-bounded solutions depend on host speed and load.
5. **Empty submission = starter.** Without `solution.py` the judge grades its own starter (3418);
   the rescale baseline (5369) comes from a different baseline, and both map to 0.
6. Wrong answers, crashes and timeouts are per-case zeros; a crash on every case is `valid=true, 0`.
7. **The submission can tamper with grading.** Solutions run as root next to the grader, the cases
   and the tester (the cross-task issue in `tasks/SCHEMA.md`).
8. **The `task.toml` description is wrong.** It (from v1's task list) mentions blocking the path,
   which is a wrong answer; the score is the adventurer's turn count.
9. The README's "~100 remote submissions" is a v1 harness policy, not enforced by the task.
