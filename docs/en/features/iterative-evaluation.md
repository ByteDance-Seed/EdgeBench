---
title: Iterative Evaluation Framework
---

# Iterative Evaluation Framework

SForge uses an iterative evaluate-and-improve loop: the agent edits code, submits for evaluation, reads feedback, and keeps improving until timeout.

The mechanisms fall into four groups:

| Mechanism | Purpose |
|-----------|---------|
| `sforge-submit` | Agent-initiated submission with immediate feedback |
| Auto-eval | Periodically evaluate current code to add sampling points |
| Stop hook / Auto-resume | Keep the agent working until timeout |
| Submission limits | Control the number and frequency of agent-initiated submissions |

## Workflow

1. The agent works in the **Work container**
2. The agent calls `sforge-submit` to submit current code
3. The Judge Server starts a temporary **Judge container** and runs `eval_cmd`
4. SForge returns `pass_rate`, `score`, failed items, and summary
5. The agent uses the feedback to improve and submit again
6. Auto-eval periodically submits current code in the background, creating extra sampling points
7. The final result is the best result across all submissions

## Agent-Initiated Submission: `sforge-submit`

`sforge-submit` is installed in the Work container at `/usr/local/bin/sforge-submit`.

It:

- Archives code from `submit_paths`, excluding `submit_exclude`
- Submits it to the Judge Server
- Polls for evaluation results
- Displays pass rate, score, failed items, and summary
- Updates `/tmp/sforge_state.json`

Common commands:

| Command | Description |
|---------|-------------|
| `sforge-submit` | Submit and wait for result |
| `sforge-submit --details` / `-d` | Submit and wait for per-item details |
| `sforge-submit --no-wait` | Submit a snapshot and return its accepted ID |
| `sforge-submit --result ID --details` | Wait for an existing submission's feedback without resubmitting |
| `sforge-submit --result ID --no-wait --details` | Query once; return pending or terminal feedback |
| `sforge-submit --list` / `-l` | List previous submissions |

After asynchronous submission, continue independent work before checking the
same ID again. A pending response contains no score and does not update the
display cache. Later edits do not change the accepted snapshot; retain candidate
versions separately if you may need to restore them. See
[submission and result retrieval](../reference/judge-api.md#submitting-snapshots-and-reading-results).

## Auto-Eval: Adding Sampling Points

Auto-eval is a background evaluation daemon. Its purpose is not to inject extra feedback into the agent, but to **periodically record the current code state as additional evaluation samples**.

This is useful for long runs: even if the agent does not call `sforge-submit` at the right time, SForge still records intermediate versions instead of only the final state.

Properties:

- Default interval: `300` seconds
- Adjust with `--eval-interval`
- Disable with `--disable-auto-eval`
- Uses separate rounds: `auto-1`, `auto-2`, ...
- Results are not injected into the agent context
- Auto-eval submissions are not limited by `--max-submissions` or `--submission-cooldown`

```bash
# Sample every 600 seconds
sforge run --task ad_placement_optimization --agent claude-code --eval-interval 600

# Disable automatic sampling
sforge run --task ad_placement_optimization --agent claude-code --disable-auto-eval
```

## Keeping the Agent Working

### Stop hook

The stop hook prevents the agent from deciding it is done and exiting early. When the agent tries to exit, the hook tells it to keep working until the run timeout.

- Prevents premature natural exits
- Enabled by default for agents that support stop hooks
- Can be disabled for debugging or short runs

```bash
sforge run --task ad_placement_optimization --agent claude-code --disable-stop-hook
```

### Auto-resume

Auto-resume handles abnormal exits such as API disconnects, transient errors, or unexpected agent process termination. These exits can bypass the stop hook.

- After an abnormal exit, SForge resumes the session using the agent's native resume mechanism
- The remaining timeout budget is passed to the resumed session
- Enabled by default for agents with a `resume_cmd`
- Safety guards stop retrying after very fast exits or too many resume attempts

```bash
sforge run --task ad_placement_optimization --agent claude-code --disable-auto-resume
```

## Submission Count and Cooldown

Some tasks need to limit agent-initiated evaluations or prevent very frequent submissions. Use:

| Flag | Description |
|------|-------------|
| `--max-submissions N` | Limit the total number of agent-initiated submissions |
| `--submission-cooldown S` | Require at least S seconds between two agent-initiated submissions |

```bash
sforge run \
  --task ad_placement_optimization \
  --agent claude-code \
  --max-submissions 10 \
  --submission-cooldown 120
```

These limits apply only to agent-initiated `sforge-submit` calls. Auto-eval samples do not count toward the limit and do not observe the cooldown.

If a limit is hit, `sforge-submit` tells the agent how many submissions remain or how long to wait. The agent should continue local checks and improvements, then submit later.

## Scoring and Final Result

Each submission records pass rate, score, summary, and details.

| Metric | Description |
|--------|-------------|
| `pass_rate` | Fraction of tests passed |
| `score` | Continuous numeric score, often used by optimization tasks |
| `score_direction` | `maximize` or `minimize` |

The final result is the best result across all submissions, including:

- Agent-initiated submissions: `agent-1`, `agent-2`, ...
- Auto-eval samples: `auto-1`, `auto-2`, ...

The best-submission policy is controlled by `judge.selection` in the task JSON:

- `pass_rate_first`: prioritize pass rate, then score after 100% or equal pass rate
- `score_first`: compare score directly
- `valid_then_score`: filter invalid submissions, then compare score

## State File

`/tmp/sforge_state.json` inside the Work container tracks submission history:

```json
{
  "best_pass_rate": 0.95,
  "best_score": 250,
  "best_round": "agent-3",
  "submissions": []
}
```
