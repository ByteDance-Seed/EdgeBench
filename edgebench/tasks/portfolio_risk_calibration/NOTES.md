# portfolio_risk_calibration

Dynamic multi-asset ETF portfolio optimizer with risk calibration (VaR, risk scaling factor),
constrained optimization, turnover-aware rebalancing and mandatory shorting. The agent delivers
`portfolio_optimizer.py` (plus `requirements.txt` and `backtest_results.json`). The judge runs
`scoring/score.py`, which runs `scoring/eval_script.py`: it runs `portfolio_optimizer.py
--backtest` on the hidden 2025 test period (at most 300 s), re-computes everything from the
`backtest_results.json` that run writes (NAV rebuild from weights and prices, constraint audit,
anti-fraud checks, independent VaR) and prints a total out of 100. Raw score = that total clamped to
0..100 (maximize). v1 defined no rescale, so none is set.

## Source

- Every task file (workspace inputs and docs, the judge's `scoring/` with the evaluator, hidden
  data, risk-event labels, reference implementation and example logs) is taken from the published
  v1 images, which carry an English translation of the task authors' Chinese original (some files
  renamed; only strings changed in the code). All files are identical by sha256 to the published
  images. `deliverables_guide.docx` is still the Chinese document.
- `environment/requirements.lock`: the 52 package versions v1's unpinned install resolved to,
  hash-pinned wheels from PyPI. Debian `python3-pip`/`python3-wheel` at v1's versions. Base:
  `bases/python`.
- `judge/run.sh`, `judge/emit_result.py`: new; they run v1's eval command verbatim and write
  `result.json` with v1's structured-result logic.
- `instruction.md`: v1's published prompt, verbatim.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. Python dependencies are pinned to the versions v1 resolved (numpy 2.4.6, pandas 3.0.3, scipy
   1.17.1, statsmodels 0.14.6, cvxpy 1.9.1, scikit-learn 1.9.0, …). The workspace `requirements.txt`
   is unchanged.
3. If the scorer itself crashes without a result (not reachable in practice), v1 recorded an
   unrankable score; the new grader returns `valid=false`. Strategy failures and the empty
   submission score `valid=true, 0`, as in v1.
4. A stale bytecode cache left in v1's judge image is not shipped; nothing loads it.
5. The workspace git commit is identical to v1's (same hash).

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same host, interleaved, two runs
each. The grader is not timing-dependent. Raw score (no rescale).

| Submission | Old | New |
|---|---|---|
| empty, crashing strategy | 0 | 0 |
| strategy that prints a forged result | 0 | 0 |
| forged result via the parent process (Known issue 1) | 100 | 100 |
| historical 1–6 | 6.59, 8.48, 24.63, 28.59, 36.71, 37.21 | same |

Every row is valid and matches exactly, and summaries (per-metric points and penalties) equal the
historical v1 reports.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The submission can forge its result.** The strategy runs as root inside the judge; its own
   output is captured, but it can write to the evaluator's output, which is printed before the real
   result, and the parser takes the first result block (the cross-task issue in `tasks/SCHEMA.md`).
2. **Hidden data and labels are readable by the strategy.** It runs next to the judge's scoring
   directory (hidden files, reference implementation and logs), and the planted volatility event
   that earns the +10 bonus is only renamed in the same directory. A static text check of the
   strategy file is the only guard.
3. **Grader inputs are writable by the strategy.** Backups of the full test data sit in the working
   directory during the run and are restored afterwards for the audit. (Not tested.)
4. **The instruction misdescribes the evaluation environment.** It promises an isolated directory
   with only the test inputs; the working directory also holds the training and validation data,
   the scoring directory and the event label (issue 2).
5. **Look-ahead is only checked statically.** The strategy receives the whole 2025 price file at
   once; the audit only greps for a few look-ahead patterns.
6. **Two deliverables are ignored.** The submitted `backtest_results.json` is deleted before the
   run and `requirements.txt` is never installed, although both are listed as deliverables.
7. **Wall-clock cap.** The 300 s strategy limit is wall time, so a slow strategy's score depends on
   host load.
8. **Translation quality.** Some translated evaluator messages are garbled, and the deliverables
   guide is still in Chinese.
