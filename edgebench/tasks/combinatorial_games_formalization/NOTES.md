# combinatorial_games_formalization

Lean 4 formalization task: the public Lean project "Combinatorial games" (Apache-2.0) with its
proofs replaced by `sorry`, on Lean v4.28.0 and Mathlib `8f9d9cf`. The agent fills in proofs in
`se-bmk-intern/combinatorial-games`. The judge builds the submitted project, runs `eval_lean.py
--mode unweighted`, and counts repaired declarations. Raw score = `repaired / 3732` (0..1,
maximize). The rescale is the v1 one (`linear` 0..1 -> 0..100). Migrated like
`lean_analysis_proofs` (same base, same `eval_lean.py`).

## Source

- `environment/se-bmk-intern/combinatorial-games/` (67 files) and
  `judge/se-bmk-intern/eval_lean.py`: the task authors' repository (not public), identical to the
  published v1 images.
- `combinatorial-games/ListDeclAxiom.lean`: the version shipped in the published v1 images
  (comments translated to English, code identical).
- Base `bases/lean-4.28.0-mathlib-8f9d9cf`: the task's `lake-manifest.json` equals the base's, so
  Lake reuses the base's Mathlib and builds only the task's modules.
- `judge/run.sh`, `judge/write_result.py`: new; they run v1's eval chain and write `result.json`.
- `instruction.md`: v1's prompt, verbatim.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. `.lake/packages` is a symlink to the base's Mathlib packages instead of a copy.
3. The `lake-manifest.json` files record the real upstream revisions (v1 had synthetic ones);
   Mathlib content is identical. These are the only files that differ in the workspace, so the
   workspace git commit hash differs from v1's.
4. Best-of-run: a run whose only valid submission repaired nothing now has best 0 (v1: none).
   Build failures are invalid with no score, as in v1.

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same host, interleaved. Lean
builds are deterministic. Raw score; 0..100 = 100 x raw.

| Submission | Old | New |
|---|---|---|
| empty | no score | invalid |
| historical 1, 2 (build errors) | no score | invalid |
| historical 3–5 | 0.069400, 0.246785, 0.528671 | same |
| historical 6 | 1.0 | 1.0 |

Scores and `eval_lean` summaries are identical everywhere and equal the historical v1 scores; for
the build failures the error locations are identical. One historical submission timed out in v1
but fails to build in about 30 s on both images, so that timeout was environmental.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The submission can spoof or tamper with the result.** Output printed while the submitted
   project builds is parsed before the evaluator's own result, and code that runs during the build
   (for example `#eval`) runs as root next to the grader (the cross-task issue in
   `tasks/SCHEMA.md`).
2. **Public solutions exist.** The upstream project has the complete proofs; one historical
   submission repairs all 3732 declarations, so the task is close to saturated.
3. **Compiler-generated "new bad" declarations.** A few auto-generated declarations are reported as
   new problems in most partial solves; they have weight 0 and do not affect the score.
4. Changed or disappeared declarations score 0; there is no statement hash guard in this task.
5. **Fragile workspace.** Deleting `.lake/packages/mathlib` in the workspace removes the only
   Mathlib copy, which cannot be restored offline.
