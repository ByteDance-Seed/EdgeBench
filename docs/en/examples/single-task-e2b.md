---
title: "Single Task (E2B)"
---

# Single Task (E2B)

Run one EdgeBench task (`ad_placement_optimization`) in [E2B](https://e2b.dev) cloud Sandboxes. No local Docker daemon or Kubernetes cluster is needed; the only thing you host yourself is the Judge Server.

::: tip When to use E2B
E2B is the easiest way to run tasks when you cannot run Docker locally. Work, Judge, and Game environments are all created as E2B Sandboxes from pre-built official Templates. Concurrency and Sandbox lifetime are bounded by your E2B plan; see [Plan Limits and Run Sizing](/en/configuration/container-backends#plan-limits-and-run-sizing) before scaling up.
:::

::: warning Cost
Frontier-model runs are expensive — one task over the official 12-hour budget can cost hundreds to over a thousand USD in API usage, plus E2B Sandbox time. Start with a short `--timeout` (this example uses 2 hours) to gauge your burn rate before scaling up.
:::

## Prerequisites

| Requirement | Check |
|-------------|-------|
| E2B account and API key | `E2B_API_KEY` from the E2B dashboard |
| A host with a **publicly routable** address for the Judge Server | Sandboxes submit to it over the internet |
| Python >= 3.10 | `python --version` |

> **Note:** The agent timeout must fit within your E2B plan's maximum Sandbox
> lifetime, including time for evaluation and cleanup. Check your plan before
> running long tasks.

## Using Claude Code with Anthropic API

### 1. Install SForge with the E2B extra

```bash
pip install "sforge[e2b]"
```

### 2. Fetch task definitions

```bash
sforge fetch-tasks edgebench
```

Downloads the EdgeBench task JSONs and `BENCHMARK.yaml` into `./tasks/`.
Verify with:

```bash
sforge list
```

### 3. Configure E2B

E2B Sandboxes start from Templates, not Docker images, so there is no
`sforge pull` step. Official Templates for every published EdgeBench task are
already built; SForge derives the Template name from each task's image
reference. Set the following on **both** the Judge Server host and the run
host:

```bash
export E2B_API_KEY="e2b_xxxx"
export SFORGE_E2B_TEMPLATE_NAMESPACE=edgebench
```

If the Judge Server and `sforge run` are on **different machines**, they also
need a shared admin secret. The Judge Server only accepts registrations whose
secret matches its own, and each side otherwise generates its own random one
under `SFORGE_LOG_DIR/.judge-admin-secret`. Export the same value on both hosts:

```bash
export SFORGE_ADMIN_SECRET="$(openssl rand -base64 32)"   # same value on both hosts
```

When both run on the same machine with the same log directory, they share the
generated file automatically and nothing needs to be set. Never pass the secret
to the agent.

### 4. Start the judge server

On the publicly reachable host:

```bash
sforge serve --host 0.0.0.0 --port 8080
```

The Judge Server needs `E2B_API_KEY` too: when a run registers, it creates
the Judge and Game Sandboxes on E2B, evaluates each submitted archive in an
ephemeral Judge Sandbox, and returns scores. Make sure port 8080 is open to
the internet.

### 5. Run the agent

On the run host (can be the same machine), point `--judge-url` at the Judge
Server's public address:

```bash
SFORGE_AGENT_API_KEY="sk-ant-xxxx" \
sforge run --backend e2b \
  --task ad_placement_optimization --agent claude-code \
  --model claude-opus-4-8[1m] \
  --timeout 7200 \
  --judge-url http://YOUR_PUBLIC_HOST:8080 \
  --run-id ad-placement-optimization-e2b-001
```

This launches Claude Opus 4.8 in an E2B Work Sandbox for 2 hours.
You will see the agent's work output streamed to stdout in real time.

Each `sforge run` with `--backend e2b` evaluates tasks independently; passing
several task IDs schedules several separate Sandbox sets.

### 6. View results

You can view the progress in real time via the built-in web UI:

```bash
sforge visualizer
# Open http://127.0.0.1:8000
```

Or inspect files directly:

```bash
ls logs/runs/*/ad_placement_optimization/
cat logs/runs/*/ad_placement_optimization/final_result.json
```

Sandboxes are deleted automatically when the run finishes. If one lingers for
more than a minute, see [Troubleshooting](/en/configuration/container-backends#troubleshooting).


## Using a Third-Party Model

The model-routing and context-window settings are identical to the Docker
example; only the backend flags change. Follow
[Using a Third-Party Model](/en/examples/single-task-docker#using-a-third-party-model)
and add `--backend e2b --judge-url http://YOUR_PUBLIC_HOST:8080` to the
`sforge run` command, for example:

```bash
export SFORGE_AGENT_API_KEY="your-deepseek-key"
export SFORGE_AGENT_API_BASE_URL="https://api.deepseek.com/anthropic"
export SFORGE_CLAUDE_CACHE_OPT=1
export SFORGE_AGENT_EXTRA_ENV="ANTHROPIC_MODEL=deepseek-v4-pro[1m],ANTHROPIC_DEFAULT_OPUS_MODEL=deepseek-v4-pro[1m],ANTHROPIC_DEFAULT_SONNET_MODEL=deepseek-v4-pro[1m],ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-v4-pro[1m],CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-pro[1m]"

sforge run --backend e2b \
  --task ad_placement_optimization --agent claude-code \
  --model deepseek-v4-pro[1m] \
  --timeout 7200 \
  --judge-url http://YOUR_PUBLIC_HOST:8080 \
  --run-id ad-placement-deepseek-e2b-001
```


## Network Isolation

The `internet` field in each task JSON and the `--disable-internet` /
`--enable-internet` flags work the same as on Docker. On E2B, SForge applies
the allowlist through E2B's native `update_network` API instead of host
iptables, so nothing is left behind on your machine. E2B rules are host-level
rather than port-level: allowing a hostname allows all of its ports.

Host `HTTP_PROXY` / `HTTPS_PROXY` variables are **not** forwarded into
Sandboxes. If the model API must go through a proxy, it has to be reachable
from the internet and set explicitly via `SFORGE_HTTP_PROXY` /
`SFORGE_HTTPS_PROXY`. See [Network Isolation](/en/features/network-isolation#e2b-backend).


## LLM-Graded Tasks

LLM-graded tasks such as `college_english_exam_bank` need grading credentials
in the Judge environment, exactly as on Docker. Set `SFORGE_JUDGE_EXTRA_ENV`
**before starting the judge server**; see
[LLM-Graded Tasks](/en/examples/single-task-docker#llm-graded-tasks) for the
variables.
