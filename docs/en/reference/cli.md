---
title: CLI Commands
---

# CLI Commands

SForge has one entry point, `sforge <command>`. Commands that work on tasks (`list`, `pull`, `build`, `push`, `run`, `eval`, `serve`) take the benchmark directory with `-b DIR` / `--benchmark DIR` (default: `SFORGE_BENCHMARK`, else `edgebench`, the EdgeBench directory of this repository).

## Command Groups

### Evaluation

| Subcommand | Purpose | Key Flags |
|------------|---------|-----------|
| `list` | List the benchmark's tasks | none |
| `pull` | Pull pre-built task images | `--task` / `--all`, `--registry` |
| `run` | Run an agent on tasks | `--task`, `--experiment`, `--agent`, `--model`, `--timeout`, `--backend` |
| `eval` | Grade a solution archive directly | `--task`, `--archive`, `--json` |
| `serve` | Start a standalone judge server | `--host`, `--port` |
| `viewer` | Start the run viewer web UI | `--runs-dir`, `--host`, `--port` |
| `replay` | Open a run's agent session in the agent's own UI | `--run-id`, `--task`, `--session` |

### Task development

| Subcommand | Purpose | Key Flags |
|------------|---------|-----------|
| `build` | Build base, work and judge images from the task directories | `--task` / `--all`, `--force-rebuild`, `--force-rebuild-with-base` |
| `push` | Push images to a registry | `--task` / `--all`, `--registry` |

## Global Options

These flags go before the subcommand (`sforge --log-dir ... run ...`):

| Flag | Default | Description |
|------|---------|-------------|
| `--log-dir` | `logs/` | Build logs and run outputs |
| `--silent` | `false` | Suppress verbose output (auto-enabled for multi-task runs) |

## sforge list

```bash
sforge list
```

Output columns: ID, Name, Base, Version.

## sforge pull

Pull the work and judge images of tasks and tag them with their local keys.

```bash
sforge pull --task ad_placement_optimization
sforge pull --task ad_placement_optimization smt_solver
sforge pull --all
```

| Flag | Description |
|------|-------------|
| `--task` | One or more task IDs |
| `--all` | All tasks |
| `--registry` | Registry prefix (default: `SFORGE_REGISTRY`, else the benchmark's `registry`) |

Tags are content hashes of the task directory, so only images matching your checkout are pulled. See [Pre-built Images](/en/features/prebuilt-images).

## sforge run

Run an agent on one or more tasks; each task gets its own containers and results.

```bash
# One task
sforge run --task ad_placement_optimization --agent claude-code

# Several independent task runs
sforge run --task ad_placement_optimization smt_solver --agent claude-code

# Experiment file
sforge run --experiment examples/all-tasks-k8s/experiment.yaml
```

Unless `--judge-url` is given, `sforge run` serves the judge itself on a thread of the same process.

| Flag | Default | Description |
|------|---------|-------------|
| `--task` | required* | One or more task IDs. Several IDs batch-schedule independent task runs |
| `--agent` | required* | `claude-code`, `codex` or `opencode`, optionally `@<version>` (e.g. `codex@0.145.0`). Not needed with `--experiment` |
| `--experiment` | --- | Experiment YAML. Without `--task`, all of its tasks run; with `--task`, only those, with the experiment's settings |
| `--model` | agent default | Model name |
| `--effort` | agent default | Reasoning effort: `low`, `medium`, `high` or `max` |
| `--timeout` | agent default | Agent time budget in seconds |
| `--run-id` | random | Run identifier; outputs go to `logs/runs/<run-id>/` |
| `--backend` | `docker` | `docker`, `k8s` or `e2b` |
| `--judge-port` | any free port | Port of the in-process judge |
| `--judge-advertise` | `host.docker.internal` | Address of this machine that sandboxes use to reach the in-process judge. Required for `k8s` and `e2b` |
| `--judge-url` | --- | Use an external judge server (`sforge serve`) at this URL, as seen from inside the sandboxes |
| `--eval-interval` | `300` | Auto-eval interval in seconds |
| `--stagger` | --- | Spread task launches evenly over N seconds |
| `--max-submissions` | unlimited | Maximum number of agent submissions per task |
| `--submission-cooldown` | none | Minimum seconds between agent submissions |
| `--work-cpu-limit` | task / none | CPUs for work containers |
| `--work-mem-limit` | task / none | Memory for work containers (e.g. `8g`) |
| `--judge-cpu-limit` | task / none | CPUs for judge containers |
| `--judge-mem-limit` | task / none | Memory for judge containers |
| `--disable-stop-hook` | `false` | Let the agent exit normally |
| `--disable-auto-eval` | `false` | Turn off the background auto-eval |
| `--disable-auto-resume` | `false` | Do not relaunch the agent after an abnormal exit |
| `--disable-internet` | `false` | Isolate every task's work container (only the judge is reachable). On Docker this needs passwordless `sudo` for iptables |
| `--enable-internet` | `false` | Give every task's work container internet access. Mutually exclusive with `--disable-internet` |

### Run Outputs

```
logs/runs/<run_id>/
├── run_config.json          # resolved configuration of all tasks
├── experiment.yaml          # copy of the experiment file, if any
├── summary.json             # multi-task summary
└── <task_id>/
    ├── run_config.json      # this task's effective configuration (keys redacted)
    ├── run_agent.log        # harness log
    ├── agent_prompt.md      # prompt sent to the agent
    ├── agent_output.txt     # agent stdout (JSON lines for Claude Code and Codex)
    ├── sessions/            # the agent's native session files, synced every 60 s
    ├── llm_requests.jsonl   # one line per model request, with token usage
    ├── run_history.json     # every submission
    ├── final_archive.tar.gz # final snapshot of the workspace
    ├── final_result.json    # best score, rounds, runtime, token usage
    └── submissions/
        ├── agent-1/         # judge_output.txt, result.json, report.json
        ├── auto-1/
        └── ...
```

## sforge eval

Grade an archive with a task's judge, without running an agent. Useful for testing solutions and judge changes.

```bash
sforge eval --task ad_placement_optimization --archive solution.tar.gz
sforge eval --task ad_placement_optimization --archive solution.tar.gz --json
sforge eval --task ad_placement_optimization --archive - < solution.tar.gz
```

| Flag | Description |
|------|-------------|
| `--task` | Task ID (required) |
| `--archive` | `.tar.gz` archive of the workspace, or `-` for stdin. It is filtered by the task's submission paths like an agent submission |
| `--run-id` | Run ID for log organization |
| `--timeout` | Evaluation timeout in seconds (default: the task's `timeout_sec`) |
| `--json` | Also print the full JSON report |
| `--backend` | `docker`, `k8s` or `e2b` |
| `--judge-cpu-limit` | CPUs for the judge container |
| `--judge-mem-limit` | Memory for the judge container (e.g. `4g`) |

## sforge serve

Start a standalone judge server, for sharing one judge between several `sforge run` processes or hosts. Runs attach to it with `--judge-url`.

```bash
sforge serve
sforge serve --host 0.0.0.0 --port 9090
```

| Flag | Default | Description |
|------|---------|-------------|
| `--host` | `0.0.0.0` | Bind address |
| `--port` | `8080` | Listen port |

The server exposes the [Judge HTTP API](/en/reference/judge-api): submissions, game sessions and the LLM gateway. It and its runs must share `SFORGE_ADMIN_SECRET` (automatic on one machine with the same log directory).

## sforge viewer

```bash
sforge viewer
sforge viewer --runs-dir logs/runs --port 8000
```

| Flag | Default | Description |
|------|---------|-------------|
| `--runs-dir` | `<log dir>/runs` | Run folders |
| `--host` | `127.0.0.1` | Bind address |
| `--port` | `8000` | Listen port |

See [Viewer and Replay](/en/features/viewer).

## sforge replay

Open a run's archived agent session in the agent's own UI (`claude --resume` or `codex resume`).

```bash
sforge replay --run-id ad-placement-001 --task ad_placement_optimization
```

| Flag | Description |
|------|-------------|
| `--run-id` | Run ID (required) |
| `--task` | Task ID (required) |
| `--session` | Session ID (default: the latest one) |
| `--runs-dir` | Run folders (default: `<log dir>/runs`) |

## sforge build

Build the base, work and judge images of tasks with local Docker. Missing blobs are downloaded first.

```bash
sforge build --task ad_placement_optimization
sforge build --task ad_placement_optimization smt_solver
sforge build --all
sforge build --task ad_placement_optimization --force-rebuild
```

| Flag | Description |
|------|-------------|
| `--task` | One or more task IDs |
| `--all` | All tasks |
| `--force-rebuild` | Rebuild work and judge images even if their tags exist (not the base) |
| `--force-rebuild-with-base` | Rebuild all images including the base |

Build logs go to `logs/build_images/<image>_<tag>.log`.

## sforge push

Push the base, work and judge images of tasks under a registry prefix (`<registry>/<image>:<tag>`), like the pre-built images.

```bash
sforge push --task ad_placement_optimization --registry registry.example.com/sforge
sforge push --all --registry registry.example.com/sforge
```

| Flag | Description |
|------|-------------|
| `--task` | One or more task IDs |
| `--all` | All tasks |
| `--registry` | Registry prefix (default: `SFORGE_REGISTRY`, else the benchmark's `registry`) |
