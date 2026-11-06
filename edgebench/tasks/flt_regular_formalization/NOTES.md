# flt_regular_formalization

Lean 4 formalization task: the public `flt-regular` project (leanprover-community, Apache-2.0)
with proofs removed, on Lean v4.28.0 and Mathlib `8f9d9cf`. The agent completes the proofs in
`se-bmk-intern/FltRegular`. The judge builds the submitted project and runs `eval_lean.py --mode
weighted` with `task/FltRegular_weight.json`, which defines 25 target declarations and their
expected types (total weight 87, weights 1–6). A target scores its weight if it uses only the
standard axioms and keeps its type; the score becomes 0 if the statement of `flt_regular` changed.
Raw score = `repaired_weight / 87` (0..1, maximize). The rescale is the v1 one (`linear` 0..1 ->
0..100). Migrated like `lean_analysis_proofs` (same base, same `eval_lean.py`).

## Source

- `environment/se-bmk-intern/FltRegular/` (33 files), `judge/se-bmk-intern/eval_lean.py` and
  `judge/se-bmk-intern/task/FltRegular_weight.json`: the task authors' repository (not public),
  identical to the published v1 images.
- `FltRegular/ListDeclAxiom.lean` and `FltRegular/README.md`: the English versions shipped in the
  published v1 images (code identical).
- Base `bases/lean-4.28.0-mathlib-8f9d9cf`: the task's `lake-manifest.json` equals the base's, so
  Lake reuses the base's Mathlib and builds only FltRegular.
- `judge/run.sh`, `judge/write_result.py`: new; they run v1's eval chain and write `result.json`.
- `instruction.md`: v1's prompt, verbatim.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. `.lake/packages` is a symlink to the base's Mathlib packages instead of a 7 GB copy.
3. `lake-manifest.json` records the real upstream revisions (v1 had synthetic ones); Mathlib
   content is identical. It is the only file that differs in the workspace, so the workspace git
   commit hash differs from v1's.
4. The judge image no longer prebuilds its own copy of FltRegular, which v1's eval never used.
5. Build failures are invalid with no score, as in v1; best-of-run equals v1's.

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same host, one run each. The grader
is deterministic. Raw score; 0..100 = 100 x raw.

| Submission | Old | New |
|---|---|---|
| empty | no score | invalid |
| historical 1 (build error) | no score | invalid |
| historical 2–4 | 0.034483, 0.436782, 0.505747 | same |
| historical 5, 6 | 1.0 | 1.0 |

All scores and per-declaration summaries match exactly and equal the historical v1 scores.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The submission can spoof or tamper with the result.** Output printed while the submitted
   project builds is parsed before the evaluator's own result, and code that runs during the build
   (for example `#eval`) runs as root next to the grader (the cross-task issue in
   `tasks/SCHEMA.md`).
2. **Public solutions exist.** The full proofs are in the public `flt-regular` repository; two of
   six sampled historical submissions score 100.
3. **Unclear README wording.** It says auxiliary lemmas "must not contain full proofs and must not
   leave sorry" (faithful to the Chinese original); it presumably means they must be fully proved.
4. **Fragile workspace.** Deleting `.lake/packages/mathlib` in the workspace removes the only
   Mathlib copy.
5. **Only the 25 named declarations count**, and only `flt_regular` has a statement hash guard;
   other targets are protected only by their type text.
