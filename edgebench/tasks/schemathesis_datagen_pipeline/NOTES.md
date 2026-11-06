# schemathesis_datagen_pipeline

Roadmap task on the real Schemathesis code base (Python). Starting from Schemathesis 4.14.3, the
agent implements eight targets described in `/app/TODO.md` (structured header generation,
coverage-phase hooks, multi-schema `schemathesis.pytest.parametrize`, discriminator response
validation, discriminator-aware data generation, schema-loading 503 retry, reporting all distinct
schema errors, a pattern quantifier fix). The judge runs eight hidden pytest files (46 checks) via
`/tests/test.sh`. Raw score = test.sh's `TOTAL_SCORE` = weighted mean of the per-phase pass ratios
(weights 2, 1, 2, 2, 2, 1, 1, 2; 0..1, maximize). The rescale is the v1 one (`linear` 0..1 ->
0..100).

Sibling of `schemathesis_config_modernization` (same task authors, same recipe).

## Source

- Workspace: public upstream Schemathesis, tag `v4.14.3` (commit `d4b9c504…`), fetched as the
  GitHub archive and sha256-checked; two upstream symlinks are replaced by copies of their targets,
  as in v1. The resulting tree is identical to v1's workspace.
- `environment/TODO.md` and the judge's `tests/` (test.sh plus 8 test files): taken from the
  published v1 images (the task authors' repository is private and was not available to us),
  identical by sha256.
- `environment/requirements.lock`: the 80 package versions v1's unpinned install resolved to,
  hash-pinned wheels from PyPI; `environment/build-requirements.lock` pins the build backend
  (hatchling 1.30.1). The editable install comes out byte-identical to v1's. Base: `bases/python`.
- `judge/structured_result.py`, `judge/write_result.py`, `judge/run.sh`: v1's eval program and
  parser, shared with the sibling task.
- `instruction.md`: v1's prompt, verbatim.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. Pinned Python dependencies and build backend; no pip cache in the image.
3. Grading logs go to temporary files instead of fixed `/tmp` paths, and test.sh's full output is
   also printed to the judge log.
4. **The judge is offline.** test.sh re-runs `pip install -e .`, which now fails silently and
   leaves the image's editable install in place. This matches v1 for every submission that keeps
   `src/schemathesis` as the package; it could differ only for a submission that changes
   dependencies or entry points and relies on the reinstall.
5. The workspace git commits are identical to v1's (same hashes).

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same host, interleaved, two runs
each. The tests are deterministic in practice. Raw score; 0..100 in brackets. Historical v1 scores
range only from 0.3235 to 0.6718; the submissions below cover that range.

| Submission | Old | New |
|---|---|---|
| empty archive (unmodified 4.14.3) | 0.323504 (32.35) | same |
| forged score (Known issue 1) | 0.99 | 0.99 |
| historical 1–5 | 0.400427, 0.461111, 0.55, 0.614103, 0.671795 | same |

Every row is valid, matches exactly with zero spread, and has identical per-phase summaries.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The submission can inject a score.** The score is the first `TOTAL_SCORE` in test.sh's
   output, the per-phase pytest output comes first, and the submitted code runs inside each pytest
   process, so a submission can print a score of its choice. A fix is to read the score from a file
   the submission cannot reach (related to the cross-task issue in `tasks/SCHEMA.md`).
2. **Per-phase counting is loose.** Pass and fail counts are line matches on pytest output, so
   extra captured output can shift them; a phase that fails to collect scores 0.
3. **An empty submission is not 0.** Unmodified 4.14.3 already scores 0.3235, which is also the
   lowest historical score.
4. **The whole repository is the submission**, including `pyproject.toml` and test files, and the
   hidden tests import the submitted package, so submitted code runs as root next to the grader.
5. The instruction mentions "local tests or submission feedback", but the hidden tests are not in
   the work image; only the upstream test suite is available locally.
