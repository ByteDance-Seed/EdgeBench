# smt_solver

The agent writes an SMT solver (`build.sh`, `solve`, `src/`) for QF_UF, QF_LRA, QF_LIA and QF_UFLRA.
The judge runs `./build.sh`, then `scripts/evaluate.py` on 774 hidden instances (60 s wall clock per
case, 16 in parallel, with a satisfiability-preserving perturbation). A `sat` answer earns 1.0 only
with a JSON model that validates against the assertions; a correct `unsat` earns 0.2; anything else
earns 0. Credit is averaged per difficulty and weighted easy 0.10 / medium 0.20 / hard 0.70. Raw
score = that weighted value in 0..1 (maximize). The rescale is the v1 one (`linear` 0..1 ->
0..100).

## Source

- Workspace docs, papers and `scripts/evaluate.py`, and the judge's evaluation scripts: the task
  authors' repository (not public), at the version the published v1 images carry, identical by
  sha256.
- Public develop set `environment/workspace/benchmarks/` (48 instances, 25 MB): taken from the
  published v1 work image. The starter `build.sh` and `solve` are byte-identical to v1's inline
  scripts.
- Blob `judge/blobs/hidden_benchmarks.tar.gz` (356 MB packed, 3.29 GB unpacked; sha256 in
  `task.toml`): the 774 hidden instances and their answer files, extracted from the archive in the
  published v1 judge image and byte-identical to it. The instances are anonymized and could not be
  traced to a public release.
- `judge/parse_result.py` is v1's inline parse script; `judge/run.sh` and `judge/write_result.py`
  run v1's eval chain and write `result.json` with v1's structured-result logic.
- `instruction.md`: v1's prompt, verbatim. Base: `bases/python310` (no extra packages).

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. **The hidden set ships extracted.** v1 kept the archive in the judge image and extracted it at
   the start of every run; the image now holds the extracted tree at the same path, so the archive
   (which stayed readable during v1 runs) no longer exists.
3. Grading scratch files moved from fixed `/tmp` paths to a temporary directory; the captured output
   and its order are unchanged.
4. If no score can be parsed, v1 recorded an unrankable score; the new grader returns
   `valid=false`. Empty submissions, build failures and preflight rejections score `valid=true, 0`,
   as in v1.
5. The workspace git commit is identical to v1's (same hash).

## Regression summary

Old (published v1 judge) and new judge on the same submissions, run concurrently on the same
shared host, two runs each. Raw score; 0..100 in brackets.

| Submission | Old | New |
|---|---|---|
| empty, historical 1 (always answers `unknown`) | 0 | 0 |
| historical 2 | 0.15674 / 0.15350 (15.67 / 15.35) | 0.15940 / 0.15350 (15.94 / 15.35) |
| historical 3 (one run) | 0.21575 (21.57) | 0.21575 |
| historical 4 | 0.50434 / 0.50111 (50.43 / 50.11) | 0.50218 / 0.50003 (50.22 / 50.00) |
| forged score file (Known issue 1) | 1.0 | 1.0 |

Deterministic rows match exactly, including per-logic counts. The timed rows differ by a few cases
near the 60 s limit; the old-new difference of means is smaller than either side's own spread.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The submission can forge its score file.** The score is read from a file the submitted
   `build.sh` (running as root) can write before the evaluator does, and an early evaluator exit is
   not treated as a failure, so a submission can report a full score. Same root cause as the
   cross-task issue in `tasks/SCHEMA.md`.
2. A malformed score file crashes the parser and makes the result unrankable (now invalid).
3. **Hidden answers are readable during the build.** The answer files are deleted only after the
   build, and the preflight scan of the submission is plain substring matching. A correct `unsat`
   earns 0.2 without a proof, so leaked labels are worth something; `sat` still needs a valid model.
4. **The documented local evaluation fails in the shipped workspace.** The README's command is
   rejected by the preflight check when run from the workspace; with the check skipped it deletes the
   public answer files, so the next run crashes (restorable with `git checkout`).
5. **Host-dependent score.** Cases near the 60 s limit flip with host speed and load (16 in parallel,
   no CPU pinning).
6. **No judge resource limits.** A solver may use all host cores and memory; some hidden inputs are
   up to 162 MB.
7. **Scoring details are only in the docs.** The instruction does not mention the 0.2 `unsat`
   credit or the difficulty weights (650 of 774 hidden cases are hard); `smtlib_spec.md` does.
8. The instruction's "7200 second whole-run budget" is the judge timeout; hitting it gives no result,
   not a partial score.
