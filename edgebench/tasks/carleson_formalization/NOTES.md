# carleson_formalization

Lean 4 formalization task on the Carleson project (Lean `v4.30.0-rc2`, Mathlib `1a4917a`). The
agent repairs declarations in `se-bmk-intern/carleson`. The judge builds the submitted project,
runs `eval_lean.py --mode unweighted`, and counts repaired declarations. Raw score =
`repaired / 3004` (0..1, maximize), or 0 (still valid) when the statement of
`classical_carleson` changed. The rescale is the v1 one (`linear` 0..1 -> 0..100).

## Source

- `environment/se-bmk-intern/carleson/` (162 files) and `judge/se-bmk-intern/eval_lean.py`: the
  task authors' repository (not public), identical to the published v1 images.
- `carleson/ListDeclAxiom.lean`: the version shipped in the published v1 images (comments
  translated to English, code identical; it prints the statement hash the judge checks).
- Base `bases/lean-4.30.0-rc2-mathlib-1a4917a` (created for this task): the toolchain, Mathlib and
  its dependencies with prebuilt oleans. The one package the base lacks, `checkdecls`, is cloned at
  the commit in the task's `lake-manifest.json` during the build.
- `judge/run.sh`, `judge/write_result.py`: new; `run.sh` runs v1's eval chain verbatim and
  `write_result.py` writes `result.json`.
- `instruction.md`: v1's prompt, verbatim.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. `.lake/packages/<pkg>` are symlinks to the base's shared packages instead of a private copy,
   so the judge copies about 150 MB instead of 6.6 GB. Package sources and oleans are identical.
3. `lake-manifest.json` records the real upstream revisions (v1 had synthetic ones). It is the
   only file that differs in the workspace, so the workspace git commit hash differs from v1's.
4. v1's build trace for `ListDeclAxiom` recorded a stale source, which made v1 recompile it at
   grading time; the new trace matches the shipped file. Outputs are identical.
5. Best-of-run: a run whose only valid submission repaired nothing now has best 0 (v1: none).
   Build failures and empty submissions are invalid with no score, as in v1.

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same host, run in parallel. Lean
grading is deterministic. Raw score; 0..100 = 100 x raw.

| Submission | Old | New |
|---|---|---|
| empty | no score | invalid |
| historical 1 (build error) | no score | invalid |
| historical 2–5 | 0.005992, 0.063915, 0.304261, 0.967710 | same |
| forged result (Known issue 1) | 1.0 | 1.0 |

Raw scores are bit-identical, summaries match, and they equal the historical v1 scores.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The submission can spoof or tamper with the result.** Output printed while the submitted
   project builds is parsed before the evaluator's own result, so a one-line `#eval` can report a
   full score; build-time code also runs as root next to the grader (the cross-task issue in
   `tasks/SCHEMA.md`).
2. **Shared packages are writable.** Through the symlinks, the agent (work) and the submission's
   build (judge) can modify the base's shared Mathlib for that container; v1 had a private copy.
   The oleans can be restored offline from the local Mathlib cache.
3. Changed or disappeared declarations score 0; only `classical_carleson` has a statement hash
   guard.
