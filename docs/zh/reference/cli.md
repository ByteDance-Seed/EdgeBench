---
title: CLI 命令参考
---

# CLI 命令参考

SForge 统一通过 `sforge <command>` 调用。

对于大多数评测用户，核心流程只需要四个命令：

```bash
sforge fetch-tasks edgebench
sforge pull --task ad_placement_optimization --registry seededge
sforge serve
sforge run --task ad_placement_optimization --agent claude-code
```

`build`、`push`、`hub` 等偏开发者的命令放在本页末尾。它们主要用于接入任务、维护 benchmark，或搭建共享基础设施。

## 命令分组

### 评测流程

| 子命令 | 用途 | 关键选项 |
|--------|------|----------|
| `fetch-tasks` | 下载 benchmark 任务定义 | `benchmark`、`--repo`、`--revision` |
| `list` | 列出可用任务定义 | 无 |
| `pull` | 从 registry 拉取预构建任务镜像 | `--task`、`--registry` |
| `serve` | 启动 Judge HTTP 服务器 | `--host`、`--port` |
| `run` | 在任务上运行 Agent | `--task`、`--experiment`、`--agent`、`--model`、`--timeout`、`--judge-url` |
| `eval` | 直接评测提交归档 | `--task`、`--archive`、`--run-id`、`--timeout`、`--json` |
| `proxy` | 启动宿主机侧 LLM API 反向代理 | `--target`、`--host`、`--port` |
| `visualizer` | 启动本地结果查看器 | `--runs-dir`、`--tasks-dir`、`--host`、`--port` |

### 开发者 / benchmark 维护

| 子命令 | 用途 | 关键选项 |
|--------|------|----------|
| `build` | 本地构建 base、work、judge 镜像 | `--task`、`--force-rebuild`、`--force-rebuild-with-base` |
| `push` | 将本地构建的镜像推送到 registry | `--task`、`--registry` |

## 全局选项

以下选项适用于所有子命令：

| 选项 | 默认值 | 说明 |
|------|--------|------|
| `--log-dir` | `logs/` | 覆盖日志输出目录 |
| `--tasks-dir` | `tasks/` | 覆盖任务定义目录 |
| `--silent` | `false` | 抑制详细输出（多任务并行运行时自动启用） |

## sforge fetch-tasks

从 HuggingFace Hub 下载 benchmark 任务定义。EdgeBench 使用：

```bash
sforge fetch-tasks edgebench
```

高级用法：

```bash
sforge fetch-tasks --repo ByteDance-Seed/EdgeBench --revision main
```

| Flag / 参数 | 说明 |
|-------------|------|
| `benchmark` | benchmark 名，例如 `edgebench` |
| `--repo` | HuggingFace dataset repo ID，会覆盖 benchmark 名映射 |
| `--revision` | 要下载的 Git revision、branch、tag 或 commit hash |

## sforge list

列出可用的任务。

```bash
sforge list
```

输出列：ID、Name、Base Image、Parser。

## sforge pull

从远程容器镜像仓库拉取预构建的镜像。标准评测流程中，应在 `sforge fetch-tasks edgebench` 之后、`sforge serve` / `sforge run` 之前执行。

```bash
sforge pull --task ad_placement_optimization --registry seededge
sforge pull --task ad_placement_optimization gitlet --registry seededge
```

| 选项 | 说明 |
|------|------|
| `--task` | 一个或多个任务 ID（必填） |
| `--registry` | 远程容器镜像仓库或已配置的 registry 别名（覆盖 `SFORGE_REGISTRY` 环境变量） |

镜像标签基于内容哈希，因此只会拉取与当前任务定义匹配的镜像。

## sforge serve

启动 Judge HTTP 服务器。必须在运行 `sforge run` 之前启动——Agent 容器通过它提交代码进行评测。

```bash
sforge serve
sforge serve --port 8080
sforge serve --host 0.0.0.0 --port 9090
```

| 选项 | 默认值 | 说明 |
|------|--------|------|
| `--host` | `0.0.0.0` | 绑定地址 |
| `--port` | `8080` | 监听端口 |

服务器暴露 [Judge HTTP API](/zh/reference/judge-api)，同时处理标准的测试驱动提交和交互式游戏会话。

## sforge run

在一个 task 上运行 Agent，或批量调度多个相互独立的 task 评测。每个 task 始终拥有各自的
Work 环境、Judge session、结果和清理生命周期。

### 基本用法

```bash
# 标准 Agent 模式
sforge run --task ad_placement_optimization --agent claude-code

# 批量调度多个独立 task
sforge run --task ad_placement_optimization gitlet rookiedb --agent claude-code

# 实验配置模式
sforge run --experiment experiment.yaml
```

### 完整选项

| 选项 | 默认值 | 说明 |
|------|--------|------|
| `--task` | 必填* | 一个或多个任务 ID（空格分隔）。传入多个 ID 时，CLI 批量调度多个独立 task，不会把它们合并为一次评测。 |
| `--agent` | 必填* | Agent 名称（如 `claude-code`、`codex`）。除非指定 `--experiment`，否则必填。 |
| `--experiment` | --- | 实验 YAML 配置文件路径。如果未指定 `--task`，运行 YAML 中的全部任务；如果指定了 `--task`，则只运行该子集并套用实验配置。 |
| `--model` | --- | 模型覆盖（如 `claude-opus-4-8`） |
| `--effort` | Agent 默认值 | 推理强度（`low`、`medium`、`high` 或 `max`）。SForge 会在所选 Agent 支持时映射到其原生配置。 |
| `--timeout` | `3600` | Agent 超时时间（秒） |
| `--eval-interval` | `300` | 自动评测守护进程的间隔时间（秒） |
| `--run-id` | 随机生成 | 运行标识符，用于跟踪和日志组织 |
| `--judge-url` | `http://host.docker.internal:8080` | 容器内部看到的 Judge 服务器 URL |
| `--backend` | `docker` | 容器后端（`docker`、`k8s` 或 `e2b`） |
| `--stagger` | --- | 将任务启动均匀分散在 N 秒内（如 `--stagger 300`） |
| `--max-submissions` | --- | 每次运行的最大 Agent 提交次数 |
| `--submission-cooldown` | --- | Agent 两次提交之间的最小间隔（秒） |
| `--work-cpu-limit` | --- | Work 容器的 CPU 数量限制 |
| `--work-mem-limit` | --- | Work 容器的内存限制（如 `'8g'`） |
| `--judge-cpu-limit` | --- | Judge 容器的 CPU 数量限制 |
| `--judge-mem-limit` | --- | Judge 容器的内存限制（如 `'4g'`） |
| `--disable-stop-hook` | `false` | 禁用 stop hook（允许 Agent 正常退出） |
| `--disable-auto-eval` | `false` | 禁用后台自动评测守护进程 |
| `--disable-auto-resume` | `false` | 禁用 Agent 异常退出时的自动恢复 |
| `--disable-internet` | `false` | 强制网络隔离（仅允许 Judge 服务器 + API 访问）。需要 `sudo` 权限来配置 iptables。与 `--enable-internet` 互斥。 |
| `--enable-internet` | `false` | 强制开启完整网络访问（覆盖任务的 `internet: false` 设置）。与 `--disable-internet` 互斥。 |

::: warning 必填参数
`--task` 或 `--experiment` 必须指定其一。除非指定了 `--experiment`，否则 `--agent` 为必填。
:::

### 输出文件

运行完成后，结果写入 `logs/runs/<run_id>/<task_id>/`：

```
logs/runs/<run_id>/<task_id>/
├── run_config.json      # 本次运行的生效配置
├── run_agent.log        # 框架层日志
├── install_output.txt   # Agent 安装输出
├── agent_prompt.md      # 增强后的 prompt
├── agent_output.txt     # Agent 完整对话日志
├── final_archive.tar.gz # 最终代码快照
├── final_result.json    # 最优分、总轮次等汇总
└── submissions/         # 每轮评测详情
```

## sforge eval

直接对归档文件进行评测，无需运行 Agent。适用于手动测试解决方案。

```bash
sforge eval --task ad_placement_optimization --archive solution.tar.gz
sforge eval --task ad_placement_optimization --archive solution.tar.gz --json
sforge eval --task ad_placement_optimization --archive - < solution.tar.gz
```

| 选项 | 说明 |
|------|------|
| `--task` | 任务 ID（必填） |
| `--archive` | `.tar.gz` 归档文件路径，或 `-` 从标准输入读取 |
| `--run-id` | 自定义运行 ID，用于日志组织 |
| `--timeout` | 评测超时时间（秒） |
| `--json` | 同时输出完整的 JSON 报告 |
| `--backend` | 容器后端（`docker`、`k8s` 或 `e2b`） |
| `--judge-cpu-limit` | Judge 容器的 CPU 数量限制 |
| `--judge-mem-limit` | Judge 容器的内存限制（如 `'4g'`） |

## sforge proxy

启动本地 API 反向代理。设计用于与 `--disable-internet` 配合使用。

```bash
sforge proxy --target https://api.anthropic.com --port 9090
```

| 选项 | 默认值 | 说明 |
|------|--------|------|
| `--target` | 必填 | 上游 API URL |
| `--host` | `0.0.0.0` | 绑定地址 |
| `--port` | `9090` | 监听端口 |

需要预先配置 `SFORGE_HTTPS_PROXY`（或 `HTTPS_PROXY`）。

## sforge visualizer

启动基于 Web 的结果查看器，用于浏览运行结果和比较不同任务、不同运行的分数。

```bash
sforge visualizer
sforge visualizer --runs-dir logs/runs --port 8000
```

| 选项 | 默认值 | 说明 |
|------|--------|------|
| `--runs-dir` | `logs/runs` | 运行结果文件夹目录 |
| `--tasks-dir` | `tasks/` | 任务 JSON 定义目录（用于获取 score_direction） |
| `--host` | `127.0.0.1` | 绑定地址 |
| `--port` | `8000` | 监听端口 |

启动后在浏览器中打开 `http://127.0.0.1:8000/`。

## 开发者命令

以下命令主要面向接入任务、维护 benchmark JSON 定义，或搭建共享基础设施的用户。

### sforge build

为一个或多个任务构建 Docker 镜像（base + work + judge）。评测用户通常使用 `sforge pull`，不需要本地构建。

```bash
sforge build --task ad_placement_optimization
sforge build --task ad_placement_optimization gitlet rookiedb
sforge build --task ad_placement_optimization --force-rebuild
```

| 选项 | 说明 |
|------|------|
| `--task` | 一个或多个任务 ID（必填，空格分隔） |
| `--force-rebuild` | 强制重新构建 work + judge 镜像（跳过 base） |
| `--force-rebuild-with-base` | 强制重新构建所有镜像，包括 base |

### sforge push

将本地构建的镜像推送到远程容器镜像仓库。

```bash
sforge push --task ad_placement_optimization --registry registry.example.com/sforge
sforge push --task ad_placement_optimization gitlet --registry registry.example.com/sforge
```

| 选项 | 说明 |
|------|------|
| `--task` | 一个或多个任务 ID（必填） |
| `--registry` | 远程容器仓库 URL（覆盖 `SFORGE_REGISTRY` 环境变量） |
