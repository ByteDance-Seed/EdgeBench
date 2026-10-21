---
title: Experiment Configuration
---

# Experiment Configuration

## Overview

Experiment configuration files provide a YAML-based way to run multiple tasks with shared model settings and per-task overrides. This decouples "how to run" (model, timeouts, agent settings) from "what to test" (task JSON definitions).

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

tasks:
  ad_placement_optimization:
    eval_interval: 1800
  tinykv:
    extra_env:
      GOPROXY: "https://goproxy.cn"
  gitlet: {}
```

## Fields

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
| `agent` | `string` | --- | Agent name (`claude-code`, `codex`, `opencode`, or a pinned variant such as `claude-code-2.1.214`) |
| `model` | `string` | --- | Model override (overrides `model.model` for specific tasks if set per-task) |
| `effort` | `string` | --- | Reasoning effort (`low`, `medium`, `high`, or `max`); mapped to the selected Agent when supported |
| `timeout` | `int` | --- | Agent timeout in seconds |
| `eval_interval` | `int` | --- | Auto-eval interval in seconds |
| `disable_stop_hook` | `bool` | `false` | Disable the agent stop hook |
| `disable_auto_eval` | `bool` | `false` | Disable background auto-evaluation |
| `disable_auto_resume` | `bool` | `false` | Disable auto-resume on abnormal agent exit |
| `internet` | `bool` | --- | Enable/disable internet access |
| `extra_env` | `dict` | --- | Extra environment variables injected into the agent container |
| `backend` | `string` | --- | Container backend (`docker`, `k8s`, or `e2b`) |
| `judge_url` | `string` | --- | Judge server URL override |
| `max_submissions` | `int` | --- | Maximum number of agent submissions per run |
| `submission_cooldown` | `int` | --- | Minimum seconds between agent submissions |
| `work_cpu_limit` | `int` | --- | CPU limit for work containers |
| `work_mem_limit` | `string` | --- | Memory limit for work containers |
| `judge_cpu_limit` | `int` | --- | CPU limit for judge containers |
| `judge_mem_limit` | `string` | --- | Memory limit for judge containers |

### `tasks`

Per-task overrides. Each key is a task ID that must correspond to a JSON file in the tasks directory. The value accepts the same fields as `defaults`. Tasks listed here define which tasks are run --- if `--task` is not specified on the CLI, the experiment's task list is used.

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
CLI flags  >  per-task overrides  >  experiment defaults  >  env vars / task JSON
```

For example:
- `--timeout 3600` on the CLI always wins
- A per-task `timeout: 1800` overrides the experiment-level `defaults.timeout`
- The experiment `defaults.timeout` overrides `SFORGE_AGENT_TIMEOUT`

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

## Agent execution budget

After configuration resolution, `run_agent` chooses its explicit `timeout`, then
`SForgeConfig.agent_timeout`, then the selected Agent's default. The effective value
must be a positive integer in seconds; invalid values fail before registration or
container creation instead of silently selecting a fallback.

The runner writes this same budget into `agent_prompt.md` for both iterative and
game modes. It takes precedence over conflicting **whole-run Agent** time limits
in the task query or workspace documentation. Task text is preserved, and local
command, test, training, and judge limits still apply. The budget is an upper
limit; it does not require an Agent to use all available time or change the
configured stop-hook and auto-resume policy.

Execution time is shared across resumes. Agent installation and final grading
are outside the execution budget. Before each execution, the runner supplies:

| Environment variable | Meaning |
| --- | --- |
| `SFORGE_AGENT_BUDGET_SECONDS` | Total execution budget |
| `SFORGE_AGENT_REMAINING_SECONDS` | Remaining whole seconds allowed for this execution |
| `SFORGE_AGENT_SEGMENT_STARTED_AT` | Host Unix timestamp at dispatch |

These reserved values override matching `extra_env` keys at dispatch. They are
snapshots, not live counters. A resumed process receives updated values even if
its resume command does not reread the prompt; an Agent must read them to use
them in planning. Resumption deducts elapsed execution time rather than granting
a fresh total budget. Remaining fractions of a second are rounded down, and a
zero-second execution is not dispatched.

Changing the prompt's budget declaration changes the experiment protocol. Keep
old attempts and their original prompts; use distinct run IDs for budget-aligned
reruns. An outer timeout alone does not show what duration the Agent was told to use.

## Usage

### Run all tasks in an experiment

```bash
sforge run --experiment experiments/my_config.yaml --run-id batch-001
```

When `--task` is not specified, all tasks listed in the experiment file are run in parallel.

### Run a subset of tasks

```bash
sforge run --experiment experiments/my_config.yaml --task ad_placement_optimization tinykv
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

When running with an experiment config, SForge saves:

- `logs/runs/<run-id>/experiment.yaml` --- a copy of the experiment file
- `logs/runs/<run-id>/run_config.json` --- the fully resolved configuration for all tasks
- `logs/runs/<run-id>/<task-id>/run_config.json` --- per-task resolved configuration (with API keys redacted)
- `logs/runs/<run-id>/summary.json` --- final results summary (multi-task runs)

This ensures every run is fully reproducible from its log directory.
