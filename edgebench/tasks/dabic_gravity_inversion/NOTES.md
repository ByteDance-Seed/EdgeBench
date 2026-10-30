# dabic_gravity_inversion

The agent ports the D-ABIC regularization-parameter method (Song Han et al. 2025, Geophysics) to
3D gravity inversion in SimPEG, validates it on a synthetic model and on the Vinton salt dome field
data under L0 and L1 sparse norms, and compares it with Cooling, L-curve and Xu et al.'s 2025 HMC
result. It delivers `outputs/` (`dabic_directive.py`, `run_synthetic.py`, `run_vinton.py`,
`results.json`, `report.md`). The judge runs `eval_dabic_v2.py` (100 points): a static scan of the
directive (3), synthetic metrics from `results.json` (12), twelve small hidden SimPEG inversions
that run the submitted `DABIC_Beta_Estimator` (35), Vinton metrics from `results.json` (30), a
behaviour fingerprint captured during the hidden runs (8), and keyword counts in `report.md` (12);
`total = raw_total × penalty` (0.334, 0.5 or 1.0 by thresholds). `valid` requires that beta was
really updated with a proper log-determinant routine. Raw score = `total` (0..100, maximize). v1
defined no rescale, so none is set.

## Source

- Task data, the two papers (PDF) and the Chinese starter files under
  `environment/task_files/` (also installed at `/opt/dabic_task_files/`, as in v1), and the judge's
  `eval_dabic_v2.py`: the task authors' archives (not public), identical by sha256 to the published
  v1 images.
- `environment/workspace/starter/*`: the English versions shipped in the published v1 work image
  (only comments, prints and prose differ).
- `environment/requirements.lock`: the 18 package versions in the published images, hash-pinned
  from PyPI; simpeg 0.25.2 and pymatsolver 0.4.0 exist only as sdists and are built with the exact
  build backend v1 used (`environment/build-requirements.lock`), giving byte-identical results.
  Base: `bases/python`.
- `judge/run.sh`, `judge/emit_result.py`: new; they run v1's eval command verbatim and write
  `result.json` with v1's structured-result logic.
- `instruction.md`: v1's prompt, verbatim.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. Pinned Python dependencies; no pip cache in the images.
3. An unused duplicate of the grader (with stray bytecode) in v1's judge image is not shipped.
4. **Two unrankable cases change form.** A grader crash before the result (for example
   `results.json` is a JSON list) and a NaN total were valid-but-unrankable in v1; they are now
   `valid=false`. NaN or infinite values inside details are written as null so `result.json` is
   strict JSON.
5. The workspace git commit is identical to v1's (same hash).

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same host, interleaved, 2–4 runs
per side. Raw score (no rescale).

| Submission | Old | New |
|---|---|---|
| empty archive | 0 (invalid) | 0 (invalid) |
| `results.json` = `[1, 2]` | no score (valid) | invalid (Deviation 4) |
| historical 1 | 0 (invalid) | 0 (invalid) |
| historical 2 (NaN metric) | NaN (valid) | invalid (Deviation 4) |
| historical 3 | 7.18–7.48 (invalid) | 7.23–7.54 (invalid) |
| historical 4 | 8.99–9.04 | 8.99–9.05 |
| historical 5 | 15.62–15.65 | 15.62–15.64 |
| historical 6 | 18.38–18.40 | 18.39–18.42 |

Old and new ranges overlap on every row with the same spread (at most 0.3), and the historical v1
values sit inside or next to them. The noise is in the grader itself (Known issue 3), not timing.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **42 of 100 points are self-reported.** The synthetic (12) and Vinton (30) components are read
   from numbers the agent writes into `results.json`; nothing re-runs the scripts or checks them.
2. **The submitted directive runs inside the grader process,** so its module-level code can change
   the grader's own scoring functions; the submission also runs as root next to the grader (the
   cross-task issue in `tasks/SCHEMA.md`).
3. **Nondeterministic hidden component.** The hidden runs use an unseeded estimator, so the same
   submission scores differently per run (up to 0.3 points).
4. **NaN and malformed results.** A NaN metric makes the total NaN (unrankable), and malformed
   `results.json` types crash the grader.
5. **The report score is keyword counting,** and its length bands do not match the instruction's
   "800 to 1500 words/characters".
6. **The "pure D-ABIC" check is a regex** on the directive source, so certain identifiers lose the
   point regardless of what the code does.
7. An empty submission is `valid=false`, score 0 (rejected rather than scored 0).
8. **Read-only starter files are writable.** The instruction forbids modifying them, and v1 made
   them read-only, but the published image's versions are writable. The grader never reads them.
9. The original Chinese task files are visible to the agent in `/opt/dabic_task_files/`; they
   contain no hidden data.
