---
title: Environment Variables
---

# Environment Variables

## Overview

Most SForge configuration can be injected via `SFORGE_*` environment variables. CLI-only fields, such as judge CPU/memory limits, are called out below. The resolution priority is:

```
defaults  <  env vars  <  experiment YAML  <  CLI flags
```

Proxy, mirror, API key, path, backend, registry, and hub settings can be overridden at runtime.

## Build Stage Variables

These variables are passed as Docker build args during `sforge build`. They affect image construction but are **not** baked into the final image.

| Variable | Purpose |
|----------|---------|
| `SFORGE_HTTP_PROXY` | HTTP proxy for Docker build |
| `SFORGE_HTTPS_PROXY` | HTTPS proxy for Docker build |
| `SFORGE_NO_PROXY` | Addresses to bypass proxy |
| `SFORGE_PYPI_INDEX_URL` | PyPI mirror URL (sets `PIP_INDEX_URL` at build time) |
| `SFORGE_MAVEN_MIRROR_URL` | Maven repository mirror (sets `MAVEN_MIRROR_URL` at build time) |
| `SFORGE_GO_PROXY` | Go module proxy (sets `GOPROXY` at build time) |
| `SFORGE_APT_MIRROR_URL` | APT source mirror (rewrites `/etc/apt/sources.list` in base image) |
| `SFORGE_GIT_USER` | Git username for private repos |
| `SFORGE_GIT_TOKEN` | Git access token (injected as BuildKit secret, **not** stored in image) |
| `SFORGE_EXTRA_HOSTS` | DNS overrides during build, format: `"host1:ip1,host2:ip2"` |

### How build args work

Proxy variables (`HTTP_PROXY`, `HTTPS_PROXY`, `NO_PROXY`) are Docker predefined build args --- they are automatically available to `RUN` commands but do not persist in the final image layer.

Package mirror variables (`PIP_INDEX_URL`, `GOPROXY`, `MAVEN_MIRROR_URL`) are declared as `ARG` directives, making them available during `RUN` but also not persisted.

## Run Stage Variables

Used when running agents via `sforge run`. These are injected as container environment variables.

| Variable | Purpose |
|----------|---------|
| `SFORGE_AGENT_API_KEY` | API key passed to the selected agent using that agent's expected env var (`ANTHROPIC_AUTH_TOKEN` for Claude Code, `CODEX_API_KEY` for Codex, `ANTHROPIC_API_KEY` for OpenCode) |
| `SFORGE_AGENT_API_BASE_URL` | API base URL override passed through the selected agent's base-url env var when it has one |
| `SFORGE_AGENT_MODEL` | Model override for the agent |
| `SFORGE_AGENT_EFFORT` | Reasoning effort (`low`, `medium`, `high`, or `max`) |
| `SFORGE_AGENT_TIMEOUT` | Agent timeout in seconds |
| `SFORGE_AGENT_EXTRA_ENV` | Extra env vars for agent container, format: `"KEY1=VAL1,KEY2=VAL2"` |
| `SFORGE_HTTP_PROXY` | HTTP proxy injected into the agent container at run time. Not recommended for normal use; incompatible with `--disable-internet`. |
| `SFORGE_HTTPS_PROXY` | HTTPS proxy injected into the agent container at run time. Not recommended for normal use; incompatible with `--disable-internet`. |
| `SFORGE_NO_PROXY` | Addresses that bypass the run-time proxy |
| `SFORGE_NODEJS_MIRROR_URL` | Node.js download mirror (used during agent runtime install) |
| `SFORGE_NPM_REGISTRY_URL` | NPM registry mirror (sets `npm_config_registry` in container) |
| `SFORGE_CLAUDE_CACHE_OPT` | Suppress Claude Code attribution header and dynamic system prompt sections for better caching on third-party proxies. Set to `1` to enable. |

::: warning Direct run-time proxies
Directly injecting `SFORGE_HTTP_PROXY` / `SFORGE_HTTPS_PROXY` into the agent container gives that container proxy-mediated network access. This is useful only for exceptional run-time dependency downloads and is **not recommended** for LLM API access.

It is also incompatible with network isolation (`--disable-internet`). If the agent needs to call an LLM API through a corporate proxy while network isolation is enabled, run `sforge proxy` on the host and point `SFORGE_AGENT_API_BASE_URL` to `http://host.docker.internal:<port>` instead.

For E2B, generic host `HTTP_PROXY` / `HTTPS_PROXY` variables are not forwarded
to Work Sandboxes. Set the `SFORGE_` variants only when the proxy is reachable
from E2B; isolated E2B runs always remove proxy variables and use the native
host allowlist directly.
:::

## Judge Variables

| Variable | Purpose |
|----------|---------|
| `SFORGE_JUDGE_EXTRA_ENV` | Extra env vars for judge containers, format: `"KEY1=VAL1,KEY2=VAL2"` |
| `SFORGE_ADMIN_SECRET` | Trusted-host credential for Judge session registration and auto-eval. If omitted, SForge creates a mode-`0600` secret under `SFORGE_LOG_DIR`. Never expose it to Work containers. |

## Resource Limit Variables

| Variable | Purpose |
|----------|---------|
| `SFORGE_WORK_CPU_LIMIT` | Number of CPUs for work containers (e.g., `4`) |
| `SFORGE_WORK_MEM_LIMIT` | Memory limit for work containers (e.g., `8g`) |

Judge CPU/memory limits are currently set through CLI flags (`--judge-cpu-limit`, `--judge-mem-limit`) or experiment YAML (`judge_cpu_limit`, `judge_mem_limit`), not environment variables.

## Judge admission and resource limits

`serve` now defaults to **2 active evaluations and 32 additional pending snapshots**
per server process, instead of creating an evaluation thread for every submission.
Set the capacity according to available memory and the per-container limits:

```bash
sforge serve --judge-max-concurrent 1 --judge-max-pending 32
```

The equivalent environment variables are `SFORGE_JUDGE_MAX_CONCURRENT` (>= 1)
and `SFORGE_JUDGE_MAX_PENDING` (>= 0). These are server settings; registration
cannot raise them. Multiple server processes have independent limits. They apply
across tasks, runs and both agent/auto submissions; interactive game sessions
and direct synchronous `sforge eval` are separate paths.

Accepted snapshots are spooled under the log directory and evaluated in admission
order by a fixed worker pool. Pending snapshots do not retain their archive bytes
in RAM. Results transition from `queued` to `running` before reaching a terminal
state. The visualizer excludes missing/invalid reports rather than plotting them as zeros.
Reports retain the admission timestamp for timelines; runtime still measures
execution. No snapshots are deduplicated, coalesced, or assigned cached scores.

At capacity, submission returns **503 with Retry-After**, without allocating a
round, consuming submission budget, or starting a cooldown. Clients must retain
and retry the same snapshot if they need lossless sampling; the existing periodic
auto-evaluator logs failed ticks and does not retry them. A queue bounds resource
use, not scoring latency: if arrivals exceed throughput, reduce sampling or add
qualified capacity. Larger pending limits also require disk space.

Graceful shutdown drains accepted work. Sessions, queue metadata, and counters
remain in memory, so this is **not restart recovery**; orphan spool files alone
are not enough to reconstruct a run. Drain before restarting. This does not change
task/scoring rules, per-evaluation limits, or feedback visibility. To revert the
scheduling change, drain, stop, and deploy the previous server revision; there is
no unlimited-concurrency switch.

## Container Backend Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `SFORGE_BACKEND` | `docker` | Container backend: `docker`, `k8s`, or official `e2b` |
| `SFORGE_K8S_NAMESPACE` | `default` | Kubernetes namespace |
| `SFORGE_K8S_IMAGE_REGISTRY` | --- | Container registry for K8s image pulls |
| `SFORGE_K8S_KUBECONFIG` | --- | Path to kubeconfig file |
| `SFORGE_K8S_NODE_SELECTOR` | --- | Node selector for K8s pods, format: `"key1=val1,key2=val2"` |
| `SFORGE_E2B_TEMPLATE_MAP` | --- | Explicit E2B image-key to Template mapping, overriding the derived name. Inline `"image_key=template,..."` pairs, or a path ending in `.json` holding a JSON object |
| `SFORGE_E2B_TEMPLATE_NAMESPACE` | --- | Namespace for published E2B Templates (for example, `edgebench`) |
| `SFORGE_E2B_SANDBOX_TTL` | `3600` | E2B Sandbox TTL in seconds |

## Path Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `SFORGE_LOG_DIR` | `logs/` | Override log output directory |
| `SFORGE_TASKS_DIR` | `tasks/` | Override task definitions directory |
| `SFORGE_REGISTRY` | --- | Default Docker registry URL for `pull`/`push` commands |

## Proxy Fallback Chain

For proxy variables, SForge checks multiple environment variable names in priority order:

| Config Field | Env vars checked (first match wins) |
|-------------|--------------------------------------|
| `http_proxy` | `SFORGE_HTTP_PROXY` > `HTTP_PROXY` > `http_proxy` |
| `https_proxy` | `SFORGE_HTTPS_PROXY` > `HTTPS_PROXY` > `https_proxy` |
| `no_proxy` | `SFORGE_NO_PROXY` > `NO_PROXY` > `no_proxy` |

This means if you already have `HTTP_PROXY` set in your shell, SForge will pick it up automatically. Use the `SFORGE_` prefix to override without affecting other tools.

Because these proxy values are also injected into work containers during `sforge run`, unset them when using `--disable-internet` or use `sforge proxy` for LLM API forwarding.

## Build vs Run Decoupling

::: warning Important
Build and Run variables are completely independent. Build-stage variables are only used during `docker build` --- they are **not** baked into images. The run stage needs its own configuration.
:::

This means:

- Setting `SFORGE_PYPI_INDEX_URL` only affects `sforge build` (package installation during image construction)
- Setting `SFORGE_AGENT_API_KEY` only affects `sforge run` (agent execution)
- Proxy settings are read by both build and run stages. Run-time direct proxies are not recommended and do not work with network isolation; use `sforge proxy` for LLM API access through an upstream proxy.

## Example: Full Configuration

```bash
# Build stage
export SFORGE_HTTP_PROXY="http://proxy.corp.example:8080"
export SFORGE_HTTPS_PROXY="http://proxy.corp.example:8080"
export SFORGE_PYPI_INDEX_URL="https://mirrors.example.com/pypi/simple/"
export SFORGE_APT_MIRROR_URL="http://mirrors.example.com"
export SFORGE_GO_PROXY="https://goproxy.example.com"

# Run stage
export SFORGE_AGENT_API_KEY="sk-ant-..."
export SFORGE_AGENT_API_BASE_URL="https://api.anthropic.com"
export SFORGE_AGENT_MODEL="claude-sonnet-4-20250514"
export SFORGE_AGENT_TIMEOUT="7200"
export SFORGE_NODEJS_MIRROR_URL="https://mirrors.example.com/nodejs-release/"

# Resource limits
export SFORGE_WORK_CPU_LIMIT="4"
export SFORGE_WORK_MEM_LIMIT="8g"

# Container backend (Kubernetes)
export SFORGE_BACKEND="k8s"
export SFORGE_K8S_NAMESPACE="sforge-runs"
export SFORGE_K8S_IMAGE_REGISTRY="registry.example.com/sforge"
```
