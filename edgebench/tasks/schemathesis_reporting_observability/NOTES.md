# schemathesis_reporting_observability

Roadmap task on the real Schemathesis code base (Python). Starting from Schemathesis 4.13.0, the
agent implements five v4.14-style targets described in `/app/TODO.md` (a post-validation hook
system, reporting writers for VCR/HAR/JUnit/NDJSON, pytest plugin report integration, an
examples-phase enhancement with optional properties and per-branch `oneOf`/`anyOf` sets, and
email-format and `allow-extra-parameters` fixes). The judge runs five hidden pytest files (53
checks) via `/tests/test.sh`. Raw score = test.sh's `TOTAL_SCORE` = weighted mean of the per-phase
pass ratios (weights 2, 2, 3, 2, 1; 0..1, maximize). The rescale is the v1 one (`linear` 0..1 ->
0..100).

Sibling of `schemathesis_config_modernization` (same task authors, same recipe; several files are
shared).

## Source

- Workspace: public upstream Schemathesis, tag `v4.13.0` (commit `c759d3c6…`), fetched as the
  GitHub archive and sha256-checked; two upstream symlinks are replaced by copies of their targets,
  as in v1. The resulting tree is identical to v1's workspace.
- `environment/TODO.md` and the judge's `tests/` (test.sh plus 5 test files): taken from the
  published v1 images (the task authors' repository is private and was not available to us),
  identical by sha256.
- `environment/requirements.lock`: the 80 package versions v1's unpinned install resolved to,
  hash-pinned wheels from PyPI; `environment/build-requirements.lock` pins the build backend. The
  editable install comes out byte-identical to v1's. Base: `bases/python`.
- `judge/structured_result.py`, `judge/write_result.py`, `judge/run.sh`: v1's eval program and
  parser, shared with the sibling task.
- `instruction.md`: v1's prompt, verbatim.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. Pinned Python dependencies and build backend; no pip cache in the image.
3. Grading logs go to temporary files instead of fixed `/tmp` paths, and test.sh's full output is
   also printed to the judge log.
4. **The judge is offline.** test.sh re-runs `pip install -e .`, which now fails silently and
   leaves the image's editable install in place; this matches v1 for every submission that keeps
   `src/schemathesis` as the package.
5. A judge timeout leaves no result (invalid); v1 recorded an unrankable score.
6. The workspace git commits are identical to v1's (same hashes).

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same host, interleaved, two runs
each. The tests are deterministic in practice. Raw score; 0..100 in brackets.

| Submission | Old | New |
|---|---|---|
| empty archive (unmodified 4.13.0) | 0.02 (2.0) | 0.02 |
| forged score (Known issue 1) | 0.99 | 0.99 |
| historical 1 (hangs) | timed out after 1800 s | timed out after 1800 s |
| historical 2–6 | 0.670833, 0.767262, 0.795833, 0.8125, 0.8125 | same |

Every scored row is valid, matches exactly with zero spread, and has identical per-phase summaries.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The submission can inject a score.** The score is the first `TOTAL_SCORE` in test.sh's
   output, the per-phase pytest output comes first, and the submitted code runs inside each pytest
   process, so a submission can print a score of its choice. A fix is to read the score from a file
   the submission cannot reach (related to the cross-task issue in `tasks/SCHEMA.md`).
2. **Per-phase counting is loose.** Pass and fail counts are line matches on pytest output, so
   extra lines shift them (the empty submission reports more checks than phase 4 has), and a phase
   whose pytest exits 0 gets full marks.
3. **An empty submission is not 0.** Unmodified 4.13.0 already passes 2 of the phase-5 checks.
4. **The whole repository is the submission**, including `pyproject.toml`, `tox.ini` and test
   files, and the hidden tests import the submitted package, so submitted code runs as root next to
   the grader.
5. **A hanging submission costs the full 1800 s and gets no score.** test.sh sets no per-phase
   timeout.
6. The instruction mentions "local tests or submission feedback", but the hidden tests are not in
   the work image; only the upstream test suite is available locally.
