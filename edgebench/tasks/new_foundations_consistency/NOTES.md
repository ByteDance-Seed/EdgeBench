# new_foundations_consistency

Lean 4 formalization task on ConNF, the formalization of the consistency of Quine's New
Foundations (Lean `v4.21.0-rc3`, Mathlib `5b77ef3c`, plus doc-gen4 as a declared dependency). The
agent repairs declarations in `se-bmk-intern/con-nf`. The judge builds the submitted project, runs
`eval_lean.py --mode unweighted`, and counts repaired declarations. Raw score = `repaired / 2246`
(0..1, maximize). The rescale is the v1 one (`linear` 0..1 -> 0..100).

## Source

- `environment/se-bmk-intern/con-nf/` (143 files) and `judge/se-bmk-intern/eval_lean.py`: the
  task authors' repository (not public), identical to the published v1 images.
- `con-nf/ListDeclAxiom.lean`: the version shipped in the published v1 images (comments translated
  to English, code identical).
- Base `bases/lean-4.21.0-rc3-mathlib-5b77ef3` (created for this task): elan and the toolchain
  (identical to v1's), and con-nf's 13 packages with Mathlib oleans whose combined sha256 equals
  v1's.
- `judge/run.sh`, `judge/write_result.py`: new; `run.sh` runs v1's eval chain verbatim and
  `write_result.py` writes `result.json`.
- `instruction.md`: v1's prompt, verbatim.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. **The packages are real upstream clones; v1's doc-gen4 checkout was broken.** v1's
   post-processed packages made Lake re-clone doc-gen4 from GitHub at grading time, so the v1 judge
   needed network (and failed every submission without it). The new images use the manifest's real
   revisions and need no network at grading time. Production v1 had network, so historical scores
   are unaffected.
3. `.lake/packages` is a symlink to the base's shared packages instead of a per-image copy.
4. `lake-manifest.json` records the real upstream revisions, so the workspace git commit hash
   differs from v1's.
5. Best-of-run: a run whose only valid submission repaired nothing now has best 0 (v1: none).
   Build failures are invalid with no score, as in v1.

## Regression summary

Old (published v1 judge, run with network as production was) and new judge on the same
submissions, same host. Lean grading is deterministic. Raw score; 0..100 = 100 x raw.

| Submission | Old | New |
|---|---|---|
| empty | no score | invalid |
| historical 1 (build error) | no score | invalid |
| unsolved task files | 0.0 | 0.0 |
| forged result (Known issue 1) | 1.0 | 1.0 |
| historical 2–6 | 0.137133, 0.315672, 0.561888, 0.720392, 0.925646 | same |

All `eval_lean` summaries match exactly and equal the historical v1 scores. Without network, most
old-judge runs failed on the doc-gen4 re-clone (Deviation 2).

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The submission can spoof or tamper with the result.** Output printed while the submitted
   project builds is parsed before the evaluator's own result, so a one-line `#eval` can report a
   full score; build-time code also runs as root next to the grader (the cross-task issue in
   `tasks/SCHEMA.md`).
2. Submissions may drop the doc-gen4 requirement from `lakefile.toml`; the judge accepts this.
   Harmless for scoring.
3. **Fragile workspace.** Deleting `.lake/packages/mathlib` in the workspace removes the only
   Mathlib copy, which cannot be restored offline.
4. Changed or disappeared declarations score 0 with no statement hash guard. About 300 compiler
   auxiliaries are reported as "new bad" even for the unsolved tree; they have weight 0.
