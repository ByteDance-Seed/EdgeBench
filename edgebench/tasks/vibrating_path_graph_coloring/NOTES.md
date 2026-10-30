# vibrating_path_graph_coloring

CodeChef VBR "Vibrating Path", in ALE-Bench style. The agent writes `solution.py`. The judge runs
`python3 solution.py` on 50 fixed cases (8 at a time, 30 s wall clock each), scores each output
with `tools/bin/tester` (the sum of the costs of the hit vertices) and sums the per-case scores.
Any case that is not `OK` makes the total `inf`. Raw score = that sum (minimize). The rescale is
the v1 one (`piecewise_log_min`).

## Source

- Workspace (READMEs, `tools/bin/{gen,tester}`, `tools/src/`) and the 50 judge cases: the task
  authors' repository (not public), identical by sha256 and mode to the published v1 images.
- `environment/workspace/solution.py` (starter) and `judge/eval_vibrating_path.py`: byte-identical
  to v1's inline scripts and to the published v1 images. `judge/grade.py` is new and writes
  `result.json` with v1's scoring logic.
- `instruction.md`: v1's prompt, verbatim. Base: `bases/python310`.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. The eval script moved from `/tmp/` to `/judge/` (content unchanged).
3. **`inf` becomes invalid.** When any case is not `OK` (including the empty submission and the
   starter, which is wrong on every case), v1 reported score `inf`, which was not rankable; the
   new grader returns `valid=false`. Same ranking effect.
4. The workspace git commits are identical to v1's (same hashes).

## Regression summary

Old (published v1 judge) and new judge on the same submissions, run concurrently on the same host,
two rounds. Raw score per run; 0..100 in brackets.

| Submission | Old | New |
|---|---|---|
| empty, starter, historical 1 | `inf` (not rankable) | invalid |
| historical 2 | 9218714 / 6266448 (10.82 / 14.26) | 8671710 / 6439089 (11.36 / 14.01) |
| historical 3 | 3073737 / 3061788 (29.88 / 30.45) | 3070956 / 3062192 (30.01 / 30.43) |
| historical 4 | 3006074 (33.13) | 3006074 (33.13) |
| historical 5 | 2896248 (38.57) | 2896248 (38.57) |
| historical 6 | 2761546 / 2757414 (45.54 / 45.76) | 2759417 / 2756819 (45.65 / 45.79) |

Deterministic submissions match exactly and equal the historical v1 scores. The time-budgeted
searches differ by less than the old judge's own run-to-run spread; historical 2 is very
load-sensitive, but old and new run side by side agree within 6%.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The scored cases are reproducible.** They come from the public generator with a fixed seed
   range; the instruction says to use seeds 0..10000 only, but nothing enforces it, so an agent
   that finds the seeds can tune on the exact inputs.
2. **All or nothing.** One wrong, crashing or timed-out case makes the whole submission
   unrankable.
3. **Host-dependent score.** Limits are wall-clock with no CPU pinning, and strong solutions search
   for a fixed time budget, so scores move with host speed and load, and a timeout on a loaded
   host voids the whole submission (issue 2).
4. **The `task.toml` description does not match the task.** It (from v1's catalogue) describes
   penalties for removed and monochromatic edges, while the task requires a valid coloring after
   hits and scores only the hit costs.
5. **The vibrating-path rule is defined only by the tester.** The README describes it loosely; the
   exact rule lives in `tools/bin/tester` (visible to the agent) and may differ from the original
   CodeChef problem.
6. **`tools/src/verifier.py` is not the tester.** It only sums hit costs, but both READMEs present
   it as the tester source.
7. **The submission can tamper with grading.** `solution.py` runs as root next to the grader (the
   cross-task issue in `tasks/SCHEMA.md`). (Not tested.)
8. **Stale or unenforced README rules.** "Limited remote submissions" is a v1 harness policy, and
   the 1 GB memory limit is not enforced.
