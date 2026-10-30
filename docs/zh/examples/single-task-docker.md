---
title: "单任务运行 (Docker)"
---

# 单任务运行 (Docker)

在本地用 Docker 运行一道 EdgeBench 任务（`ad_placement_optimization`）。

::: tip 规模
Docker backend 只适合试跑**少量任务**。在单机上并发运行大量任务（约 20 个以上）即使是高性能服务器也会被耗尽。完整套件请参考 [Kubernetes 示例](/zh/examples/all-tasks-k8s)，使用官方配置。
:::

::: warning 费用
前沿模型的运行费用很高——单个任务跑满官方 12 小时预算，API 费用可达数百甚至上千美元。建议先用较短的 `--timeout`（本例为 2 小时）试跑，摸清费用水平后再扩大规模。
:::

## 前置依赖

| 依赖 | 检查方式 |
|------|----------|
| Linux x86_64 主机 | - |
| Docker Engine 运行中 | `docker run hello-world` |
| Python 3.11–3.13 | `python --version` |

> **注意：** Docker backend 需要直接访问宿主机的 Docker daemon。
> 把 SForge 本身放在容器里运行会遇到 Docker-in-Docker 问题。

## 使用 Claude Code + Anthropic API

### 1. 安装 SForge

```bash
git clone https://github.com/ByteDance-Seed/EdgeBench.git
cd EdgeBench
pip install -e .
sforge list            # 列出 edgebench/tasks 下的任务
```

### 2. 获取镜像

```bash
sforge pull --task ad_placement_optimization
```

从 `docker.io/seededge` 拉取该题的 work 和 judge 镜像，并在本地打上 tag：

- `edgebench.work.ad_placement_optimization:<hash>`
- `edgebench.judge.ad_placement_optimization:<hash>`

哈希来自任务目录，所以镜像与你的代码一致。也可以自己构建（改过题目之后必须这样做）：
`sforge build --task ad_placement_optimization`。

### 3. 运行 Agent

```bash
SFORGE_AGENT_API_KEY="sk-ant-xxxx" \
sforge run --task ad_placement_optimization --agent claude-code \
  --model claude-opus-4-8[1m] \
  --timeout 7200 \
  --run-id ad-placement-optimization-001
```

启动 Claude Opus 4.8 在该任务上工作 2 小时，judge server 在同一个 `sforge run` 进程内运行。
Agent 的输出会实时打印到终端。

### 4. 查看结果

```bash
sforge viewer
# 打开 http://127.0.0.1:8000
```

或直接查看文件：

```bash
ls logs/runs/ad-placement-optimization-001/ad_placement_optimization/
cat logs/runs/ad-placement-optimization-001/ad_placement_optimization/final_result.json
```

`sforge replay --run-id ad-placement-optimization-001 --task ad_placement_optimization`
会在 Claude Code 里打开这次的会话。


## 使用第三方模型

用 Claude Code 评测非 Anthropic 模型时，把 API base URL 指向该厂商的 Anthropic 兼容端点，
另外还需要两项配置。

### 1. 模型路由环境变量

Claude Code 内部会将 subagent 调用分发到不同层级的模型（opus/sonnet/haiku）。默认情况下这些层级
指向 Anthropic 模型 ID。需要**全部**覆盖，使所有内部调用都路由到你的第三方模型：

| 变量 | 用途 |
|------|------|
| `ANTHROPIC_MODEL` | Claude Code 使用的主模型 |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | opus 层级调用使用的模型 |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | sonnet 层级调用使用的模型 |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | haiku 层级调用使用的模型 |
| `CLAUDE_CODE_SUBAGENT_MODEL` | subagent 使用的模型 |

### 2. 上下文窗口配置

**1M 上下文模型（如 DeepSeek V4 Pro）：** 在模型名后追加 `[1m]` 以启用 Claude Code 的 1M 上下文模式，
例如 `deepseek-v4-pro[1m]`。不加该后缀时，Claude Code 默认使用 200K 上下文窗口。

**200K 上下文模型（如 GLM 5.1）：** 设置以下变量，防止 Claude Code 超出上下文限制：

| 变量 | 值 | 用途 |
|------|-----|------|
| `CLAUDE_CODE_AUTO_COMPACT_WINDOW` | `200000` | 上下文窗口大小（token 数） |
| `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` | `80` | 使用率达到 80% 时触发压缩 |

不设置这些变量时，Claude Code 可能按更大的默认窗口填充上下文，在第三方模型上下文较小时报错。

Prompt 缓存不用另外配置。Claude Code 默认会在 system prompt 开头放一段每次请求都不一样的 attribution 信息，第三方服务的前缀缓存因此命中不了；SForge 已经把它关掉了。

### 示例 A：DeepSeek V4 Pro（1M 上下文）

```bash
export SFORGE_AGENT_API_KEY="your-deepseek-key"
export SFORGE_AGENT_API_BASE_URL="https://api.deepseek.com/anthropic"
export SFORGE_AGENT_EXTRA_ENV="ANTHROPIC_MODEL=deepseek-v4-pro[1m],ANTHROPIC_DEFAULT_OPUS_MODEL=deepseek-v4-pro[1m],ANTHROPIC_DEFAULT_SONNET_MODEL=deepseek-v4-pro[1m],ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-v4-pro[1m],CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-pro[1m]"

sforge run --task ad_placement_optimization --agent claude-code \
  --model deepseek-v4-pro[1m] \
  --timeout 7200 \
  --run-id ad-placement-deepseek-001
```

### 示例 B：GLM 5.1（200K 上下文）

```bash
export SFORGE_AGENT_API_KEY="your-glm-key"
export SFORGE_AGENT_API_BASE_URL="https://open.bigmodel.cn/anthropic"
export SFORGE_AGENT_EXTRA_ENV="ANTHROPIC_MODEL=glm-5.1,ANTHROPIC_DEFAULT_OPUS_MODEL=glm-5.1,ANTHROPIC_DEFAULT_SONNET_MODEL=glm-5.1,ANTHROPIC_DEFAULT_HAIKU_MODEL=glm-5.1,CLAUDE_CODE_SUBAGENT_MODEL=glm-5.1,CLAUDE_CODE_AUTO_COMPACT_WINDOW=200000,CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=80"

sforge run --task ad_placement_optimization --agent claude-code \
  --model glm-5.1 \
  --timeout 7200 \
  --run-id ad-placement-glm-001
```


## 网络隔离

大多数任务是隔离的：work 容器只能访问 judge server。Docker 上的隔离依靠宿主机 iptables 规则，需要对 `iptables` 有免密 `sudo`；详见[网络隔离](/zh/features/network-isolation)。


## LLM 评分任务

`college_english_exam_bank` 由 LLM 评分：评分程序在 judge 容器里运行 Codex CLI，调用一个兼容
OpenAI Responses 的端点。Harness 不会给 judge 容器任何自己的凭据，需要在运行 judge 的机器上
（`sforge run` 所在机器；用 `--judge-url` 时是 `sforge serve` 所在机器）用 `SFORGE_JUDGE_EXTRA_ENV` 传入：

```bash
export SFORGE_JUDGE_EXTRA_ENV="SFORGE_JUDGE_API_KEY=your-key,SFORGE_JUDGE_API_BASE_URL=https://api.openai.com/v1,SFORGE_JUDGE_MODEL=gpt-5.5"
```

| 变量（judge 容器内） | 用途 |
|----------------------|------|
| `SFORGE_JUDGE_API_KEY` | 评分脚本调用 LLM 用的 API key |
| `SFORGE_JUDGE_API_BASE_URL` | 评分端点的 base URL（默认 `https://openrouter.ai/api/v1`） |
| `SFORGE_JUDGE_MODEL` | 评分脚本使用的模型 ID |

不设置时，这道题的每次提交都是 `valid=false`。其他任务会忽略这些变量，所以对所有运行都设置也没问题。
