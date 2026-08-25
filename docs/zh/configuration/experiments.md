---
title: 实验配置
---

# 实验配置

## 概述

实验配置文件采用 YAML 格式，用于在多任务运行中共享模型设置并支持逐任务覆盖。这将「如何运行」（模型、超时、Agent 设置）与「测试什么」（任务 JSON 定义）解耦。

::: tip 官方 leaderboard 配置
[all-tasks-k8s 示例](/zh/examples/all-tasks-k8s)中的 experiment YAML 就是 EdgeBench leaderboard 官方数字所使用的配置。
:::

## YAML 格式

```yaml
model:
  api_key: ${OPUS_KEY}
  api_base_url: https://api.anthropic.com
  model: claude-opus-4-6

stagger: 300  # 在 300 秒内均匀分散任务启动

defaults:
  agent: claude-code
  timeout: 7200
  eval_interval: 300

tasks:
  ad_placement_optimization:
    eval_interval: 1800
  tinykv:
    extra_env:
      GOPROXY: "https://goproxy.cn"
  gitlet: {}
```

## 字段说明

### `model`

配置 Agent 使用的 LLM。所有字符串值支持 `${ENV_VAR}` 环境变量展开 --- 引用的环境变量必须在运行时已设置。

| 字段 | 类型 | 说明 |
|------|------|------|
| `api_key` | `string` | API 密钥（支持 `${ENV_VAR}` 展开） |
| `api_base_url` | `string` | API Base URL |
| `model` | `string` | 模型名称（如 `claude-opus-4-6`、`claude-sonnet-4-20250514`） |

### `defaults`

应用于所有任务的默认设置，可被逐任务覆盖。

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `agent` | `string` | --- | Agent 名称（`claude-code`、`codex`） |
| `model` | `string` | --- | 模型覆盖（在逐任务设置中可覆盖 `model.model`） |
| `timeout` | `int` | --- | Agent 超时时间（秒） |
| `eval_interval` | `int` | --- | 自动评测间隔（秒） |
| `disable_stop_hook` | `bool` | `false` | 禁用 Agent Stop Hook |
| `disable_auto_eval` | `bool` | `false` | 禁用后台自动评测 |
| `disable_auto_resume` | `bool` | `false` | 禁用 Agent 异常退出时的自动恢复 |
| `internet` | `bool` | --- | 启用/禁用网络访问 |
| `extra_env` | `dict` | --- | 注入 Agent 容器的额外环境变量 |
| `backend` | `string` | --- | 容器后端（`docker`、`k8s` 或 `e2b`） |
| `judge_url` | `string` | --- | Judge 服务器 URL 覆盖 |
| `max_submissions` | `int` | --- | 每次运行中 Agent 最大提交次数 |
| `submission_cooldown` | `int` | --- | Agent 两次提交之间的最小间隔（秒） |
| `work_cpu_limit` | `int` | --- | Work 容器的 CPU 限制 |
| `work_mem_limit` | `string` | --- | Work 容器的内存限制 |
| `judge_cpu_limit` | `int` | --- | Judge 容器的 CPU 限制 |
| `judge_mem_limit` | `string` | --- | Judge 容器的内存限制 |

### `tasks`

逐任务覆盖。每个 key 是任务 ID，必须对应 tasks 目录下的 JSON 文件。value 支持与 `defaults` 相同的字段。此处列出的任务决定了运行范围 --- 如果 CLI 中没有指定 `--task`，则使用实验配置中的任务列表。

空对象（`{}`）表示「使用所有默认设置，无覆盖」。

### `stagger`

顶层整数字段，在运行多个任务时将任务启动均匀分散在指定的秒数内。这可以避免同时启动大量容器和 API 调用造成的"惊群效应"。

```yaml
stagger: 300  # 在 5 分钟内均匀间隔启动任务
```

例如，6 个任务配合 `stagger: 300`，每个任务间隔 50 秒启动。

## 优先级链

配置值按以下顺序解析（优先级从高到低）：

```
CLI 参数  >  逐任务覆盖  >  实验默认值  >  环境变量 / 任务 JSON
```

举例来说：
- CLI 中的 `--timeout 3600` 总是优先
- 逐任务的 `timeout: 1800` 覆盖实验级的 `defaults.timeout`
- 实验的 `defaults.timeout` 覆盖 `SFORGE_AGENT_TIMEOUT` 环境变量

对于 `extra_env`，字典是**合并**（而非替换）的。逐任务的 key 在冲突时覆盖默认值：

```yaml
defaults:
  extra_env:
    FOO: "from-defaults"
    BAR: "shared"

tasks:
  ad_placement_optimization:
    extra_env:
      FOO: "from-task"   # 覆盖 defaults
      BAZ: "task-only"   # 新增
    # 最终结果：FOO=from-task, BAR=shared, BAZ=task-only
```

## 使用方法

### 运行实验中的所有任务

```bash
sforge run --experiment experiments/my_config.yaml --run-id batch-001
```

不指定 `--task` 时，实验文件中列出的所有任务会并行运行。

### 运行部分任务

```bash
sforge run --experiment experiments/my_config.yaml --task ad_placement_optimization tinykv
```

使用实验配置中的模型和默认设置，但只运行指定的任务。

### CLI 覆盖

```bash
sforge run \
  --experiment experiments/my_config.yaml \
  --timeout 3600 \
  --disable-stop-hook \
  --run-id experiment-v2
```

CLI 参数具有最高优先级，会覆盖逐任务和默认设置。

## 环境变量展开

`model` 部分的字符串值支持 `${VAR_NAME}` 语法：

```yaml
model:
  api_key: ${MY_API_KEY}
  api_base_url: ${API_ENDPOINT}
```

如果引用的变量未设置，SForge 会报错退出。这样可以将密钥保存在环境变量中，而实验配置文件本身可以安全地提交到版本控制。

## 运行产物

使用实验配置运行时，SForge 会保存以下文件：

- `logs/runs/<run-id>/experiment.yaml` --- 实验配置文件的副本
- `logs/runs/<run-id>/run_config.json` --- 所有任务的完整解析后配置
- `logs/runs/<run-id>/<task-id>/run_config.json` --- 逐任务解析后配置（API 密钥已脱敏）
- `logs/runs/<run-id>/summary.json` --- 最终结果汇总（多任务运行时）

这确保每次运行都可以从日志目录完整复现。
