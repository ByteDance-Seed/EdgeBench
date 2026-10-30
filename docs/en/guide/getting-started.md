# Getting Started

This guide runs one EdgeBench task end to end on the default **Docker backend**: install SForge, get the task images, run an agent, and look at the result.

::: tip Scale
The Docker backend is meant for a small number of tasks. Running many tasks concurrently on one host (roughly 20+) will exhaust even a high-end server. Use the [Kubernetes backend](/en/configuration/container-backends) for full-suite runs, with the [official leaderboard settings](/en/examples/all-tasks-k8s).
:::

::: warning Cost
Frontier-model runs are expensive: one task over the official 12-hour budget can cost **hundreds to over a thousand USD** in API usage. Start with a single task and a short `--timeout` (as in this guide) to gauge your burn rate.
:::

## Prerequisites

- **Linux** (x86_64). SForge currently targets Linux hosts.

  ::: warning
  The Docker backend needs direct access to the host Docker daemon; running SForge inside a container introduces Docker-in-Docker issues.
  :::

- **Docker Engine**, running. Check with:

  ```bash
  docker run hello-world
  ```

- **Python 3.11–3.13**.

## Install SForge

The tasks live in the repository, so install from a clone:

```bash
git clone https://github.com/ByteDance-Seed/EdgeBench.git
cd EdgeBench
pip install -e .            # add the e2b extra for the E2B backend: pip install -e ".[e2b]"
```

Run the commands below from the repository root: SForge reads EdgeBench from `edgebench/` (another benchmark: `-b <dir>` or `SFORGE_BENCHMARK`). List its tasks with:

```bash
sforge list
```

## Run Ad Placement Optimization

[Ad Placement Optimization](https://github.com/ByteDance-Seed/EdgeBench/tree/main/edgebench/tasks/ad_placement_optimization) is a C++ optimization task, used here as a small end-to-end example.

### 1. Get the images

Pull the pre-built work and judge images:

```bash
sforge pull --task ad_placement_optimization
```

Images are tagged by a hash of the task directory, for example `edgebench.work.ad_placement_optimization:7b2f533ff7d4`, so the pulled images always match your checkout. If you changed the task, or prefer not to download, build them instead:

```bash
sforge build --task ad_placement_optimization
```

See [Pre-built Images](/en/features/prebuilt-images) for where the images come from.

### 2. Run an agent

```bash
SFORGE_AGENT_API_KEY="sk-ant-xxxx" \
sforge run --task ad_placement_optimization --agent claude-code \
  --model claude-opus-4-8 \
  --timeout 7200 \
  --run-id ad-placement-001
```

`sforge run` starts its own judge server in the same process. The agent works inside the work container, submits code with `sforge-submit`, gets a score and feedback, and keeps improving until the timeout. Its model requests go through the judge server, which holds the real API key; the key never enters the container.

## View Results

Start the run viewer:

```bash
sforge viewer
```

Then open `http://127.0.0.1:8000/` for score curves, submissions and token usage. To read the agent's own transcript in its UI:

```bash
sforge replay --run-id ad-placement-001 --task ad_placement_optimization
```

Run outputs are files under `logs/runs/<run-id>/<task-id>/`:

```bash
tail -f logs/runs/ad-placement-001/ad_placement_optimization/agent_output.txt
cat logs/runs/ad-placement-001/ad_placement_optimization/final_result.json
```

## Common Next Steps

- A different agent or model: [Supported Agents](./agents).
- API keys, proxies, resource limits: [Environment Variables](/en/configuration/environment-variables) and [Network Setup](/en/configuration/network-setup).
- Every command and flag: [CLI Commands](/en/reference/cli).
- Fixing or adding a task: [Task Format](/en/tasks/task-format).
