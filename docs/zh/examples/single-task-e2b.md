---
title: "单任务运行 (E2B)"
---

# 单任务运行 (E2B)

在 [E2B](https://e2b.dev) 云端 Sandbox 中运行一个 EdgeBench 任务（`ad_placement_optimization`）。不需要本地 Docker daemon 或 Kubernetes 集群，唯一需要自己部署的是 Judge Server。

::: tip 适用场景
本地没法跑 Docker 时，E2B 是最省事的方式。Work、Judge 和 Game 环境都会从官方预构建的 Template 创建为 E2B Sandbox。并发数和 Sandbox 生命周期受你的 E2B 套餐限制，扩大规模前请先看[套餐限制与运行规模](/zh/configuration/container-backends#套餐限制与运行规模)。
:::

::: warning 费用
前沿模型的运行费用很高——单个任务跑满官方 12 小时预算，API 费用可达数百甚至上千美元，另外还有 E2B Sandbox 时长费用。建议先用较短的 `--timeout`（本示例为 2 小时）试跑，摸清费用水平后再扩大规模。
:::

## 前提条件

| 要求 | 验证方式 |
|------|----------|
| E2B 账号和 API key | 在 E2B 控制台获取 `E2B_API_KEY` |
| 一台有**公网可达**地址的主机运行 Judge Server | Sandbox 通过公网向它提交 |
| Python >= 3.10 | `python --version` |

> **注意：** Agent timeout 必须落在 E2B 套餐允许的最大 Sandbox 生命周期之内，
> 且要给评测和清理留出时间。跑长任务前先确认套餐上限。

## 使用 Claude Code + Anthropic API

### 1. 安装带 E2B 依赖的 SForge

```bash
pip install "sforge[e2b]"
```

### 2. 获取任务定义

```bash
sforge fetch-tasks edgebench
```

将 EdgeBench 任务 JSON 和 `BENCHMARK.yaml` 下载到 `./tasks/`。验证：

```bash
sforge list
```

### 3. 配置 E2B

E2B Sandbox 从 Template 启动而不是 Docker 镜像，所以没有 `sforge pull` 这一步。
所有已发布 EdgeBench 任务的官方 Template 已经构建好，SForge 会根据任务镜像引用
自动推导 Template 名称。在 Judge Server 主机和运行主机上**都**设置：

```bash
export E2B_API_KEY="e2b_xxxx"
export SFORGE_E2B_TEMPLATE_NAMESPACE=edgebench
```

如果 Judge Server 和 `sforge run` **不在同一台机器**，两边还需要一个共享的 admin
secret。Judge Server 只接受与自己一致的 secret，而未设置时两边会各自在
`SFORGE_LOG_DIR/.judge-admin-secret` 下随机生成，值对不上。在两台主机上导出同一个值：

```bash
export SFORGE_ADMIN_SECRET="$(openssl rand -base64 32)"   # 两台主机使用同一个值
```

同一台机器、同一个 log 目录下运行时，两边自动共用生成的文件，不需要设置。
不要把该 secret 传给 Agent。

### 4. 启动 Judge 服务器

在公网可达的主机上：

```bash
sforge serve --host 0.0.0.0 --port 8080
```

Judge Server 同样需要 `E2B_API_KEY`：运行注册后，它会在 E2B 上创建 Judge 和
Game Sandbox，在临时 Judge Sandbox 中评测每个提交的压缩包并返回分数。
确保 8080 端口对公网开放。

### 5. 运行 Agent

在运行主机上（可以和 Judge Server 同一台机器），`--judge-url` 指向 Judge Server
的公网地址：

```bash
SFORGE_AGENT_API_KEY="sk-ant-xxxx" \
sforge run --backend e2b \
  --task ad_placement_optimization --agent claude-code \
  --model claude-opus-4-8[1m] \
  --timeout 7200 \
  --judge-url http://YOUR_PUBLIC_HOST:8080 \
  --run-id ad-placement-optimization-e2b-001
```

这会在 E2B Work Sandbox 中启动 Claude Opus 4.8 处理该任务，持续 2 小时。
你会在 stdout 中实时看到 Agent 的工作输出。

`--backend e2b` 下每个任务独立评测；传入多个 task ID 只是调度多套互不相关的 Sandbox。

### 6. 查看结果

通过内置 Web UI 实时查看评分进展：

```bash
sforge visualizer
# 打开 http://127.0.0.1:8000
```

也可以直接查看文件：

```bash
ls logs/runs/*/ad_placement_optimization/
cat logs/runs/*/ad_placement_optimization/final_result.json
```

运行结束后 Sandbox 会自动删除。如果超过一分钟仍有残留，见[常见问题](/zh/configuration/container-backends#常见问题)。


## 使用第三方模型

模型路由和上下文窗口的配置与 Docker 示例完全相同，只需改后端参数。按照
[使用第三方模型](/zh/examples/single-task-docker#使用第三方模型)配置，并在
`sforge run` 命令中加上 `--backend e2b --judge-url http://YOUR_PUBLIC_HOST:8080`，例如：

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


## 网络隔离

任务 JSON 中的 `internet` 字段以及 `--disable-internet` / `--enable-internet`
参数与 Docker 下用法一致。E2B 上 SForge 通过 E2B 原生的 `update_network` API
下发白名单，而不是宿主机 iptables，因此本机不会留下任何残留。E2B 规则是主机级
而非端口级：放行一个域名即放行它的所有端口。

宿主机的 `HTTP_PROXY` / `HTTPS_PROXY` **不会**转发进 Sandbox。如果模型 API
必须走代理，该代理需要公网可达，并通过 `SFORGE_HTTP_PROXY` /
`SFORGE_HTTPS_PROXY` 显式指定。详见[网络隔离](/zh/features/network-isolation#e2b-backend)。


## LLM 评分任务

`college_english_exam_bank` 这类 LLM 评分任务需要在 Judge 环境中提供评分用凭证，
与 Docker 下相同。**在启动 Judge 服务器前**设置 `SFORGE_JUDGE_EXTRA_ENV`，变量
说明见 [LLM 评分任务](/zh/examples/single-task-docker#llm-评分任务)。
