---
title: Container Backends
---

# Container Backends

SForge runs work and judge containers on a backend: local Docker by default, `k8s` for a Kubernetes cluster, or `e2b` for E2B cloud Sandboxes. One `sforge run` uses one backend for all its tasks; choose it with `--backend` or `backend:` in an experiment file.

| Backend | Use it for | Needs |
|---------|-----------|-------|
| `docker` | Trying tasks, task development, small runs | A local Docker daemon |
| `k8s` | Full-suite and other large runs | `kubectl` access to a cluster |
| `e2b` | Running without Docker or a cluster | An E2B account and Templates for the tasks |

::: warning
The Docker backend is for a few tasks at a time: around 20 concurrent tasks exhaust even a large host. Use `k8s` for the full suite.
:::

## The Judge Server

Every run has a judge server. It grades submissions in fresh judge containers, runs game sessions and forwards the agent's model requests, so the sandboxes must be able to reach it. `sforge run` serves it in-process:

| Backend | Sandboxes reach it at |
|---------|----------------------|
| Docker | `http://host.docker.internal:<port>`, set up automatically |
| Kubernetes, E2B | `http://<--judge-advertise>:<--judge-port>`: an IP of this machine the pods or Sandboxes can reach |

To share one judge between several `sforge run` processes or hosts, start `sforge serve` and pass `--judge-url` to the runs. They must share `SFORGE_ADMIN_SECRET`, which is automatic on one machine with the same log directory.

Resource limits (`--work-cpu-limit`, `--work-mem-limit`, `--judge-cpu-limit`, `--judge-mem-limit`) override the task's `cpus` and `memory`; on Kubernetes they become Pod requests and limits.

## Docker

The default backend. Images come from local Docker, via `sforge pull` or `sforge build`:

```bash
sforge pull --task ad_placement_optimization
sforge run --task ad_placement_optimization --agent claude-code
```

## Kubernetes

Each container becomes a Pod, labeled `app=sforge`. You need:

- `kubectl` access, and a namespace where you can create Pods and NetworkPolicies;
- nodes that can pull the task images (by default from the benchmark's `registry`, `docker.io/seededge` for EdgeBench);
- an IP of this host that pods can reach, for `--judge-advertise`;
- a CNI that enforces NetworkPolicy, for isolated tasks.

```bash
export SFORGE_K8S_NAMESPACE=sforge
sforge run --backend k8s --task ad_placement_optimization --agent claude-code \
  --judge-advertise 10.0.0.12 --judge-port 8080
```

Pods pull `<SFORGE_K8S_IMAGE_REGISTRY>/<image>:<tag>`. To pull from a registry near the cluster, or to run tasks you have changed, push the images there and point `SFORGE_K8S_IMAGE_REGISTRY` at it:

```bash
sforge push --task ad_placement_optimization --registry registry.example.com/sforge
export SFORGE_K8S_IMAGE_REGISTRY=registry.example.com/sforge
```

The other `SFORGE_K8S_*` variables are listed in [Environment Variables](/en/configuration/environment-variables#container-backends). For the full suite, see [All Tasks (Kubernetes)](/en/examples/all-tasks-k8s).

## E2B

Work, judge and game containers run as E2B Sandboxes. The judge server still runs on your host, so `--judge-advertise` must be an address reachable from the internet.

E2B starts Sandboxes from Templates rather than images. SForge derives each Template name from the image key (`edgebench.work.ad_placement_optimization:7b2f533ff7d4` becomes `edgebench-work-ad-placement-optimization:7b2f533ff7d4`) and looks for it in your E2B team. `SFORGE_E2B_TEMPLATE_NAMESPACE` selects Templates published under a shared namespace, and `SFORGE_E2B_TEMPLATE_MAP` maps image keys to other names. The [E2B example](/en/examples/single-task-e2b) shows how to build Templates.

A Template's CPU and memory are fixed when it is built. Your E2B plan bounds them, the Sandbox lifetime and the concurrency; keep `--timeout` well below the plan's maximum Sandbox lifetime.

For Volcano Engine veFaaS, which speaks the e2b protocol, set `SFORGE_E2B_PROVIDER=vefaas` and `E2B_DOMAIN`; `SFORGE_E2B_TEMPLATE_MAP` then maps image keys to function ids.
