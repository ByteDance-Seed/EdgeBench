# Getting Started

This guide runs one SForge task end to end using the default **Docker backend**: install SForge, fetch task definitions, pull pre-built task images, start the judge server, run an agent, and inspect the result.

::: tip Scale
The Docker backend is meant for a small number of tasks. Running many tasks concurrently on one host (roughly 20+) will exhaust even a high-end server — use the [Kubernetes backend](/en/configuration/container-backends) for full-suite runs, with the [official leaderboard settings](/en/examples/all-tasks-k8s).
:::

::: warning Cost
Frontier-model runs are expensive: one task over the official 12-hour budget can cost **hundreds to over a thousand USD** in API usage. Start with a single task and a short `--timeout` (as in this guide) to gauge your burn rate.
:::

## Prerequisites

- **Linux**: SForge currently targets Linux hosts.

  ::: warning
  The default Docker backend needs direct access to the host Docker daemon; running inside a container introduces Docker-in-Docker issues.
  :::

- **Docker Engine**: required to pull task images and run work/judge containers. The Docker daemon must be running; verify it with:

  ```bash
  docker run hello-world
  ```

- **Python >= 3.10**.

## Install SForge

Install the released package:

```bash
pip install sforge
```

To use the [E2B backend](/en/configuration/container-backends#e2b-backend), include the `e2b` extra: `pip install "sforge[e2b]"`.

Or install from source:

```bash
git clone https://github.com/ByteDance-Seed/EdgeBench.git
cd SForge
pip install -e .
```

Check that the CLI is available:

```bash
sforge --help
```

## Run Ad Placement Optimization

[Ad Placement Optimization](https://huggingface.co/datasets/ByteDance-Seed/EdgeBench/blob/main/ad_placement_optimization.json) is a C++ optimization task in EdgeBench, used here as a small end-to-end example.

### 1. Fetch Task Definitions

```bash
sforge fetch-tasks edgebench
```

This downloads the default `edgebench` task definitions into `./tasks`. You can confirm that tasks are visible with:

```bash
sforge list
```

### 2. Pull Images

```bash
sforge pull --task ad_placement_optimization --registry seededge
```

This pulls the pre-built base, work, and judge images for the task. Image names are derived from the benchmark name, role, task/base key, and content hash, for example:

- `<benchmark>.base.cpp:<hash>`
- `<benchmark>.work.ad_placement_optimization:<hash>`
- `<benchmark>.judge.ad_placement_optimization:<hash>`

### 3. Start the Judge Server

Open a second terminal:

```bash
sforge serve
```

The judge server listens on `0.0.0.0:8080` by default.

### 4. Run an Agent

In the first terminal:

```bash
SFORGE_AGENT_API_KEY="sk-ant-xxxx" \
sforge run --task ad_placement_optimization --agent claude-code \
  --model claude-opus-4-8 \
  --timeout 7200 \
  --run-id ad-placement-001
```

The agent works inside the work container, submits code to the judge server, receives test feedback, and iterates until timeout or completion.

## View Results

Start the web UI to monitor runs in real time:

```bash
sforge visualizer
```

Then open `http://127.0.0.1:8000/`.

Run outputs are also written under `logs/runs/<run-id>/<task-id>/` if you prefer inspecting files manually:

```bash
tail -f logs/runs/ad-placement-001/ad_placement_optimization/agent_output.txt
cat logs/runs/ad-placement-001/ad_placement_optimization/final_result.json
```

## Common Next Steps

- Need a different agent or model? See [Supported Agents](./agents).
- Need API keys, mirrors, proxy variables, or resource limits? See [Environment Variables](/en/configuration/environment-variables) and [Network Setup](/en/configuration/network-setup).
- Need the full command and flag list? See [CLI Commands](/en/reference/cli).
- Developing a new benchmark or task? See the [Developer section](/en/tasks/integration-guide).
