# order_addition_permutation_optimization

Order-of-Addition permutation optimization. The agent searches for a permutation of 1..1000 that
minimizes a black-box cost (a compiled Cython module with built-in data) and writes
`final_result.txt` (`final_pai`, `final_cost`, `final_num`). The judge runs v1's pytest file
against private copies of the cost module and score helper, recomputes the cost, and prints
`TOTAL_SCORE = 100 * min(1, cost_ref/cost)^3 * min(1, num_ref/num)^0.5`
(cost_ref = 200690260.6677975, num_ref = 200000). Raw score = that value (0..100, maximize); the
rescale is the v1 one (`linear` 0..100). The grader is deterministic and takes about 1 s.

## Source

- Workspace files (cost module, `requirements.txt`, test script, example result) and the judge's
  `tests/`: the task authors' repository (not public), identical by sha256 to the published v1
  images.
- `environment/workspace/README.md`, `environment/workspace/score_vcpom_result.py` and
  `judge/tests/score_vcpom_result.py`: the English versions shipped in the published v1 images
  (the repository has Chinese versions; only comments and labels differ).
- `environment/requirements.lock`, `environment/pip-bootstrap.lock`: the published work image's
  `pip freeze`, one PyPI wheel per package with its sha256.
- `judge/run.sh`, `judge/result.py`: new; they run v1's eval command unchanged and write
  `result.json` with v1's parsing.
- `instruction.md`: v1's prompt, verbatim. Base: `bases/python`.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. pip installs exact, hash-checked wheels from PyPI instead of resolving `requirements.txt`
   against a private mirror. Same versions; v1's leftover copies of the pre-upgrade pip,
   setuptools and wheel are gone.
3. **Score instead of pass rate.** The raw score is v1's raw score (the first `TOTAL_SCORE` in the
   pytest output). Submissions without a `TOTAL_SCORE` (missing or malformed result file, cost
   mismatch) are `valid=true, score=0` instead of v1's unscored pass rate of 0.4–0.6, which keeps
   them below every scored submission.
4. **Best-of-run selection changes.** Because of Known issue 1 no v1 submission ever passed all 5
   tests, so v1's `pass_rate_first` kept the *first* submission of a run that reached 4/5 rather
   than the best one. The harness now keeps the best score, which is what v1's rule would have
   done had that test passed. Per-submission scores are unchanged; in 6 of the 10 recorded v1 runs
   the run's best score goes up, and runs without any valid result go from 0.4 to 0.
5. The workspace git commit is identical to v1's (same hash).

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same host, interleaved, two runs
each. Raw score (= 0..100).

| Submission | Old | New |
|---|---|---|
| empty, cost mismatch, historical 1 (no valid result) | no score (pass rate 0.4–0.6) | 0 |
| identity permutation, reversed with too many calls | 3.3e-09, 1.7e-09 | same |
| forbidden access in a submitted `.py` | 0 | 0 |
| pytest-config spoof (Known issue 2) | 100 | 100 |
| historical 2–6 | 5.8649067881, 19.6271276663, 24.2722089238, 30.8401596802, 47.1674017724 | same |

Every scored row matches exactly on every run, and summaries are identical; rows without a v1
score map to 0 as in Deviation 3.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The judge's integrity test always fails.** It expects the hash of the original
   Chinese-comment score helper, but the published images shipped an English translation, so
   every submission fails 1 of 5 tests. The score is unaffected; in v1 this changed best-of-run
   selection (Deviation 4). Restoring the original file or updating the hash fixes it.
2. **The submission can inject a score.** pytest loads plugin and configuration files from the
   submission directory, and the first `TOTAL_SCORE` in its output wins, so a submission can make
   the grader report a full score. Same root cause as the cross-task issue in `tasks/SCHEMA.md`
   (submitted code runs as root next to the grader); a fix is to run pytest isolated from the
   submission's files.
3. **`final_num` is self-reported.** The judge cannot count black-box calls, so any small
   `final_num` earns the full call-count factor. The workspace also has an identical copy of the
   cost module that the agent can call without limit.
4. **The forbidden-access scan is weak in both directions.** It is a substring search over
   submitted `.py/.pyw/.ipynb/.sh` files: simple rewrites slip through, other file types are never
   scanned, and a harmless comment that quotes a forbidden pattern scores 0.
5. **The "private" cost module is the public one.** The judge's copy has the same bytes as the
   workspace copy; isolation only protects against editing the workspace copy.
6. **Unclear wording.** The instruction says the result depends only on `final_result.txt`, but
   the scan of other submitted files can zero the score (issue 4).
7. Missing or malformed `final_result.txt` is `valid=true, score=0` rather than invalid.
