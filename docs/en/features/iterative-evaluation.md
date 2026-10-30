---
title: Iterative Evaluation
---

# Iterative Evaluation

During a run the agent submits as often as it likes and gets a score and feedback each time:

1. The agent calls `sforge-submit` in the work container.
2. The judge server grades the submission in a fresh judge container with the task's grader.
3. The agent reads the raw score, whether the submission is valid, and the grader's feedback, and keeps improving.

The [stop hook and auto-resume](/en/guide/agents#stop-hook) keep it working until the time budget ends.

## sforge-submit

| Command | Description |
|---------|-------------|
| `sforge-submit` | Submit the task's submission paths and wait for the result |
| `sforge-submit -d` | Also show per-item details |
| `sforge-submit -l` | List previous submissions |

`--max-submissions N` caps the agent's submissions and `--submission-cooldown S` requires S seconds between them; `sforge-submit` tells the agent when a limit applies.

## Auto-Eval

Every 300 seconds (`--eval-interval`) SForge also grades the current workspace in the background, as rounds `auto-1`, `auto-2`, ... The agent does not see these results; they make progress count even when the agent does not submit. Auto-eval ignores the submission limits; `--disable-auto-eval` turns it off.

## Scoring

The grader writes a raw `score`, `valid` and feedback (`summary`, `details`, `metrics`) to `result.json`; see [Task Format](/en/tasks/task-format#judge-contract). Invalid submissions, crashes and judge timeouts do not count.

The run's result is the best valid score across agent and auto-eval rounds, in the task's `direction`. For the leaderboard it is mapped to 0–100 by the task's `[score] rescale`; the agent only sees raw scores. The workspace at the end of the run is archived but not graded, so only submitted states count.

Everything is written to `logs/runs/<run-id>/<task-id>/`; see [Run Outputs](/en/reference/cli#run-outputs).
