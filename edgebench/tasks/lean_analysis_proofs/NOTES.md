# lean_analysis_proofs

Lean 4 formalization task on the `analysis` project (Lean v4.28.0, Mathlib `8f9d9cf`). The agent
completes proofs in `se-bmk-intern/analysis`. The judge builds the submitted project, runs
`eval_lean.py --mode unweighted`, and counts repaired declarations. Raw score = `repaired / 2901`
(0..1, maximize). The rescale is the v1 one (`linear` 0..1 -> 0..100). This was the first Lean
task migrated; the other Lean tasks follow its recipe.

## Source

- `environment/se-bmk-intern/analysis/` (113 files) and `judge/se-bmk-intern/eval_lean.py`: the
  task authors' repository (not public), identical to the published v1 images.
- `analysis/ListDeclAxiom.lean`: the version shipped in the published v1 images (comments
  translated to English, code identical).
- Base `bases/lean-4.28.0-mathlib-8f9d9cf`: Ubuntu 22.04 (the image under v1) with apt from a dated
  snapshot, elan 4.2.2 and Lean v4.28.0 from sha256-pinned release tarballs, and a `baseline`
  project created with v1's own `lake new baseline math`, verified against v1's manifest and fully
  prebuilt. The task's `lake-manifest.json` equals the base's, so Lake reuses the base's Mathlib
  and builds only the task's modules.
- `judge/run.sh`, `judge/write_result.py`: new; they run v1's eval chain and write `result.json`.
- `instruction.md`: v1's prompt, verbatim.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. `.lake/packages` is a symlink to the base's Mathlib packages instead of a 7 GB copy; package
   sources and oleans are identical.
3. `lake-manifest.json` records the real upstream revisions (v1's images had synthetic ones from a
   post-processing step). It is the only file that differs in the workspace, so the workspace git
   commit hash differs from v1's.
4. The `elan` binary differs in bytes from v1's (same version string; the release asset was
   apparently rebuilt). The Lean toolchain is identical.
5. Best-of-run: a run whose only valid submission repaired nothing now has best 0 (v1: none).
   Build failures are invalid with no score, as in v1.

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same host. Lean grading is
deterministic. Raw score; 0..100 = 100 x raw.

| Submission | Old | New |
|---|---|---|
| empty | no score | invalid |
| historical 1, 2 (build errors) | no score | invalid |
| historical 3–6 | 0.003102, 0.170631, 0.447432, 0.918304 | same |

Scores and `eval_lean` summaries match exactly and equal the historical v1 scores.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The submission can spoof or tamper with the result.** Output printed while the submitted
   project builds is parsed before the evaluator's own result, so a one-line `#eval` can report a
   full score; build-time code also runs as root next to the grader (the cross-task issue in
   `tasks/SCHEMA.md`).
2. **Some targets are false.** Two statements in `Analysis/Section_11_8.lean` appear to be false as
   written (a historical submission machine-checked counterexamples):
   `Chapter11.f_11_8_6_RS_integ` claims the value 22 where it is 6, and
   `Chapter11.RS_integ_with_sign` fails for f = 1. These targets cannot be repaired.
3. **Fragile workspace.** Deleting `.lake/packages/mathlib` in the workspace removes the only
   Mathlib copy, which cannot be restored offline.
4. Changed or disappeared declarations score 0; there is no statement hash guard in this task.
