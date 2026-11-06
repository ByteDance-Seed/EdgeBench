# borden_source_inversion

Borden-style 3D groundwater contaminant source inversion. The agent writes `answer.json` (a
finite-duration rectangular-region source plus a description of its transport model). The judge
runs `scoring/evaluate.py`, which predicts concentrations at hidden wells and hidden future times
with a closed-form advection-dispersion forward model and scores the fit (relative RMSE and
log-RMSE), plus small capped format, bounds and method points, with quality caps.
Raw score = `total_score` (0..100 by construction, maximize). v1 defined no rescale, so none is set.

## Source

- Workspace (README, starter `answer.json`, template, baseline solver, grid, public data and
  config) and the judge's `scoring/` (evaluator, hidden forward model, hidden wells, readings and
  the true source): the task authors' public and private data bundles (not public), identical by
  sha256 to the published v1 images.
- `environment/requirements.lock`: the 30 package versions v1's unpinned install resolved to,
  hash-pinned wheels from PyPI. Base: `bases/python310`.
- `judge/run.sh`, `judge/emit_result.py`: new; they run v1's eval command verbatim and write
  `result.json` with v1's structured-result logic.
- `instruction.md`: v1's prompt, verbatim.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. Python dependencies are pinned to the versions v1 resolved (numpy 2.2.6, pandas 2.3.3, scipy
   1.15.3, matplotlib 3.10.9, pymoo 0.6.1.6, …). The workspace `requirements.txt` the agent sees
   still has v1's `>=` ranges.
3. If the evaluator crashes before printing a score (for example `answer.json` is a JSON list),
   v1 recorded an unrankable score; the new grader returns `valid=false`. A missing or unparsable
   `answer.json` scores `valid=true, 0`, as in v1.
4. The workspace git commit is identical to v1's (same hash).

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same host, interleaved, two runs
each. The grader is deterministic. Raw score (= 0..100).

| Submission | Old | New |
|---|---|---|
| empty archive | 7.012 | 7.012 |
| unparsable `answer.json` | 0 | 0 |
| `answer.json` = `[1, 2]` | no score (valid) | no score (invalid), Deviation 3 |
| historical 1–6 | 7.091, 7.627, 15.279, 27.62, 41.612, 88.602 | same |

Every scored row matches exactly, including the summaries with the hidden and future fit errors,
and matches the historical v1 scores.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The submission controls the judge's forward-model configuration.** The judge reads the
   public problem config, prior, wells and monitoring data from the submission directory, and the
   hidden forward model takes its hydrogeological parameters, grid and source discretization from
   that config. Changing them changes the score, and the bounds checks can be widened the same
   way. A fix is to read these files from a judge-owned copy.
2. **An empty submission scores 7.012, not 0.** The judge image contains the baseline
   `answer.json`, so a submission without one is graded as the baseline, although the instruction
   says a missing `answer.json` scores zero.
3. **Bounds are only lightly enforced.** An out-of-bounds answer loses at most the bounds points
   (1 after caps); the forward model uses the values as given.
4. **Easy points from file presence.** Any extra `*.py` file and a report file earn method and
   workflow points (capped at 1). The forbidden-access scan only adds warnings.
5. **Missing helper.** The instruction recommends `validate_answer.py if available`; none is
   shipped.
6. **Crash = unrankable.** Valid JSON that is not an object crashes the evaluator (Deviation 3).
7. **Hidden data next to the submission.** The judge's working directory holds the hidden
   scoring data. The grader never executes submitted code, so this is not exploitable through the
   judge; the layout is v1's.
