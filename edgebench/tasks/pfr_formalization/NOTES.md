# pfr_formalization

Lean 4 formalization task: the public `pfr` project (teorth/pfr, Apache-2.0) with proofs
removed, on Lean v4.29.0 and Mathlib `8a178386`. The agent completes proofs in
`se-bmk-intern/pfr`. The judge builds the submitted project, runs `eval_lean.py --mode unweighted`
against the unsolved baseline, and counts repaired declarations. Raw score = `repaired / 423`
(0..1, maximize), or 0 when the statement of `weak_PFR` or `entropic_PFR_conjecture` changed. The
rescale is the v1 one (`linear` 0..1 -> 0..100).

## Source

- `environment/se-bmk-intern/pfr/` (117 files, including upstream's `blueprint/` and `website/`)
  and `judge/se-bmk-intern/eval_lean.py`: the task authors' repository (not public), identical to
  the published v1 images.
- `pfr/ListDeclAxiom.lean`: the version shipped in the published v1 images (comments translated to
  English, code identical; it prints the statement hashes the judge checks).
- Base `bases/lean-4.29.0-mathlib-8a17838` (created for this task): Mathlib and its dependencies
  with prebuilt oleans. The two pfr-only packages (`AddCombi`, `checkdecls`) are cloned at the
  commits in the task's `lake-manifest.json` during the build.
- `judge/run.sh`, `judge/write_result.py`: new; `run.sh` runs v1's eval chain verbatim and
  `write_result.py` writes `result.json`.
- `instruction.md`: v1's prompt, verbatim.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. Mathlib and its dependencies are symlinks into the base instead of a 7 GB copy per image; the
   base adds `/home/workspace/baseline` next to the task project. All oleans and sources are
   identical to v1's.
3. `lake-manifest.json` records the real upstream revisions (v1 had synthetic ones). It is the only
   file that differs in the workspace, so the workspace git commit hash differs from v1's.
4. Build failures are invalid with no score, as in v1; best-of-run equals v1's.

## Regression summary

Old (published v1 judge, two runs) and new judge on the same submissions, same host, interleaved.
Lean grading is deterministic. Raw score; 0..100 = 100 x raw.

| Submission | Old | New |
|---|---|---|
| empty | no score | invalid |
| historical 1 (build error) | no score | invalid |
| historical 2–5 | 0.189125, 0.368794, 0.617021, 0.782506 | same |
| unsolved tree | 0.0 | 0.0 |
| forged result (Known issue 1) | 1.0 | 1.0 |

Scores and `eval_lean` summaries match exactly and equal the historical v1 scores.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The submission can spoof or tamper with the result.** Output printed while the submitted
   project builds is parsed before the evaluator's own result, so a one-line `#eval` can report a
   full score; build-time code also runs as root next to the grader (the cross-task issue in
   `tasks/SCHEMA.md`).
2. **Public solutions exist.** The full proofs are in the public `pfr` repository, and the
   workspace's `blueprint/` holds the informal proofs.
3. Only the two main statements are hash-guarded; other declarations are protected only by their
   printed type.
4. **Fragile workspace.** Deleting `.lake/packages/mathlib` in the workspace removes the only
   Mathlib copy, which cannot be restored offline; `lake update` may also try to re-clone it.
