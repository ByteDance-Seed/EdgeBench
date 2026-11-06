# k12_math_recommendation

The agent builds a knowledge-tracing and question-recommendation system from about 800k synthetic
student answer logs, and submits `train.py`, `infer.py`, `models/`, `submission.json`,
`requirements.txt` and `README.md`. The judge runs the submitted `infer.py` on 100 hidden
scenarios and `evaluate.py` scores the output: total = 0.35 M1 (next-question AUC) + 0.30 M2
(mastery calibration: ECE + Spearman) + 0.30 M3 (learning gain in a built-in student simulator vs
random recommendations) + 0.04 M4 (5 instructional constraints) + 0.01 M5 (infer.py time ≤ 200 s,
−5 per missing deliverable). Raw score = `total_score`, 0..100 (maximize). v1 had no rescale.
The grader is fully local: no LLM and no network calls.

## Source

- Every task file (workspace inputs and docs, the judge's `scoring/` with `evaluate.py`, the
  hidden scenarios and ground truth, the student simulator and two reference implementations) is
  taken from the published v1 images, which carry an English translation of the authors' original
  Chinese assets (renamed directories, translated docs and comments; logic unchanged). All files
  are identical by sha256 to the published images.
- v1's duplicate copies (`attachments/` in the workspace, `input/` in the judge) are recreated
  from `environment/workspace/` instead of committed twice.
- `environment/requirements.lock`: the 13 package versions in the published images, hash-pinned
  wheels from PyPI. Base: `bases/python`.
- `judge/run.sh`, `judge/emit_result.py`: new; they run v1's eval command verbatim and write
  `result.json` with v1's structured-result logic.
- `instruction.md`: v1's prompt, verbatim.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. No pip cache in the images.
3. If no score is printed at all (the scorer crashed), v1 recorded an unrankable score; the new
   grader returns `valid=false`. The scorer always prints a score in practice.
4. The workspace git commit is identical to v1's (same hash).

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same host, interleaved, two runs
each. Raw score (no rescale).

| Submission | Old | New |
|---|---|---|
| empty, `infer.py` that crashes | 0.0 | 0.0 |
| forged result (Known issue 2) | 99.5 | 99.5 |
| shipped reference stage 1 / stage 2 | 17.598 / 24.699 | same |
| historical 1 (writes no output) | 0.0 | 0.0 |
| historical 2–6 | 28.57, 30.76, 36.338, 43.81, 45.319 | same |

Every run matches exactly with zero spread and equals the historical v1 scores. `infer.py` time
stayed far below the 200 s limit, so timing never affected a score.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **Hidden labels are readable by the submission.** `infer.py` runs as root in the judge next to
   the ground truth and the simulator, and the scorer even copies the ground truth, the scenarios
   and the reference submissions into the workspace before running it. A submission that reads
   them gets M1 and M2 near full marks.
2. **The submission can forge its result.** When `infer.py` fails, its error output is printed
   before the scorer's own result, and the parser takes the first result block. Same root cause
   as the cross-task issue in `tasks/SCHEMA.md`.
3. **Missing `README.md` and `requirements.txt` are never penalized.** The scorer copies the
   reference versions into the workspace when they are absent; only a missing `train.py` costs
   points (0.05).
4. **M5 is wall-clock.** It depends on the judge host's speed (no CPU limit); only 1% weight.
5. **Instruction wording.** The prompt refers to a scoring formula "described below" that does not
   follow; the weights and thresholds are only in the hidden scorer and rubric, and a manifest in
   the judge quotes older weights. The submission-path metadata omits `models/`, which the task
   accepts.
6. **Infrastructure failures score 0 instead of invalid** (any scorer crash, missing output, bad
   JSON or a 600 s `infer.py` timeout).
7. The reference implementations are pickle files; loading them executes code.
