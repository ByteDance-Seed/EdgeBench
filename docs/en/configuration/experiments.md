---
title: Experiment Configuration
---

# Experiment Configuration

## Overview

Experiment configuration files provide a YAML-based way to run multiple tasks with shared model settings and per-task overrides. This decouples "how to run" (model, timeouts, agent settings) from "what to test" (the task directories).

::: tip Official leaderboard settings
The experiment YAMLs in the [all-tasks-k8s example](/en/examples/all-tasks-k8s) are the official configurations behind the EdgeBench leaderboard numbers.
:::

## YAML Format

```yaml
model:
  api_key: ${OPUS_KEY}
  api_base_url: https://api.anthropic.com
  model: claude-opus-4-6

stagger: 300  # Spread task launches evenly over 300 seconds

defaults:
  agent: claude-code
  timeout: 7200
  eval_interval: 300

env:
  SFORGE_K8S_NAMESPACE: "sforge-runs"

tasks:
  ad_placement_optimization:
    eval_interval: 1800
  smt_solver:
    work_cpu_limit: 16
  graph_node_classification: {}
```

## Explicit continuation to a finite timeout

The default auto-resume policy stops after at most 100 resumes. A long run
whose Agent repeatedly exits successfully can reach that ceiling before its
time budget. To use the timeout as the ceiling for successful exits, opt in:

```bash
sforge run --task <task-id> --agent codex --timeout 64800 --resume-until-timeout
```

The Python `run_agent` API accepts `resume_until_timeout=True`. The mode
requires an explicit positive integer `timeout` argument or `agent_timeout`
configuration and an Agent resume command. It conflicts with
`--disable-auto-resume`. The same container, registration and Agent resume
command are retained; submission limits, cooldown and scoring are unchanged.

One monotonic deadline starts after initial command preparation at the first
solver dispatch. Initial preparation and final collection remain separate
costs. Later command preparation and time between segments consume the same
deadline; resumes never renew it. Stop and remaining time are checked again
after preparation, immediately before dispatch. Cancellation, any nonzero process exit, an Agent-owned
terminal blocker, a timed-out segment, or a segment shorter than one second
can still end work early. This mode does **not** guarantee a minimum duration.
Keep any time deficit and failure evidence instead of treating an early exit
as a completed budget. Backend timeout drain can add collection cost after
solver work stops.

Stock Agents inherit no additional classifier for successful process output.
A quota message with exit code zero requires an explicit Agent
`resume_block_reason` implementation to block continuation; this flag does not
infer that condition from arbitrary text.

The opt-in run writes `resume-policy.json`; the CLI's `final_result.json` and
Python result include the same `resume_policy`. It records the original
deadline, actual resumes, process time, solver-phase elapsed time, full
invocation elapsed time, stop reason and unused seconds. No policy field or
file is added to default runs. To disable the mode, omit the flag or pass
`False` in Python.

This is in-process continuation, not checkpoint restoration. An existing
`started_at` or policy receipt rejects a new opted-in invocation in that run
directory. Preserve the old attempt; a cold restart needs a new run identity
and remains a separate experiment. Existing frozen runs are not upgraded or
relabelled by enabling this flag on a later run.

## Fields

### `env`

Environment variables set in the `sforge run` process before the rest of the file is read, so they work like exported variables (for example `SFORGE_K8S_IMAGE_REGISTRY` or `SFORGE_JUDGE_EXTRA_ENV`). Values are taken literally; `${VAR}` expansion applies only to the `model` section.

### `model`

Configures the LLM used by the agent. All string values support `${ENV_VAR}` expansion --- the referenced environment variable must be set at runtime.

| Field | Type | Description |
|-------|------|-------------|
| `api_key` | `string` | API key (supports `${ENV_VAR}` expansion) |
| `api_base_url` | `string` | API base URL |
| `model` | `string` | Model name (e.g., `claude-opus-4-6`, `claude-sonnet-4-20250514`) |

### `defaults`

Default settings applied to all tasks unless overridden per-task.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `agent` | `string` | --- | Agent name (`claude-code`, `codex`, `opencode`), optionally `@<version>` (e.g. `claude-code@2.1.258`) |
| `model` | `string` | --- | Model override (overrides `model.model` for specific tasks if set per-task) |
| `effort` | `string` | --- | Reasoning effort (`low`, `medium`, `high`, or `max`); mapped to the selected Agent when supported |
| `timeout` | `int` | --- | Agent timeout in seconds |
| `eval_interval` | `int` | --- | Auto-eval interval in seconds |
| `disable_stop_hook` | `bool` | `false` | Disable the agent stop hook |
| `disable_auto_eval` | `bool` | `false` | Disable background auto-evaluation |
| `disable_auto_resume` | `bool` | `false` | Disable auto-resume on abnormal agent exit |
| `internet` | `bool` | --- | Override the task's `internet` setting for the work container |
| `extra_env` | `dict` | --- | Extra environment variables injected into the agent container |
| `backend` | `string` | --- | Container backend (`docker`, `k8s`, or `e2b`) |
| `judge_url` | `string` | --- | External judge server URL (default: `sforge run` serves the judge itself) |
| `max_submissions` | `int` | --- | Maximum number of agent submissions per run |
| `submission_cooldown` | `int` | --- | Minimum seconds between agent submissions |
| `work_cpu_limit` | `int` | --- | CPU limit for work containers |
| `work_mem_limit` | `string` | --- | Memory limit for work containers |
| `judge_cpu_limit` | `int` | --- | CPU limit for judge containers |
| `judge_mem_limit` | `string` | --- | Memory limit for judge containers |

### `tasks`

Per-task overrides. Each key is a task ID, the name of a directory under the benchmark's `tasks/`. The value accepts the same fields as `defaults`. Tasks listed here define which tasks are run --- if `--task` is not specified on the CLI, the experiment's task list is used.

An empty object (`{}`) means "use all defaults, no overrides."

### `stagger`

A top-level integer field that spreads task launches evenly over the specified number of seconds when running multiple tasks. This prevents a thundering-herd of simultaneous container starts and API calls.

```yaml
stagger: 300  # Launch tasks at even intervals over 5 minutes
```

For example, with 6 tasks and `stagger: 300`, each task starts 50 seconds apart.

## Priority Chain

Configuration values are resolved in the following order (highest priority first):

```
CLI flags  >  per-task overrides  >  experiment defaults  >  task.toml / env vars / built-in defaults
```

For example:
- `--timeout 3600` on the CLI always wins
- A per-task `timeout: 1800` overrides the experiment-level `defaults.timeout`
- `work_cpu_limit` in the experiment overrides `cpus` in the task's `task.toml`

For `extra_env`, dictionaries are **merged** (not replaced). Per-task keys override default keys on conflict:

```yaml
defaults:
  extra_env:
    FOO: "from-defaults"
    BAR: "shared"

tasks:
  ad_placement_optimization:
    extra_env:
      FOO: "from-task"   # overrides defaults
      BAZ: "task-only"   # added
    # Result: FOO=from-task, BAR=shared, BAZ=task-only
```

## Usage

### Run all tasks in an experiment

```bash
sforge run --experiment experiments/my_config.yaml --run-id batch-001
```

When `--task` is not specified, all tasks listed in the experiment file are run in parallel.

### Run a subset of tasks

```bash
sforge run --experiment experiments/my_config.yaml --task ad_placement_optimization smt_solver
```

This uses the experiment's model and default settings but only runs the specified tasks.

### CLI overrides

```bash
sforge run \
  --experiment experiments/my_config.yaml \
  --timeout 3600 \
  --disable-stop-hook \
  --run-id experiment-v2
```

CLI flags take highest priority and override both per-task and default settings.

## Environment Variable Expansion

String values in the `model` section support `${VAR_NAME}` syntax:

```yaml
model:
  api_key: ${MY_API_KEY}
  api_base_url: ${API_ENDPOINT}
```

If a referenced variable is not set, SForge exits with an error. This lets you keep secrets out of config files while still having reproducible experiment definitions.

## Run Artifacts

A run with an experiment file also saves a copy of it and the fully resolved configuration; see [Run Outputs](/en/reference/cli#run-outputs).
