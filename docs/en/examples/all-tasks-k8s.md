---
title: "All Tasks (Kubernetes)"
---

# All Tasks (Kubernetes)

Run the full public EdgeBench suite (51 tasks) across a Kubernetes cluster.

::: tip Official leaderboard settings
The experiment YAMLs in this example are the **official EdgeBench leaderboard settings** (12-hour budget, stop hook + auto-eval enabled; CPU and memory come from each task's `task.toml`). For results comparable to the leaderboard, change only `env` and `model`.
:::

::: warning Cost
With frontier models (e.g. Claude Opus), one task over the full 12-hour budget can cost **hundreds to over a thousand USD** in API usage; a full 51-task run is a five-figure spend. Gauge your burn rate on one task with a short `--timeout` first.
:::

## Prerequisites

| Requirement | Check |
|-------------|-------|
| Linux host with `kubectl` configured | `kubectl cluster-info` |
| NetworkPolicy support (for network isolation) | CNI enforces NetworkPolicy; kubeconfig can create/delete `NetworkPolicy` in the target namespace |
| An address of this host that pods can reach | e.g. its private IP |
| Python 3.11–3.13 | `python --version` |

## Step-by-step

### 1. Install SForge

```bash
git clone https://github.com/ByteDance-Seed/EdgeBench.git
cd EdgeBench
pip install -e .
sforge list            # verify tasks are visible
```

### 2. Decide where pods pull images from

By default pods pull the pre-built images from `docker.io/seededge`. Docker Hub
rate-limits anonymous pulls and some images are large (about 15 GB for the Lean
tasks), so for repeated runs mirror them into a registry **in the same network** as
the cluster:

```bash
sforge pull --all                                  # from Docker Hub into local Docker (docker login first)
sforge push --all --registry <registry-ip>:5000
export SFORGE_K8S_IMAGE_REGISTRY=<registry-ip>:5000
```

Pods then pull `<registry-ip>:5000/<image>:<tag>`. Verify with:

```bash
curl -s http://<registry-ip>:5000/v2/_catalog | head -c 300
```

<details>
<summary>Setting up a private Docker registry</summary>

If you don't already have a private registry, you can start one with a
single command:

```bash
docker run -d -p 5000:5000 --restart=always --name registry registry:2
```

**Configuring insecure (HTTP) registries:** By default Docker only trusts
HTTPS registries. For a plain HTTP registry on your LAN, you need to
configure every machine that pushes or pulls (including K8s nodes) to
trust it:

1. Edit `/etc/docker/daemon.json` (create if it doesn't exist):

   ```json
   {
     "insecure-registries": ["<registry-ip>:5000"]
   }
   ```

2. Restart Docker:

   ```bash
   sudo systemctl restart docker
   ```

3. For K8s nodes using containerd, add the registry to
   `/etc/containerd/config.toml` **on every node in the cluster**
   (pods can be scheduled to any node):

   ```toml
   [plugins."io.containerd.grpc.v1.cri".registry.configs."<registry-ip>:5000".tls]
     insecure_skip_verify = true
   ```

   Then restart containerd: `sudo systemctl restart containerd`

</details>

### 3. Configure LLM-graded tasks

`college_english_exam_bank` is graded by an LLM; pass its credentials on this host
(see [LLM-Graded Tasks](/en/examples/single-task-docker#llm-graded-tasks)):

```bash
export SFORGE_JUDGE_EXTRA_ENV="SFORGE_JUDGE_API_KEY=your-key,SFORGE_JUDGE_API_BASE_URL=https://api.openai.com/v1,SFORGE_JUDGE_MODEL=gpt-5.5"
```

### 4. Run the experiment

The annotated [`experiment.yaml`](https://github.com/ByteDance-Seed/EdgeBench/blob/main/examples/all-tasks-k8s/experiment.yaml)
lists every task with its run settings; its fields are described in
[Experiment Configuration](/en/configuration/experiments).

```bash
sforge run --experiment examples/all-tasks-k8s/experiment.yaml \
  --judge-advertise <this-host-ip> --judge-port 8080 \
  --run-id edgebench-001
```

`sforge run` serves the judge on port 8080 of this host, and pods reach it at
`http://<this-host-ip>:8080`.

Tasks launch staggered over 600 seconds in total. Monitor progress with:

```bash
sforge viewer
# Open http://127.0.0.1:8000
```

Or watch a specific task's log:

```bash
tail -f logs/runs/edgebench-001/ad_placement_optimization/agent_output.txt
```


## Other Experiment Configs

The examples directory includes additional experiment configs for other
agents and third-party models:

- [`experiment-codex.yaml`](https://github.com/ByteDance-Seed/EdgeBench/blob/main/examples/all-tasks-k8s/experiment-codex.yaml) — Codex with GPT-5.5
- [`experiment-deepseek.yaml`](https://github.com/ByteDance-Seed/EdgeBench/blob/main/examples/all-tasks-k8s/experiment-deepseek.yaml) — Claude Code with DeepSeek V4 Pro (1M context)
- [`experiment-glm.yaml`](https://github.com/ByteDance-Seed/EdgeBench/blob/main/examples/all-tasks-k8s/experiment-glm.yaml) — Claude Code with GLM 5.1 (200K context)

```bash
sforge run --experiment examples/all-tasks-k8s/experiment-codex.yaml \
  --judge-advertise <this-host-ip> --judge-port 8080 \
  --run-id edgebench-codex-001
```

The `SFORGE_K8S_*` variables are listed in [Environment Variables](/en/configuration/environment-variables#container-backends).
