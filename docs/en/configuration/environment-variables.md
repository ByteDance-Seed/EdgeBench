---
title: Environment Variables
---

# Environment Variables

## Overview

SForge reads a small set of `SFORGE_*` environment variables. Anything that has a CLI flag (model, effort, timeout, backend, resource limits) is set with the flag or in an [experiment file](/en/configuration/experiments), not with a variable. The resolution order is:

```
defaults  <  env vars  <  experiment YAML  <  CLI flags
```

An experiment file's `env:` block sets variables in the `sforge run` process before anything else is read.

## Agent

| Variable | Purpose |
|----------|---------|
| `SFORGE_AGENT_API_KEY` | API key for the model. It stays on the host: the judge server's LLM gateway adds it to the agent's requests |
| `SFORGE_AGENT_API_BASE_URL` | Model API endpoint, if not the agent's default (Anthropic for Claude Code and OpenCode, OpenAI for Codex) |
| `SFORGE_AGENT_EXTRA_ENV` | Extra variables for the work container, format `"KEY1=VAL1,KEY2=VAL2"` (e.g. Claude Code's model routing variables) |
| `SFORGE_NODEJS_MIRROR_URL` | Node.js download mirror used on the host when building agent bundles (the tarball is still checked against its pinned sha256) |
| `SFORGE_CACHE_DIR` | Cache for agent bundles and `sforge replay` (default `~/.cache/sforge`) |

## Judge

| Variable | Purpose |
|----------|---------|
| `SFORGE_JUDGE_EXTRA_ENV` | Variables for judge containers, format `"KEY1=VAL1,KEY2=VAL2"`, e.g. the credentials an LLM-graded task needs. Judge containers get nothing else from the host |
| `SFORGE_ADMIN_SECRET` | Shared secret between `sforge run` and an external `sforge serve` (session registration, auto-eval, usage). If unset, `sforge serve` creates a mode-`0600` file under `SFORGE_LOG_DIR` and `sforge run` reads it from the same place; an in-process judge uses a random one. Never expose it to work containers |

## Images and Tasks

| Variable | Default | Purpose |
|----------|---------|---------|
| `SFORGE_BENCHMARK` | `edgebench` | Benchmark directory, the default for `-b` |
| `SFORGE_LOG_DIR` | `logs/` | Build logs and run outputs |
| `SFORGE_REGISTRY` | the benchmark's `registry` | Registry prefix for `sforge pull` / `sforge push`; images live at `<prefix>/<image>:<tag>` |
| `SFORGE_BLOB_URL` | the benchmark's `blob_url` | Where `sforge build` downloads task blobs, as `<url>/<sha256>` (a `file://` URL works for a local copy) |

## Proxies

| Config | Env vars checked (first match wins) |
|--------|-------------------------------------|
| HTTP proxy | `SFORGE_HTTP_PROXY` > `HTTP_PROXY` > `http_proxy` |
| HTTPS proxy | `SFORGE_HTTPS_PROXY` > `HTTPS_PROXY` > `https_proxy` |
| No-proxy list | `SFORGE_NO_PROXY` > `NO_PROXY` > `no_proxy` |

Where the proxy is used is described in [Network Setup](/en/configuration/network-setup#proxies).

## Container Backends

| Variable | Default | Purpose |
|----------|---------|---------|
| `SFORGE_K8S_NAMESPACE` | `default` | Kubernetes namespace |
| `SFORGE_K8S_IMAGE_REGISTRY` | `SFORGE_REGISTRY`, else the benchmark's `registry` | Registry prefix pods pull images from |
| `SFORGE_K8S_KUBECONFIG` | --- | Path to kubeconfig file |
| `SFORGE_K8S_NODE_SELECTOR` | --- | Node selector for pods, format `"key1=val1,key2=val2"` |
| `SFORGE_E2B_TEMPLATE_NAMESPACE` | --- | Namespace of shared E2B Templates (unset: your own team's Templates) |
| `SFORGE_E2B_TEMPLATE_MAP` | --- | Explicit image-key to Template mapping, overriding the derived name. Inline `"image_key=template,..."` pairs, or a path ending in `.json` holding a JSON object |
| `SFORGE_E2B_PROVIDER` | `e2b` | E2B-compatible provider profile: `e2b` (official) or `vefaas` (Volcano Engine veFaaS). Set it on both the `run` and `serve` hosts |

The E2B SDK itself reads `E2B_API_KEY` (and `E2B_DOMAIN` for other endpoints).

## Example

```bash
# Model
export SFORGE_AGENT_API_KEY="sk-ant-..."

# Credentials for the LLM-graded task
export SFORGE_JUDGE_EXTRA_ENV="SFORGE_JUDGE_API_KEY=sk-...,SFORGE_JUDGE_MODEL=gpt-5.5"

# Kubernetes
export SFORGE_K8S_NAMESPACE="sforge-runs"

sforge run --backend k8s --task ad_placement_optimization --agent claude-code \
  --model claude-opus-4-8 --timeout 43200 \
  --work-cpu-limit 4 --work-mem-limit 16g \
  --judge-advertise 10.0.0.12 --judge-port 8080
```
