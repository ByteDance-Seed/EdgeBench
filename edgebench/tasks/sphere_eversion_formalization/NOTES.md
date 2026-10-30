# sphere_eversion_formalization

Lean 4 formalization task: the community sphere-eversion project (Lean v4.28.0, Mathlib
`8f9d9cf`) with its proofs replaced by `sorry`. The agent fills in proofs in
`se-bmk-intern/sphere-eversion`. The judge builds the submitted project, runs `eval_lean.py
--mode unweighted`, and counts repaired declarations. Raw score = `repaired / 661` (0..1,
maximize), or 0 (still valid) when the statement of the main theorem `Gromov` has changed. The
rescale is the v1 one (`linear` 0..1 -> 0..100). It is migrated like `lean_analysis_proofs` (same
base, same `eval_lean.py`).

## Source

- `environment/se-bmk-intern/sphere-eversion/` (96 files) and `judge/se-bmk-intern/eval_lean.py`:
  the task authors' repository (not public), identical to the published v1 images.
- `sphere-eversion/ListDeclAxiom.lean`: the version shipped in the published v1 images (comments
  translated to English; it also prints the hash of `Gromov`'s statement that the judge checks).
- Base `bases/lean-4.28.0-mathlib-8f9d9cf`: the task's `lake-manifest.json` equals the base's, so
  Lake reuses the base's Mathlib and builds only SphereEversion.
- `judge/run.sh`, `judge/write_result.py`: new; they run v1's eval chain and write `result.json`.
- `instruction.md`: v1's prompt, verbatim.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. `.lake/packages` is a symlink to the base's Mathlib packages instead of a copied directory; the
   package contents are identical.
3. `lake-manifest.json` records the real upstream revisions (v1 had synthetic ones); Mathlib
   content is identical. This is the only file that differs in the workspace, so the workspace git
   commit hash differs from v1's.
4. Best-of-run: a run whose only valid submission scores 0 now has best 0 (v1: none). Build
   failures are invalid with no score, as in v1.

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same host. Lean grading is
deterministic. Raw score; 0..100 = 100 x raw.

| Submission | Old | New |
|---|---|---|
| empty | no score | invalid |
| historical 1 (build fails) | no score | invalid |
| historical 2–6 | 0.069592, 0.400908, 0.488654, 0.665658, 0.928896 | same |
| changed `Gromov` statement (synthetic) | 0 | 0 |

All scores and `eval_lean` summaries match exactly and equal the historical v1 scores. No
historical submission triggered the `Gromov` check, hence the synthetic case.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The submission can spoof or tamper with the result.** The judge builds the submitted project
   before adding its own checker, so code that runs during the build (for example `#eval`) runs as
   root and can print a fake result or alter the grader (the cross-task issue in
   `tasks/SCHEMA.md`).
2. **Only `Gromov`'s statement is hash-guarded.** Other statements are checked per declaration and
   only when their printed type changes, so definitions outside `Gromov`'s closure can still be
   altered.
3. **Contamination.** The upstream sphere-eversion project is complete and public, so models may
   have memorized the proofs, and the workspace's `blueprint/` contains the informal proofs.
4. **Fragile workspace.** Deleting `.lake/packages/mathlib` in the workspace removes the only
   Mathlib copy, which cannot be restored offline (v1 had a second copy).
