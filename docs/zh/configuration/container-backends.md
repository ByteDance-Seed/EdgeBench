---
title: 容器后端
---

# 容器后端

SForge 通过容器后端创建 Work 和 Judge 环境。默认后端是本机 Docker；已有 Kubernetes
集群时可以使用 `k8s`，需要 E2B 托管远端运行环境时可以使用 `e2b`。

## 如何选择后端

| 后端 | 适合场景 | 主要要求 |
|------|----------|----------|
| `docker` | 本地开发、调试任务、单机评测、小规模实验 | 本机 Docker daemon 可用 |
| `k8s` | 共享集群、批量并发评测、希望让 Work/Judge Pod 在集群中运行 | `kubectl` 可访问集群，镜像在集群中可拉取，Judge URL 可从 Pod 访问 |
| `e2b` | 不自行维护集群或 Judge broker 的远端 Work/Judge 运行 | E2B API 与 E2B Template；详见 [E2B 后端](#e2b-后端) |

如果只是本地试跑任务，优先使用默认的 Docker 后端。Kubernetes 后端更适合已经有集群和镜像仓库的团队环境。
E2B 后端在首次运行新增或发生变化的任务镜像前，需要先准备 Template。

::: warning Docker 后端不适合大批量运行
每个任务会占用一个 Work 容器外加临时 Judge 容器，各自有独立的 CPU/内存限额。单机并发运行大量任务（约 **20 个以上**）即使是高性能服务器也会出现严重的资源争抢。大批量运行请使用 `k8s` 后端。
:::

## 配置方式

后端可以通过 CLI、环境变量或实验 YAML 配置：

```bash
# 单次运行覆盖
sforge run \
  --task ad_placement_optimization \
  --agent claude-code \
  --backend k8s \
  --judge-url http://10.0.0.12:8080

# 环境变量覆盖
export SFORGE_BACKEND=k8s
sforge run \
  --task ad_placement_optimization \
  --agent claude-code
```

实验配置中也可以设置默认后端：

```yaml
defaults:
  agent: claude-code
  backend: k8s

tasks:
  ad_placement_optimization: {}
```

## Docker 后端

Docker 是默认后端，不需要显式配置：

```bash
sforge build --task ad_placement_optimization
sforge serve

export SFORGE_AGENT_API_KEY="sk-..."
sforge run \
  --task ad_placement_optimization \
  --agent claude-code
```

Docker 后端会：

- 使用本机 Docker daemon 构建和运行镜像
- 在本机 Docker 中启动 Work 容器和 Judge 容器
- 通过默认的 `http://host.docker.internal:8080` 让容器访问宿主机上的 Judge HTTP server
- 在启用 `--disable-internet` 时使用宿主机侧网络隔离能力

资源限制可以通过 CLI 或环境变量设置：

```bash
sforge run \
  --task ad_placement_optimization \
  --agent claude-code \
  --work-cpu-limit 4 \
  --work-mem-limit 8g \
  --judge-cpu-limit 2 \
  --judge-mem-limit 4g
```

## Kubernetes 后端

Kubernetes 后端通过 `kubectl` 创建 Pod。每个 SForge 容器会对应到集群中的一个 Pod，容器名为 `work`，Pod 使用标签 `app=sforge` 和 `sforge-pod=<pod-name>`。

### 前置条件

使用 `k8s` 后端前，请确认：

1. 本机已安装 `kubectl`，并且可以访问目标集群。
2. 目标 namespace 已存在，且当前 kubeconfig 有创建、查询、删除 Pod 的权限。
3. Work/Judge 镜像已经推送到 Kubernetes 节点可访问的镜像仓库。
4. SForge Judge HTTP server 对集群中的 Pod 可访问。
5. 如果使用 `--disable-internet`，集群需要支持并执行 Kubernetes `NetworkPolicy`。

可以先检查集群连通性：

```bash
kubectl -n <namespace> cluster-info
kubectl -n <namespace> get pods
```

### Kubernetes 相关环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `SFORGE_BACKEND` | `docker` | 设置为 `k8s` 后启用 Kubernetes 后端 |
| `SFORGE_K8S_NAMESPACE` | `default` | 创建 Pod 和 NetworkPolicy 的 namespace |
| `SFORGE_K8S_IMAGE_REGISTRY` | --- | Pod 拉取镜像时添加到镜像名前的 registry 前缀 |
| `SFORGE_K8S_KUBECONFIG` | --- | kubeconfig 文件路径；未设置时使用 `kubectl` 默认配置 |
| `SFORGE_K8S_NODE_SELECTOR` | --- | Pod 的 node selector，格式为 `"key1=val1,key2=val2"` |

### 镜像准备

Kubernetes 节点不能直接使用你本机 Docker daemon 里的本地镜像。使用 k8s 后端时，通常需要先构建并推送镜像：

```bash
# 本机构建镜像
sforge build --task ad_placement_optimization

# 推送到集群可访问的 registry
sforge push --task ad_placement_optimization --registry registry.example.com/sforge
```

然后让 k8s 后端使用同一个 registry 前缀：

```bash
export SFORGE_K8S_IMAGE_REGISTRY=registry.example.com/sforge
```

Kubernetes 后端会把内部镜像名解析为：

```text
${SFORGE_K8S_IMAGE_REGISTRY}/<sforge-image-name>:<tag>
```

::: tip
`sforge build` 仍然使用本机 Docker 构建镜像；`k8s` 后端负责运行 Work/Judge Pod，不负责在集群中构建镜像。
:::

### Judge URL

`--judge-url` 是 Work 容器或 Pod 里看到的 Judge server 地址。Docker 默认值 `http://host.docker.internal:8080` 通常只适合本机 Docker，不适合 Kubernetes Pod。

使用 k8s 后端时，应通过 `--judge-url` 传入一个 Pod 可访问的地址，例如宿主机内网 IP、LoadBalancer、Ingress 或集群内 Service。

启动本机 Judge server：

```bash
sforge serve --host 0.0.0.0 --port 8080
```

然后运行：

```bash
sforge run \
  --task ad_placement_optimization \
  --agent claude-code \
  --backend k8s \
  --judge-url http://10.0.0.12:8080
```

### 完整示例

```bash
# 1. 构建并推送镜像
sforge build --task ad_placement_optimization
sforge push --task ad_placement_optimization --registry registry.example.com/sforge

# 2. 配置 k8s 后端
export SFORGE_BACKEND=k8s
export SFORGE_K8S_NAMESPACE=sforge
export SFORGE_K8S_IMAGE_REGISTRY=registry.example.com/sforge
export SFORGE_K8S_KUBECONFIG=$HOME/.kube/config

# 可选：只调度到指定节点池
export SFORGE_K8S_NODE_SELECTOR="pool=sforge"

# 3. 启动 Judge server，确保集群 Pod 可以访问这个地址
sforge serve --host 0.0.0.0 --port 8080

# 4. 另一个终端运行 Agent
export SFORGE_AGENT_API_KEY="sk-..."
sforge run \
  --task ad_placement_optimization \
  --agent claude-code \
  --backend k8s \
  --judge-url http://10.0.0.12:8080
```

### 资源限制

Work/Judge 的 CPU 和内存限制同样适用于 k8s 后端。SForge 会把它们转换为 Pod 的 resource requests/limits：

```bash
sforge run \
  --task ad_placement_optimization \
  --agent claude-code \
  --backend k8s \
  --work-cpu-limit 4 \
  --work-mem-limit 8g \
  --judge-cpu-limit 2 \
  --judge-mem-limit 4g
```

内存格式会从 Docker 风格转换为 Kubernetes 风格，例如 `8g` 转为 `8Gi`，`512m` 转为 `512Mi`。

### 网络隔离

在 Docker 后端中，`--disable-internet` 使用宿主机侧网络隔离；在 Kubernetes 后端中，SForge 会创建 Kubernetes `NetworkPolicy` 限制 Pod egress，只允许访问 Judge server、配置的 LLM API 端点和 DNS。

注意：

- 集群的 CNI 必须支持并执行 `NetworkPolicy`，否则策略可能不会生效。
- 当前 kubeconfig 需要有创建和删除 `NetworkPolicy` 的权限。
- 不同集群的默认 DNS、出口网关和策略实现可能不同，建议先用小任务验证隔离效果。

## E2B 后端

E2B 后端使用 E2B Sandbox 运行 Work、Judge 和 Game 环境。Judge Server 本身与其他后端
一样部署在你自己的主机上：在 Sandbox 可达的机器上启动 `sforge serve`，并通过
`--judge-url` 传入其地址。

### Docker 镜像与 E2B Template

Docker 镜像和 E2B Template 是两种不同的运行对象：E2B Sandbox 从 Template 启动，
不能直接传入 Docker image 引用。已发布 EdgeBench 任务的官方 E2B Template 由
SForge 维护者预先构建并发布，用户不需要执行任何 Template 准备步骤。
设置 `SFORGE_E2B_TEMPLATE_NAMESPACE` 指定发布 Template 的 namespace。
`sforge run --backend e2b` 随后会自动推导每个任务镜像对应的公开 Template 引用
（`edgebench.work.foo_bar:abc123` ->
`edgebench/edgebench-work-foo-bar:abc123`）。只有需要覆盖该映射时
（例如为修改过的任务运行自建 Template）才设置 `SFORGE_E2B_TEMPLATE_MAP`。

### 运行任务

在有公网可达地址的主机上启动 Judge Server（E2B Sandbox 里的 Agent 通过公网向它提交）：

```bash
uv sync --extra e2b
export E2B_API_KEY=...
export SFORGE_E2B_TEMPLATE_NAMESPACE=edgebench
export SFORGE_ADMIN_SECRET=...   # serve 和 run 两台主机需使用同一个值

sforge serve --host 0.0.0.0 --port 8080
```

然后运行 Agent，`--judge-url` 指向该主机：

```bash
export E2B_API_KEY=...
export SFORGE_E2B_TEMPLATE_NAMESPACE=edgebench
export SFORGE_ADMIN_SECRET=...   # 与 serve 主机一致
export SFORGE_AGENT_API_KEY=...
export SFORGE_AGENT_API_BASE_URL=...
export SFORGE_AGENT_MODEL=...

sforge run \
  --backend e2b \
  --task ad_placement_optimization \
  --agent claude-code \
  --judge-url http://YOUR_HOST:8080
```

Judge Server 主机同样需要 `E2B_API_KEY`：e2b 运行注册后，Judge Server 会在 E2B 上
创建 Judge 和 Game Sandbox（与 k8s 运行让它调度 judge pod 的机制对称）。Work Sandbox
向 Judge Server 的公网地址提交；Judge Server 通过 E2B service gateway 访问 Game
Sandbox。

每个 E2B 评测实例只对应一个 task。传入多个 task ID 时，CLI 只是批量调度多个相互独立的
评测，不会把多个 task 合并进同一个 Work 或 Judge 环境。本文验证采用每条
`sforge run` 命令运行一个 task 的方式。

### 套餐限制与运行规模

E2B 套餐限制是运行契约的一部分：

- **资源规格**：Template 的 CPU 和内存在构建时固化，超限会在创建 Template 时被拒绝。
  请按 team 支持的规格重建；`--work-*` 和 `--judge-*` 参数不能调整已有 Template。
- **Sandbox 生命周期**：Agent timeout 应明显短于套餐的最大 Sandbox 生命周期，后者还要覆盖
  Agent 安装、归档提取、Judge 评测、读取结果和清理。清理时 SForge 会把剩余生命周期收紧到
  60 秒内并删除 Sandbox，不受配置的 TTL 影响。
- **评测超时**：Judge Sandbox 受同样限制，任务的 `judge.eval_timeout` 若超过该限制则可能
  无法完成。应换更长生命周期的套餐，而不是缩短超时。
- **并发用量**：任务全并行运行，需按所选任务数为 Work、Judge 和 Game Sandbox 预留容量，
  并为评测与清理的重叠阶段留出余量。
- **最终分数**：与其他后端一致，取已完成的 agent 或 auto-eval submission 中的最佳结果。
  `final_archive.tar.gz` 是恢复快照，timeout 时不会隐式提交。短任务应保证至少一次 auto-eval
  能完成，或让 Agent 在结束前执行 `sforge-submit`。

### 用户需要提供的内容

| 输入 | 需要场景 |
| --- | --- |
| `E2B_API_KEY` | E2B 运行（`sforge run` 主机和 Judge Server 主机都需要） |
| 公网可达的 `--judge-url` | 所有 E2B 运行 |
| Agent API key、base URL 和模型 | 运行 Agent |

宿主机的 `HTTP_PROXY` 和 `HTTPS_PROXY` 不会复制到 E2B Work、Judge 或 Game Sandbox。
只有用户显式配置 `SFORGE_HTTP_PROXY` 或 `SFORGE_HTTPS_PROXY` 时，远端可访问的代理才会
被转发；网络隔离任务会移除全部代理变量。详见[网络隔离](/zh/features/network-isolation)。

## 常见问题

| 后端 | 现象 | 可能原因 | 处理方式 |
| --- | --- | --- | --- |
| Kubernetes | `kubectl cluster-info failed` | kubeconfig 不正确、集群不可达或 namespace 参数有误 | 检查 `kubectl -n <namespace> cluster-info`；必要时设置 `SFORGE_K8S_KUBECONFIG` 和 `SFORGE_K8S_NAMESPACE` |
| Kubernetes | Pod 一直无法 Running | 镜像拉取失败、调度失败或资源不足 | 使用 `kubectl -n <namespace> describe pod <pod>` 查看事件 |
| Kubernetes | Pod 拉不到镜像 | 镜像对集群节点不可见，或 registry 凭证未配置 | 先 `sforge push`；确认 `SFORGE_K8S_IMAGE_REGISTRY`；为 namespace 配置 image pull secret |
| Kubernetes | Work Pod 无法提交评测 | Judge URL 对 Pod 不可达，或服务没有监听外部地址 | 用 `--host 0.0.0.0` 启动 `sforge serve`，并设置 Pod 可访问的 IP 或 Service URL |
| Kubernetes | `--disable-internet` 没有效果 | CNI 不执行 NetworkPolicy，或权限不足 | 确认 CNI 支持 NetworkPolicy，并检查当前身份的权限 |
| Kubernetes | 配置 node selector 后 Pod Pending | 没有节点匹配 selector | 检查 `SFORGE_K8S_NODE_SELECTOR` 和节点标签 |
| E2B | 找不到 Template | Template namespace 缺失或错误、该任务镜像版本没有已发布的官方 Template，或任务使用了修改过的镜像 | 检查 `SFORGE_E2B_TEMPLATE_NAMESPACE` 和任务镜像版本，或用 `SFORGE_E2B_TEMPLATE_MAP` 指向自建 Template |
| E2B | Agent 侧 Judge 请求偶发超时 | Work Sandbox 无法通过公网访问 Judge Server | 确认 Judge 主机和端口公网可达后重试提交 |
| E2B | task timeout 到达时出现 `Sandbox not found` | 在最终归档和清理前达到了 team 级 Sandbox 最大生命周期 | 缩短 Agent timeout、减少多波次批次总时长，或使用支持更长 Sandbox 生命周期的套餐 |
| E2B | 运行结束超过 60 秒后仍有 Sandbox | 服务端终止期限和即时删除请求均未生效 | 检查运行日志或 Judge Server 日志中的生命周期清理错误 |
