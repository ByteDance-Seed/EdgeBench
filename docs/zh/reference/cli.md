---
title: CLI 命令参考
---

# CLI 命令参考

SForge 只有一个 CLI 入口：`sforge <command>`。操作任务的命令（`list`、`pull`、`build`、`push`、`run`、`eval`、`serve`）用 `-b DIR` / `--benchmark DIR` 指定 benchmark 目录（默认：`SFORGE_BENCHMARK`，否则 `edgebench`，即本仓库的 EdgeBench 目录）。

## 命令分组

### 评测

| 子命令 | 用途 | 主要参数 |
|--------|------|----------|
| `list` | 列出 benchmark 的任务 | 无 |
| `pull` | 拉取预构建任务镜像 | `--task` / `--all`、`--registry` |
| `run` | 在任务上运行 Agent | `--task`、`--experiment`、`--agent`、`--model`、`--timeout`、`--backend` |
| `eval` | 直接给一个解答 archive 评分 | `--task`、`--archive`、`--json` |
| `serve` | 启动独立的 judge server | `--host`、`--port` |
| `viewer` | 启动结果查看页面 | `--runs-dir`、`--host`、`--port` |
| `replay` | 在 Agent 自己的界面里打开一次运行的会话 | `--run-id`、`--task`、`--session` |

### 任务开发

| 子命令 | 用途 | 主要参数 |
|--------|------|----------|
| `build` | 从任务目录构建 base、work 和 judge 镜像 | `--task` / `--all`、`--force-rebuild`、`--force-rebuild-with-base` |
| `push` | 把镜像推送到 registry | `--task` / `--all`、`--registry` |

## 全局参数

这些参数写在子命令之前（`sforge --log-dir ... run ...`）：

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `--log-dir` | `logs/` | 构建日志和运行输出目录 |
| `--silent` | `false` | 减少输出（多任务运行时自动启用） |

## sforge list

```bash
sforge list
```

输出列：ID、Name、Base、Version。

## sforge pull

拉取任务的 work 和 judge 镜像，并打上本地 key 作为 tag。

```bash
sforge pull --task ad_placement_optimization
sforge pull --task ad_placement_optimization smt_solver
sforge pull --all
```

| 参数 | 说明 |
|------|------|
| `--task` | 一个或多个任务 ID |
| `--all` | 所有任务 |
| `--registry` | Registry 前缀（默认：`SFORGE_REGISTRY`，否则 benchmark 的 `registry`） |

Tag 是任务目录的内容哈希，只会拉取与你的代码一致的镜像。见[预构建镜像](/zh/features/prebuilt-images)。

## sforge run

在一道或多道题上运行 Agent；每道题有各自的容器和结果。

```bash
# 一道题
sforge run --task ad_placement_optimization --agent claude-code

# 多道题，各自独立运行
sforge run --task ad_placement_optimization smt_solver --agent claude-code

# 实验配置
sforge run --experiment examples/all-tasks-k8s/experiment.yaml
```

不传 `--judge-url` 时，`sforge run` 在同一进程的一个线程里自己提供 judge。

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `--task` | 必填* | 一个或多个任务 ID；多个 ID 会批量调度彼此独立的运行 |
| `--agent` | 必填* | `claude-code`、`codex` 或 `opencode`，可带 `@<版本>`（如 `codex@0.145.0`）。使用 `--experiment` 时不需要 |
| `--experiment` | --- | 实验 YAML。不带 `--task` 时运行其中所有任务；带 `--task` 时只运行这些任务，并使用实验配置 |
| `--model` | Agent 默认 | 模型名 |
| `--effort` | Agent 默认 | 推理强度：`low`、`medium`、`high` 或 `max` |
| `--timeout` | Agent 默认 | Agent 的时间预算（秒） |
| `--run-id` | 随机 | 运行标识；输出写到 `logs/runs/<run-id>/` |
| `--backend` | `docker` | `docker`、`k8s` 或 `e2b` |
| `--judge-port` | 任意空闲端口 | 进程内 judge 的端口 |
| `--judge-advertise` | `host.docker.internal` | sandbox 访问进程内 judge 时使用的本机地址。`k8s` 和 `e2b` 必填 |
| `--judge-url` | --- | 使用该 URL 上的外部 judge server（`sforge serve`），从 sandbox 内部看到的地址 |
| `--eval-interval` | `300` | Auto-eval 间隔（秒） |
| `--stagger` | --- | 在 N 秒内均匀错开任务启动 |
| `--max-submissions` | 不限 | 每道题 Agent 主动提交的最大次数 |
| `--submission-cooldown` | 无 | 两次 Agent 提交之间的最小间隔（秒） |
| `--work-cpu-limit` | 任务设置 / 无 | work 容器的 CPU 数 |
| `--work-mem-limit` | 任务设置 / 无 | work 容器的内存（如 `8g`） |
| `--judge-cpu-limit` | 任务设置 / 无 | judge 容器的 CPU 数 |
| `--judge-mem-limit` | 任务设置 / 无 | judge 容器的内存 |
| `--disable-stop-hook` | `false` | 允许 Agent 正常退出 |
| `--disable-auto-eval` | `false` | 关闭后台 auto-eval |
| `--disable-auto-resume` | `false` | Agent 异常退出后不再自动拉起 |
| `--disable-internet` | `false` | 隔离所有任务的 work 容器（只能访问 judge）。Docker 上需要 iptables 免密 `sudo` |
| `--enable-internet` | `false` | 所有任务的 work 容器都可联网。与 `--disable-internet` 互斥 |

### 运行输出

```
logs/runs/<run_id>/
├── run_config.json          # 所有任务的最终配置
├── experiment.yaml          # 实验文件副本（如有）
├── summary.json             # 多任务汇总
└── <task_id>/
    ├── run_config.json      # 该任务的生效配置（key 已脱敏）
    ├── run_agent.log        # harness 日志
    ├── agent_prompt.md      # 发给 Agent 的 prompt
    ├── agent_output.txt     # Agent stdout（Claude Code 和 Codex 为 JSON 行）
    ├── sessions/            # Agent 原生会话文件，每 60 秒同步
    ├── llm_requests.jsonl   # 每个模型请求一行，含 token 用量
    ├── run_history.json     # 所有提交
    ├── final_archive.tar.gz # 工作区的最终快照
    ├── final_result.json    # 最佳分数、轮次、耗时、token 用量
    └── submissions/
        ├── agent-1/         # judge_output.txt、result.json、report.json
        ├── auto-1/
        └── ...
```

## sforge eval

不运行 Agent，直接用某道题的 judge 给一个 archive 评分。适合测试解答和 judge 改动。

```bash
sforge eval --task ad_placement_optimization --archive solution.tar.gz
sforge eval --task ad_placement_optimization --archive solution.tar.gz --json
sforge eval --task ad_placement_optimization --archive - < solution.tar.gz
```

| 参数 | 说明 |
|------|------|
| `--task` | 任务 ID（必填） |
| `--archive` | 工作区的 `.tar.gz` archive，或 `-` 表示从 stdin 读取。与 Agent 提交一样按该题的提交路径过滤 |
| `--run-id` | 用于组织日志的运行 ID |
| `--timeout` | 评测超时（秒，默认为该题的 `timeout_sec`） |
| `--json` | 同时输出完整 JSON 报告 |
| `--backend` | `docker`、`k8s` 或 `e2b` |
| `--judge-cpu-limit` | judge 容器的 CPU 数 |
| `--judge-mem-limit` | judge 容器的内存（如 `4g`） |

## sforge serve

启动独立的 judge server，供多个 `sforge run` 进程或多台机器共用。运行通过 `--judge-url` 接入。

```bash
sforge serve
sforge serve --host 0.0.0.0 --port 9090
```

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `--host` | `0.0.0.0` | 监听地址 |
| `--port` | `8080` | 监听端口 |

它提供 [Judge HTTP API](/zh/reference/judge-api)：提交、游戏会话和 LLM 网关。它和接入的运行必须共享 `SFORGE_ADMIN_SECRET`（同一台机器、同一日志目录时自动共享）。

## sforge viewer

```bash
sforge viewer
sforge viewer --runs-dir logs/runs --port 8000
```

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `--runs-dir` | `<日志目录>/runs` | 运行目录 |
| `--host` | `127.0.0.1` | 监听地址 |
| `--port` | `8000` | 监听端口 |

见[结果查看与回放](/zh/features/viewer)。

## sforge replay

在 Agent 自己的界面里打开一次运行存档的会话（`claude --resume` 或 `codex resume`）。

```bash
sforge replay --run-id ad-placement-001 --task ad_placement_optimization
```

| 参数 | 说明 |
|------|------|
| `--run-id` | 运行 ID（必填） |
| `--task` | 任务 ID（必填） |
| `--session` | 会话 ID（默认最新的一个） |
| `--runs-dir` | 运行目录（默认 `<日志目录>/runs`） |

## sforge build

用本地 Docker 构建任务的 base、work 和 judge 镜像。缺失的 blob 会先下载。

```bash
sforge build --task ad_placement_optimization
sforge build --task ad_placement_optimization smt_solver
sforge build --all
sforge build --task ad_placement_optimization --force-rebuild
```

| 参数 | 说明 |
|------|------|
| `--task` | 一个或多个任务 ID |
| `--all` | 所有任务 |
| `--force-rebuild` | 即使 tag 已存在也重建 work 和 judge 镜像（不含 base） |
| `--force-rebuild-with-base` | 重建所有镜像，包括 base |

构建日志写到 `logs/build_images/<镜像>_<tag>.log`。

## sforge push

把任务的 base、work 和 judge 镜像推送到 registry 前缀下（`<registry>/<镜像>:<tag>`），与预构建镜像相同。

```bash
sforge push --task ad_placement_optimization --registry registry.example.com/sforge
sforge push --all --registry registry.example.com/sforge
```

| 参数 | 说明 |
|------|------|
| `--task` | 一个或多个任务 ID |
| `--all` | 所有任务 |
| `--registry` | Registry 前缀（默认：`SFORGE_REGISTRY`，否则 benchmark 的 `registry`） |
