---
title: 容器后端
---

# 容器后端

SForge 在 backend 上运行 work 和 judge 容器：默认是本地 Docker，`k8s` 用于 Kubernetes 集群，`e2b` 用于 E2B 云端 Sandbox。一次 `sforge run` 的所有任务使用同一个 backend，用 `--backend` 或实验配置中的 `backend:` 选择。

| Backend | 适用场景 | 需要 |
|---------|----------|------|
| `docker` | 试跑任务、开发任务、小规模运行 | 本地 Docker daemon |
| `k8s` | 完整套件等大规模运行 | 能用 `kubectl` 访问的集群 |
| `e2b` | 没有 Docker 或集群时 | E2B 账号和各任务的 Template |

::: warning
Docker backend 一次只适合跑少量任务：并发 20 道左右就会耗尽一台大机器。完整套件请用 `k8s`。
:::

## Judge Server

每次运行都有一个 judge server：它在新的 judge 容器里评分、运行游戏会话、转发 Agent 的模型请求，所以 sandbox 必须能访问到它。`sforge run` 在进程内提供 judge：

| Backend | Sandbox 访问地址 |
|---------|------------------|
| Docker | `http://host.docker.internal:<port>`，自动配置 |
| Kubernetes、E2B | `http://<--judge-advertise>:<--judge-port>`：本机一个 Pod 或 Sandbox 能访问到的 IP |

如果要让多个 `sforge run` 进程或多台机器共用一个 judge，启动 `sforge serve` 并给各次运行传 `--judge-url`。它们必须共用 `SFORGE_ADMIN_SECRET`；在同一台机器、使用同一个日志目录时会自动共用。

资源限制（`--work-cpu-limit`、`--work-mem-limit`、`--judge-cpu-limit`、`--judge-mem-limit`）覆盖任务的 `cpus` 和 `memory`；在 Kubernetes 上它们成为 Pod 的 requests 和 limits。

## Docker

默认 backend。镜像来自本地 Docker，通过 `sforge pull` 或 `sforge build` 获取：

```bash
sforge pull --task ad_placement_optimization
sforge run --task ad_placement_optimization --agent claude-code
```

## Kubernetes

每个容器对应一个 Pod，带 `app=sforge` 标签。需要：

- 能用 `kubectl` 访问集群，并有一个可以创建 Pod 和 NetworkPolicy 的 namespace；
- 节点能拉取任务镜像（默认来自 benchmark 的 `registry`，EdgeBench 为 `docker.io/seededge`）；
- 本机一个 Pod 能访问到的 IP，用作 `--judge-advertise`；
- 跑隔离任务时，CNI 要实际执行 NetworkPolicy。

```bash
export SFORGE_K8S_NAMESPACE=sforge
sforge run --backend k8s --task ad_placement_optimization --agent claude-code \
  --judge-advertise 10.0.0.12 --judge-port 8080
```

Pod 拉取 `<SFORGE_K8S_IMAGE_REGISTRY>/<镜像>:<tag>`。要从集群附近的 registry 拉取，或运行改过的任务，把镜像推到那里，再把 `SFORGE_K8S_IMAGE_REGISTRY` 指过去：

```bash
sforge push --task ad_placement_optimization --registry registry.example.com/sforge
export SFORGE_K8S_IMAGE_REGISTRY=registry.example.com/sforge
```

其他 `SFORGE_K8S_*` 变量见[环境变量](/zh/configuration/environment-variables#容器后端)。完整套件见[全部任务 (Kubernetes)](/zh/examples/all-tasks-k8s)。

## E2B

Work、judge 和游戏容器都以 E2B Sandbox 运行。Judge server 仍然运行在你的主机上，所以 `--judge-advertise` 必须是公网可达的地址。

E2B 从 Template 而不是镜像启动 Sandbox。SForge 由镜像 key 推导 Template 名称（`edgebench.work.ad_placement_optimization:7b2f533ff7d4` 对应 `edgebench-work-ad-placement-optimization:7b2f533ff7d4`），并在你的 E2B 团队中查找。`SFORGE_E2B_TEMPLATE_NAMESPACE` 用于选择发布在共享 namespace 下的 Template，`SFORGE_E2B_TEMPLATE_MAP` 把镜像 key 映射到其他名称。如何构建 Template 见 [E2B 示例](/zh/examples/single-task-e2b)。

Template 的 CPU 和内存在构建时就固定了。E2B 套餐限制它们、Sandbox 的生命周期和并发数；`--timeout` 要明显小于套餐允许的最长 Sandbox 生命周期。

火山引擎 veFaaS 兼容 e2b 协议：设置 `SFORGE_E2B_PROVIDER=vefaas` 和 `E2B_DOMAIN`，此时 `SFORGE_E2B_TEMPLATE_MAP` 把镜像 key 映射到函数 id。
