---
title: "Single Task (Docker)"
---

# Single Task (Docker)

Run one EdgeBench task (`ad_placement_optimization`) on your local machine using Docker.

::: tip Scale
The Docker backend is meant for trying out a **small number of tasks**. Running many tasks concurrently on one host (roughly 20+) will exhaust even a high-end server. For full-suite runs use the [Kubernetes example](/en/examples/all-tasks-k8s) with the official settings.
:::

::: warning Cost
Frontier-model runs are expensive — one task over the official 12-hour budget can cost hundreds to over a thousand USD in API usage. Start with a short `--timeout` (this example uses 2 hours) to gauge your burn rate before scaling up.
:::

## Prerequisites

| Requirement | Check |
|-------------|-------|
| Linux x86_64 host | - |
| Docker Engine running | `docker run hello-world` |
| Python 3.11–3.13 | `python --version` |

> **Note:** The Docker backend needs direct access to the host Docker daemon.
> Running SForge itself inside a container introduces Docker-in-Docker issues.

## Using Claude Code with Anthropic API

### 1. Install SForge

```bash
git clone https://github.com/ByteDance-Seed/EdgeBench.git
cd EdgeBench
pip install -e .
sforge list            # the tasks under edgebench/tasks
```

### 2. Get the images

```bash
sforge pull --task ad_placement_optimization
```

This pulls the task's work and judge images from `docker.io/seededge`
and tags them locally as:

- `edgebench.work.ad_placement_optimization:<hash>`
- `edgebench.judge.ad_placement_optimization:<hash>`

The hash comes from the task directory, so the images match your checkout. To build
them yourself instead (needed after you edit a task), run
`sforge build --task ad_placement_optimization`.

### 3. Run the agent

```bash
SFORGE_AGENT_API_KEY="sk-ant-xxxx" \
sforge run --task ad_placement_optimization --agent claude-code \
  --model claude-opus-4-8[1m] \
  --timeout 7200 \
  --run-id ad-placement-optimization-001
```

This launches Claude Opus 4.8 to work on the task for 2 hours, with a judge server
running inside the same `sforge run` process. You will see the agent's output
streamed to stdout in real time.

### 4. View results

```bash
sforge viewer
# Open http://127.0.0.1:8000
```

Or inspect files directly:

```bash
ls logs/runs/ad-placement-optimization-001/ad_placement_optimization/
cat logs/runs/ad-placement-optimization-001/ad_placement_optimization/final_result.json
```

`sforge replay --run-id ad-placement-optimization-001 --task ad_placement_optimization`
opens the agent's session in Claude Code itself.


## Using a Third-Party Model

To evaluate a non-Anthropic model with Claude Code, point the API base URL at the
provider's Anthropic-compatible endpoint. Two more things need configuring.

### 1. Model routing environment variables

Claude Code internally dispatches to different model tiers
(opus/sonnet/haiku) for subagent calls. By default these resolve to
Anthropic model IDs. Override **all** of them so every internal call
routes to your third-party model:

| Variable | Purpose |
|----------|---------|
| `ANTHROPIC_MODEL` | Primary model used by Claude Code |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | Model for opus-tier calls |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | Model for sonnet-tier calls |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | Model for haiku-tier calls |
| `CLAUDE_CODE_SUBAGENT_MODEL` | Model for subagent spawning |

### 2. Context window configuration

**For models with 1M context (e.g., DeepSeek V4 Pro):** Append `[1m]` to
the model name to enable Claude Code's 1M context mode, e.g.,
`deepseek-v4-pro[1m]`. Without this suffix, Claude Code defaults to the
200K context window.

**For models with 200K context (e.g., GLM 5.1):** Set these variables to
prevent Claude Code from exceeding the context limit:

| Variable | Value | Purpose |
|----------|-------|---------|
| `CLAUDE_CODE_AUTO_COMPACT_WINDOW` | `200000` | Context window size in tokens |
| `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` | `80` | Trigger compaction at 80% usage |

Without these settings, Claude Code may attempt to fill a larger default
context window and hit errors when the third-party model has a smaller
limit.

You don't need to configure prompt caching. By default Claude Code starts the
system prompt with an attribution block that changes on every request, which
defeats prefix caching on third-party providers; SForge turns it off.

### Example A: DeepSeek V4 Pro (1M context)

```bash
export SFORGE_AGENT_API_KEY="your-deepseek-key"
export SFORGE_AGENT_API_BASE_URL="https://api.deepseek.com/anthropic"
export SFORGE_AGENT_EXTRA_ENV="ANTHROPIC_MODEL=deepseek-v4-pro[1m],ANTHROPIC_DEFAULT_OPUS_MODEL=deepseek-v4-pro[1m],ANTHROPIC_DEFAULT_SONNET_MODEL=deepseek-v4-pro[1m],ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-v4-pro[1m],CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-pro[1m]"

sforge run --task ad_placement_optimization --agent claude-code \
  --model deepseek-v4-pro[1m] \
  --timeout 7200 \
  --run-id ad-placement-deepseek-001
```

### Example B: GLM 5.1 (200K context)

```bash
export SFORGE_AGENT_API_KEY="your-glm-key"
export SFORGE_AGENT_API_BASE_URL="https://open.bigmodel.cn/anthropic"
export SFORGE_AGENT_EXTRA_ENV="ANTHROPIC_MODEL=glm-5.1,ANTHROPIC_DEFAULT_OPUS_MODEL=glm-5.1,ANTHROPIC_DEFAULT_SONNET_MODEL=glm-5.1,ANTHROPIC_DEFAULT_HAIKU_MODEL=glm-5.1,CLAUDE_CODE_SUBAGENT_MODEL=glm-5.1,CLAUDE_CODE_AUTO_COMPACT_WINDOW=200000,CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=80"

sforge run --task ad_placement_optimization --agent claude-code \
  --model glm-5.1 \
  --timeout 7200 \
  --run-id ad-placement-glm-001
```


## Network Isolation

Most tasks are isolated: the work container can reach only the judge server. On Docker this uses host iptables rules and needs passwordless `sudo` for `iptables`; see [Network Isolation](/en/features/network-isolation).


## LLM-Graded Tasks

`college_english_exam_bank` is graded by an LLM: its grader runs the Codex CLI
inside the judge container against an OpenAI-Responses-compatible endpoint. The
harness gives judge containers no credentials of its own, so pass them with
`SFORGE_JUDGE_EXTRA_ENV` on the host that runs the judge (the `sforge run` host,
or the `sforge serve` host when you use `--judge-url`):

```bash
export SFORGE_JUDGE_EXTRA_ENV="SFORGE_JUDGE_API_KEY=your-key,SFORGE_JUDGE_API_BASE_URL=https://api.openai.com/v1,SFORGE_JUDGE_MODEL=gpt-5.5"
```

| Variable (inside judge container) | Purpose |
|-----------------------------------|---------|
| `SFORGE_JUDGE_API_KEY` | API key the grading script uses to call the LLM |
| `SFORGE_JUDGE_API_BASE_URL` | Base URL of the grading endpoint (default `https://openrouter.ai/api/v1`) |
| `SFORGE_JUDGE_MODEL` | Model ID used by the grading script |

Without them every submission to this task scores `valid=false`. Other tasks ignore
these variables, so it is safe to set them for all runs.
