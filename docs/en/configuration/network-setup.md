---
title: Network Setup
---

# Network Setup

## Default: No Extra Setup

SForge assumes the host can reach the public internet. On an unrestricted network you need no proxies or mirrors:

```bash
sforge pull --task ad_placement_optimization

export SFORGE_AGENT_API_KEY="sk-ant-xxxx"
sforge run --task ad_placement_optimization --agent claude-code
```

Use the options below only when your environment cannot reach a required service directly.

## What Needs Network Access

| Step | Who | Reaches |
|------|-----|---------|
| `sforge pull` | host Docker daemon | Docker Hub (`registry-1.docker.io`) |
| `sforge build` | host and `docker build` | Docker Hub and other base-image registries; the pinned public URLs, package indexes and apt snapshots in the Dockerfiles; this repository's Release assets for task blobs |
| `sforge run` (agent bundle, first use) | host | nodejs.org and the npm registry |
| `sforge run` (model calls) | judge server on the host | the model API |
| work container | — | only the judge server when the task is isolated; the internet when `internet = true` |
| judge container | — | nothing, unless the task's `[judge] internet = true` (the LLM-graded task) |

The work container never calls the model API itself: the judge server's LLM gateway forwards its requests, so isolated containers need no proxy.

## Proxies

Set a proxy for SForge without affecting other tools on the host:

```bash
export SFORGE_HTTP_PROXY="http://proxy.example:8080"
export SFORGE_HTTPS_PROXY="http://proxy.example:8080"
export SFORGE_NO_PROXY="localhost,127.0.0.1,host.docker.internal"
```

SForge falls back to `HTTP_PROXY` / `HTTPS_PROXY` / `NO_PROXY` when the `SFORGE_` variants are unset. The proxy is used by `docker build` (as Docker's predefined proxy build args, not stored in images), by the LLM gateway for model requests, and inside internet-enabled work containers. Isolated work containers get no proxy variables.

`sforge pull` and image pulls by Kubernetes nodes are done by the Docker daemon or container runtime, which have their own proxy settings (for Docker, `/etc/systemd/system/docker.service.d/http-proxy.conf`).

## Mirrors

Task Dockerfiles fetch only pinned public URLs, with a sha256 check or a hash-locked lockfile, so builds do not take per-task mirror settings. A mirror can still speed up transport if it serves identical bytes, for example a Docker registry mirror in `/etc/docker/daemon.json`, or a transparent caching proxy set as `SFORGE_HTTPS_PROXY`.

For the agent bundle, which is built on the host on first use:

```bash
export SFORGE_NODEJS_MIRROR_URL="https://nodejs.example.com/download/release/"
export npm_config_registry="https://npm.example.com"
```

Task blobs can be served from a local copy with `SFORGE_BLOB_URL=file:///path/to/blobs` (files named by their sha256).
