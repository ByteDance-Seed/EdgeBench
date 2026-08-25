---
title: CLI Commands
---

# CLI Commands

SForge exposes one CLI entry point: `sforge <command>`.

For most evaluation users, the core workflow only needs four commands:

```bash
sforge fetch-tasks edgebench
sforge pull --task ad_placement_optimization --registry seededge
sforge serve
sforge run --task ad_placement_optimization --agent claude-code
```

Developer-oriented commands such as `build`, `push`, and `hub` are grouped at the end of this page. They are mainly useful when authoring tasks, maintaining a benchmark, or operating shared infrastructure.

## Command Groups

### Evaluation workflow

| Subcommand | Purpose | Key Flags |
|------------|---------|-----------|
| `fetch-tasks` | Download benchmark task definitions | `benchmark`, `--repo`, `--revision` |
| `list` | List available task definitions | none |
| `pull` | Pull pre-built task images from a registry | `--task`, `--registry` |
| `serve` | Start the Judge HTTP server | `--host`, `--port` |
| `run` | Run an agent on tasks | `--task`, `--experiment`, `--agent`, `--model`, `--timeout`, `--judge-url` |
| `eval` | Evaluate a solution archive directly | `--task`, `--archive`, `--run-id`, `--timeout`, `--json` |
| `proxy` | Start a host-side LLM API reverse proxy | `--target`, `--host`, `--port` |
| `visualizer` | Start the local results viewer | `--runs-dir`, `--tasks-dir`, `--host`, `--port` |

### Developer / benchmark maintenance

| Subcommand | Purpose | Key Flags |
|------------|---------|-----------|
| `build` | Build base, work, and judge images locally | `--task`, `--force-rebuild`, `--force-rebuild-with-base` |
| `push` | Push locally-built images to a registry | `--task`, `--registry` |

## Global Options

These flags are available for all subcommands:

| Flag | Default | Description |
|------|---------|-------------|
| `--log-dir` | `logs/` | Override log output directory |
| `--tasks-dir` | `tasks/` | Override task definitions directory |
| `--silent` | `false` | Suppress verbose output (auto-enabled for multi-task runs) |

## sforge fetch-tasks

Download benchmark task definitions from HuggingFace Hub. For EdgeBench:

```bash
sforge fetch-tasks edgebench
```

Advanced usage:

```bash
sforge fetch-tasks --repo ByteDance-Seed/EdgeBench --revision main
```

| Flag / Argument | Description |
|-----------------|-------------|
| `benchmark` | Benchmark name, for example `edgebench` |
| `--repo` | HuggingFace dataset repo ID. Overrides benchmark lookup |
| `--revision` | Git revision, branch, tag, or commit hash to download |

## sforge list

List available tasks.

```bash
sforge list
```

Output columns: ID, Name, Base Image, Parser.

## sforge pull

Pull pre-built images from a remote container registry. In the standard evaluation workflow, run this after `sforge fetch-tasks edgebench` and before `sforge serve` / `sforge run`.

```bash
sforge pull --task ad_placement_optimization --registry seededge
sforge pull --task ad_placement_optimization gitlet --registry seededge
```

| Flag | Description |
|------|-------------|
| `--task` | One or more task IDs (required) |
| `--registry` | Remote container registry or configured registry alias (overrides `SFORGE_REGISTRY` env var) |

Each image is tagged by a content hash, so only images matching the current task definition are pulled.

## sforge serve

Start the Judge HTTP server. This must be running before `sforge run` is invoked --- the agent container connects to it to submit code for evaluation.

```bash
sforge serve
sforge serve --port 8080
sforge serve --host 0.0.0.0 --port 9090
```

| Flag | Default | Description |
|------|---------|-------------|
| `--host` | `0.0.0.0` | Bind address |
| `--port` | `8080` | Listen port |

The server exposes the [Judge HTTP API](/en/reference/judge-api) and handles both standard test-driven submissions and interactive game sessions.

## sforge run

Run an agent on one task, or batch-schedule independent evaluations for several
tasks. Each task always has its own Work environment, Judge session, results,
and cleanup lifecycle.

### Basic usage

```bash
# Standard agent mode
sforge run --task ad_placement_optimization --agent claude-code

# Batch-schedule independent task runs
sforge run --task ad_placement_optimization gitlet rookiedb --agent claude-code

# Experiment config mode
sforge run --experiment experiment.yaml
```

### Full options

| Flag | Default | Description |
|------|---------|-------------|
| `--task` | required* | One or more task IDs (space-separated). Multiple IDs batch-schedule independent task runs; they are not combined into one evaluation. |
| `--agent` | required* | Agent name (e.g., `claude-code`, `codex`). Required unless `--experiment` is specified. |
| `--experiment` | --- | Path to experiment YAML config file. If `--task` is omitted, all YAML tasks run; if `--task` is provided, only that subset runs with the experiment settings. |
| `--model` | --- | Model override (e.g., `claude-opus-4-8`) |
| `--timeout` | `3600` | Agent timeout in seconds |
| `--eval-interval` | `300` | Auto-eval daemon interval in seconds |
| `--run-id` | random | Run identifier for tracking and log organization |
| `--judge-url` | `http://host.docker.internal:8080` | Judge server URL as seen from inside the container |
| `--backend` | `docker` | Container backend (`docker`, `k8s`, or `e2b`) |
| `--stagger` | --- | Spread task launches evenly over N seconds (e.g., `--stagger 300`) |
| `--max-submissions` | --- | Maximum number of agent submissions per run |
| `--submission-cooldown` | --- | Minimum seconds between agent submissions |
| `--work-cpu-limit` | --- | Number of CPUs for work containers |
| `--work-mem-limit` | --- | Memory limit for work containers (e.g., `'8g'`) |
| `--judge-cpu-limit` | --- | Number of CPUs for judge containers |
| `--judge-mem-limit` | --- | Memory limit for judge containers (e.g., `'4g'`) |
| `--disable-stop-hook` | `false` | Disable the stop hook (allow agent to exit normally) |
| `--disable-auto-eval` | `false` | Disable the background auto-evaluation daemon |
| `--disable-auto-resume` | `false` | Disable auto-resume on abnormal agent exit |
| `--disable-internet` | `false` | Force network isolation (only judge server + API allowed). Requires `sudo` for iptables. Mutually exclusive with `--enable-internet`. |
| `--enable-internet` | `false` | Force full internet access (overrides per-task `internet: false` setting). Mutually exclusive with `--disable-internet`. |

::: warning Requirement
`--task` or `--experiment` is required. `--agent` is required unless `--experiment` is specified.
:::

### Output files

After completion, results are written to `logs/runs/<run_id>/<task_id>/`:

```
logs/runs/<run_id>/<task_id>/
├── run_config.json      # Effective configuration for this run
├── run_agent.log        # Harness-level log
├── install_output.txt   # Agent installation output
├── agent_prompt.md      # Enhanced prompt sent to agent
├── agent_output.txt     # Full agent conversation log
├── final_archive.tar.gz # Final code snapshot
├── final_result.json    # Summary with best_pass_rate, total_rounds, etc.
└── submissions/         # Per-round evaluation details
```

## sforge eval

Evaluate an archive directly against a task's test suite, without running an agent. Useful for testing solutions manually.

```bash
sforge eval --task ad_placement_optimization --archive solution.tar.gz
sforge eval --task ad_placement_optimization --archive solution.tar.gz --json
sforge eval --task ad_placement_optimization --archive - < solution.tar.gz
```

| Flag | Description |
|------|-------------|
| `--task` | Task ID (required) |
| `--archive` | Path to `.tar.gz` archive, or `-` to read from stdin |
| `--run-id` | Custom run ID for log organization |
| `--timeout` | Evaluation timeout in seconds |
| `--json` | Also output the full JSON report |
| `--backend` | Container backend (`docker`, `k8s`, or `e2b`) |
| `--judge-cpu-limit` | Number of CPUs for judge container |
| `--judge-mem-limit` | Memory limit for judge container (e.g., `'4g'`) |

## sforge proxy

Start a local API reverse proxy. This is designed for use with `--disable-internet`.

```bash
sforge proxy --target https://api.anthropic.com --port 9090
```

| Flag | Default | Description |
|------|---------|-------------|
| `--target` | required | Upstream API URL to forward to |
| `--host` | `0.0.0.0` | Bind address |
| `--port` | `9090` | Listen port |

Requires `SFORGE_HTTPS_PROXY` (or `HTTPS_PROXY`) to be configured.

## sforge visualizer

Start a web-based results viewer for browsing run outputs and comparing scores across tasks and runs.

```bash
sforge visualizer
sforge visualizer --runs-dir logs/runs --port 8000
```

| Flag | Default | Description |
|------|---------|-------------|
| `--runs-dir` | `logs/runs` | Directory containing run folders |
| `--tasks-dir` | `tasks/` | Directory of task JSON definitions (used for score direction) |
| `--host` | `127.0.0.1` | Bind address |
| `--port` | `8000` | Listen port |

Open `http://127.0.0.1:8000/` in your browser after starting.

## Developer Commands

The following commands are mainly for users who develop tasks, maintain benchmark JSON definitions, or operate shared infrastructure.

### sforge build

Build Docker images (base + work + judge) for one or more tasks. Evaluation users normally use `sforge pull` instead.

```bash
sforge build --task ad_placement_optimization
sforge build --task ad_placement_optimization gitlet rookiedb
sforge build --task ad_placement_optimization --force-rebuild
```

| Flag | Description |
|------|-------------|
| `--task` | One or more task IDs (required, space-separated) |
| `--force-rebuild` | Force rebuild work + judge images (skip base) |
| `--force-rebuild-with-base` | Force rebuild ALL images including base |

### sforge push

Push locally-built images to a remote container registry.

```bash
sforge push --task ad_placement_optimization --registry registry.example.com/sforge
sforge push --task ad_placement_optimization gitlet --registry registry.example.com/sforge
```

| Flag | Description |
|------|-------------|
| `--task` | One or more task IDs (required) |
| `--registry` | Remote container registry URL (overrides `SFORGE_REGISTRY` env var) |
