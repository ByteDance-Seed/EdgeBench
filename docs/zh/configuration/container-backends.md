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

E2B 后端使用 E2B Sandbox 运行 Work、Judge 和 Game 环境。不传 `--judge-url` 时，
SForge 还会创建临时的 managed Judge Controller，用户不需要单独部署 Judge 服务。

### Docker 镜像与 E2B Template

[`seededge`](https://hub.docker.com/u/seededge) 已经发布 EdgeBench 的预构建镜像。这些镜像
可以直接作为 E2B Template 的源镜像；对于没有修改过的公开任务，不需要执行
`sforge build`、`sforge pull` 或 `sforge push`。

Docker 镜像和 E2B Template 是两种不同的运行对象。`Template.from_image()` 将 Docker
镜像导入 E2B Template；`Sandbox.create()` 使用生成的 Template 名称或 ID 启动 Sandbox，
不能直接传入 Docker image 引用。SForge 会自动完成转换：

```text
seededge Docker 镜像
  -> sforge e2b-template
  -> 用户 E2B team 中的 Template
  -> sforge run --backend e2b
  -> E2B Sandbox
```

每个任务在一个 E2B team 中首次使用或镜像发生变化时需要准备 Template。输入一致时会
复用已有 Template；日常 `sforge run` 不会重新构建。

### 准备 Template

```bash
uv sync --extra e2b
export E2B_API_KEY=...

sforge fetch-tasks edgebench
sforge e2b-template \
  --task ad_placement_optimization \
  --source-registry seededge
```

准备所有已下载任务时，将 `--task` 换成 `--all`。SForge 会自动推导两个镜像引用、固定
不可变 digest、恢复非敏感 OCI 环境变量、快照镜像初始的 `/tmp`、构建 Work/Judge Template、
等待明确终态、重试暂态错误、记录版本化 manifest，并复用匹配的已有构建。用户不需要
编写 E2B Dockerfile，也不需要手工上传镜像层。

当前实现要求在 Linux amd64 主机上运行，并且本机 Docker daemon 可用，但不会重新构建
已发布镜像。官方任务镜像早于 E2B，会在 `/tmp` 下预置评测辅助文件：命令直接引用的包装
脚本，以及包装脚本运行时读取的其他文件。Docker 与 Kubernetes 直接从镜像启动，这些文件
天然存在；而 E2B 每个 Sandbox 都会重置 `/tmp`。因此当某个 role 的命令引用 `/tmp` 时，
SForge 会快照整个镜像 `/tmp`（连同仅被间接引用的辅助文件一起保存），存入 Template，并在
Sandbox 启动时恢复，使评测器看到与其他后端一致的文件。此过程不修改官方镜像、评测器或
评分逻辑。源 Registry 还需要能被 E2B 构建服务访问。

### 可移植镜像回退

少数版本的镜像包含 E2B 构建网络无法访问的 APT 源。这时需要提供一个可写 Registry：

```bash
export SFORGE_PORTABLE_REGISTRY_USERNAME=...
export SFORGE_PORTABLE_REGISTRY_PASSWORD=...

sforge e2b-template \
  --task TASK \
  --source-registry seededge \
  --portable-registry registry.example.com/project
```

只有 E2B 返回 APT provisioning 失败时，SForge 才会创建版本化 portable derivative。
该回退需要 Registry 写权限，但不会在每次评测时重复构建。

### 运行任务

```bash
export SFORGE_AGENT_API_KEY=...
export SFORGE_AGENT_API_BASE_URL=...
export SFORGE_AGENT_MODEL=...

sforge run \
  --backend e2b \
  --task ad_placement_optimization \
  --agent claude-code
```

SForge 会预检 Work/Judge Template，创建 secured Controller，注册 task，按需创建
Work/Judge/Game Sandbox，传递 gateway 凭证，收集结果并清理 Sandbox。只有使用独立部署的
Judge Server 时才需要传 `--judge-url`。

Work Sandbox 通过受保护的 E2B service gateway 访问 managed Controller；host 侧编排请求
则通过 E2B command channel 访问 Controller 的 loopback 地址，避免不必要地绕行公网
gateway。这个传输选择只用于 E2B，不改变 Docker 或 Kubernetes 的 Judge 路由。

每个 E2B 评测实例只对应一个 task。传入多个 task ID 时，CLI 只是批量调度多个相互独立的
评测，不会把多个 task 合并进同一个 Work 或 Judge 环境。本文验证采用每条
`sforge run` 命令运行一个 task 的方式。

### 套餐限制与运行规模

E2B 套餐限制是运行契约的一部分。Template 的 CPU 和内存会在构建时固化；超过当前 team
上限的请求会在创建 Template 时被拒绝。应使用目标 team 支持的规格重新构建 Template；
运行时的 `--work-*` 和 `--judge-*` 参数不能调整已有 E2B Template 的资源。

Agent timeout 应明显短于当前套餐允许的最大 Sandbox 生命周期。Sandbox 生命周期还要覆盖
Agent 安装、归档提取、等待 Judge 评测、读取结果和资源清理。managed Judge Controller 会在
整条多任务命令期间持续运行，因此整个错峰或多波次批次都必须落在 Controller 允许的生命周期
内，而不只是单个 task。比如套餐只允许一小时 Sandbox 时，可使用 30 分钟等更短的 Agent
预算，并避免让同一个 managed Controller 因多波调度运行满一小时；也可以改用独立部署的
Judge Server。

还需要检查每个任务的 `judge.eval_timeout`。Judge Sandbox 同样受 team 最大生命周期限制；
如果任务声明的评测超时长于该限制，那么当 evaluator 实际使用完整预算时，就无法保证评测
完成。如果要求与榜单口径可比，不应静默缩短 evaluator timeout，而应使用生命周期足够长的
套餐。

`--max-workers` 只限制并行 Work Sandbox 数量，不等于 E2B 总实例数。容量规划还要计入一个
managed Controller、临时 Judge Sandbox 和活跃 Game Sandbox，并为评测完成和资源清理的
重叠阶段留出余量。

最终分数沿用 SForge 与后端无关的既有语义：只在已经完成的 agent submission 和
auto-eval submission 中选取最佳结果。`final_archive.tar.gz` 是恢复快照，timeout 时不会被
隐式提交。短任务应选择能为至少一次完整评分留出时间的 auto-eval 间隔，或者让 Agent 在
结束前主动执行 `sforge-submit`。

### 用户需要提供的内容

| 输入 | 需要场景 |
| --- | --- |
| `E2B_API_KEY` | Template 准备和 E2B 运行 |
| Agent API key、base URL 和模型 | 运行 Agent |
| Linux amd64 主机和本机 Docker daemon | 使用当前实现准备 Template |
| `--source-registry seededge` | 使用已发布的 EdgeBench 镜像 |
| 源 Registry 凭证 | 仅使用私有源 Registry 时 |
| `--portable-registry` 及其凭证 | 仅需要 APT 可移植性回退时 |
| CPU/内存覆盖参数 | 仅 task 默认值不合适时；E2B 资源固化在 Template 中 |

宿主机的 `HTTP_PROXY` 和 `HTTPS_PROXY` 不会复制到 E2B Work、Judge 或 Game Sandbox。
只有用户显式配置 `SFORGE_HTTP_PROXY` 或 `SFORGE_HTTPS_PROXY` 时，远端可访问的代理才会
被转发；网络隔离任务会移除全部代理变量。详见[网络隔离](/zh/features/network-isolation)。

### E2B 常见问题

| 现象 | 可能原因 | 处理方式 |
| --- | --- | --- |
| 找不到 Template | 当前 E2B team 尚未转换该镜像，或输入已经变化 | 对该 task 执行 `sforge e2b-template` |
| E2B 无法拉取 `seededge` 镜像 | Registry 网络故障或精确 tag 不存在 | 核对 task 定义后重试 |
| Template provisioning 无法访问 APT 源 | 源镜像包含不可达 mirror | 提供 `--portable-registry` 和凭证 |
| Template 构建返回 internal error，或超过客户端等待时间后仍为 `building` | E2B 构建服务暂态故障；SDK 没有单次构建取消 API | 重试前先检查目标 tag 是否已经可启动，再只重试失败的 role；避免同时触发大量冷构建 |
| `/tmp` 下的 evaluator 缺失 | Template 未通过 SForge 构建，缺少镜像 `/tmp` 快照 | 用 `sforge e2b-template` 重建；SForge 会快照整个镜像 `/tmp` 并在 Sandbox 启动时恢复 |
| secured Judge 返回 403 | 缺少 traffic access token | 使用 managed 模式，或为外部 secured Judge 配置 `SFORGE_JUDGE_ACCESS_TOKEN` |
| Agent 侧 Judge 请求偶发超时 | Work Sandbox 无法通过 E2B 公网 gateway 建立连接 | 让 Agent 重试提交、降低同时提交的突发并发，或使用独立 Judge Server；host 侧 managed-controller 请求已通过 E2B command channel 走 loopback |
| task timeout 到达时出现 `Sandbox not found` | 在最终归档和清理前达到了 team 级 Sandbox 最大生命周期 | 缩短 Agent timeout、减少多波次批次总时长，或使用支持更长 Sandbox 生命周期的套餐 |
| 准备 Template 时 CPU 或内存被拒绝 | 请求规格超过当前 E2B team 上限 | 使用支持的规格重建；若榜单配置要求更高资源，则两者不具备严格可比性 |
| 运行结束后仍有 Sandbox | cleanup 失败或 Runner 被强制终止 | 检查 run 日志；平台最终按配置的 E2B TTL 回收 |

## 常见问题

| 后端 | 现象 | 可能原因 | 处理方式 |
| --- | --- | --- | --- |
| Kubernetes | `kubectl cluster-info failed` | kubeconfig 不正确、集群不可达或 namespace 参数有误 | 检查 `kubectl -n <namespace> cluster-info`；必要时设置 `SFORGE_K8S_KUBECONFIG` 和 `SFORGE_K8S_NAMESPACE` |
| Kubernetes | Pod 一直无法 Running | 镜像拉取失败、调度失败或资源不足 | 使用 `kubectl -n <namespace> describe pod <pod>` 查看事件 |
| Kubernetes | Pod 拉不到镜像 | 镜像对集群节点不可见，或 registry 凭证未配置 | 先 `sforge push`；确认 `SFORGE_K8S_IMAGE_REGISTRY`；为 namespace 配置 image pull secret |
| Kubernetes | Work Pod 无法提交评测 | Judge URL 对 Pod 不可达，或服务没有监听外部地址 | 用 `--host 0.0.0.0` 启动 `sforge serve`，并设置 Pod 可访问的 IP 或 Service URL |
| Kubernetes | `--disable-internet` 没有效果 | CNI 不执行 NetworkPolicy，或权限不足 | 确认 CNI 支持 NetworkPolicy，并检查当前身份的权限 |
| Kubernetes | 配置 node selector 后 Pod Pending | 没有节点匹配 selector | 检查 `SFORGE_K8S_NODE_SELECTOR` 和节点标签 |
