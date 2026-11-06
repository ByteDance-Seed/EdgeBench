# cta_risk_budget_optimization

Professional-knowledge task: build a cross-border CTA multi-strategy futures system (signals, risk
budgeting, multi-currency backtest with costs, drawdown control, reports) from the Excel and Word
inputs in the workspace. The agent submits `run.py`/`main.py`, CSV/JSON deliverables and reports.
The judge runs `scoring/score.py` -> `scoring/run_eval.py`, which runs the submitted entry point
(300 s cap) and then `scoring/eval_script.py`, which runs it again (300 s cap) and scores the
resulting files in five dimensions (backtest verification 10, performance 25, risk constraints 20,
signals 15, code compliance 10; 80 in total). Raw score = `grand_total / 80 * 100` (0..100,
maximize). v1 defined no rescale, so none is set.

## Source

- Workspace inputs (contract specs, price and macro data, risk policy and research notes,
  `requirements.txt`) and the judge's `scoring/` (scorer, manifest, standard answers): the task
  authors' repository (not public), identical by sha256 to the published v1 images.
- `environment/workspace/task_instruction.md`, `scoring/eval_script.py`, `run_eval.py`,
  `standard_answer_code.py`: the English versions shipped in the published v1 images (the repository
  has Chinese versions; only comments, messages and sector labels differ, and the labels are only
  used as group-by keys).
- Python packages (pandas, numpy, openpyxl, python-docx and dependencies) at v1's versions,
  hash-pinned from PyPI; `git-lfs`, `python3-pip`, `python3-wheel` from the base's Debian snapshot
  at v1's versions. Base: `bases/python`.
- `judge/run.sh`, `judge/emit_result.py`: new; they run v1's eval command verbatim and write
  `result.json` with v1's structured-result logic.
- `instruction.md`: v1's prompt, verbatim.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. Pinned apt and pip packages (same versions as v1); the workspace `requirements.txt` is
   unchanged.
3. If no score is printed (not reachable with this scorer), v1 recorded an unrankable score; the
   new grader returns `valid=false`.
4. A stale bytecode cache left in v1's judge image is not shipped; nothing loads it.
5. The judge is offline (v1 had default networking); the grader does not use the network.
6. The workspace git commit is identical to v1's (same hash).

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same host, interleaved, two runs
each. Raw score (no rescale).

| Submission | Old | New |
|---|---|---|
| empty, crashing `run.py`, historical 1 | 7.5 | 7.5 |
| `run.py` that prints a forged result (Known issue 1) | 100.0 | 100.0 |
| historical 2–7 | 12.5, 23.4375, 32.5, 46.875, 48.75, 50.625 | same |
| historical 8 (slow, hits both 300 s caps) | timed out at 600 s | timed out at 600 s (invalid) |

Every scored row is valid and matches exactly with zero spread.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The submission can inject a score.** The scorer prints the tail of the submitted `run.py`'s
   output before its own result, and the parser takes the first result block, so a `run.py` that
   prints a result block gets any score. A fix is to print the submission's output after the result
   or to parse the scorer's own block.
2. **The submission can tamper with grading.** `run.py` runs twice as root in the judge, next to
   the scorer and the standard answers (the cross-task issue in `tasks/SCHEMA.md`).
3. **Empty submissions score 7.5, not 0.** With no code at all, three code-compliance checks pass.
4. **Allowed libraries are not installed.** The instruction and `requirements.txt` list scipy,
   scikit-learn, statsmodels and matplotlib, but the images only have pandas, numpy, openpyxl and
   python-docx, and the agent has no internet.
5. **"The evaluator will prioritize reading from `outputs/`" is the opposite of what it does**: files
   under `outputs/` get the lowest priority.
6. **Runtime close to the judge timeout.** The entry point runs twice with 300 s caps plus scoring,
   against a 600 s judge timeout, so a slow `run.py` makes the whole judge time out (unrankable).
7. **Mixed languages.** The instruction is English, but the risk policy and research notes are
   Chinese documents.
8. **The README requirement cannot be submitted.** The instruction asks to document extra libraries
   in a README, but no README path is accepted in the submission.
9. **Easy points by keyword.** Some cost and FX points are awarded when the code merely contains
   certain identifiers.
