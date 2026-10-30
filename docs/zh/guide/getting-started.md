# 快速开始

本指南用默认的 **Docker backend** 完整跑一道 EdgeBench 任务：安装 SForge、获取任务镜像、运行 Agent、查看结果。

::: tip 规模
Docker backend 只适合小批量任务。在单机上并发运行大量任务（约 20 个以上）即使是高性能服务器也会被耗尽——完整套件请使用 [Kubernetes backend](/zh/configuration/container-backends)，并采用[官方 leaderboard 配置](/zh/examples/all-tasks-k8s)。
:::

::: warning 费用
前沿模型的运行费用很高：单个任务跑满官方 12 小时预算，API 费用可达**数百甚至上千美元**。建议先按本指南用单任务 + 较短 `--timeout` 试跑，摸清费用水平后再扩大规模。
:::

## 前置依赖

- **Linux**（x86_64）：SForge 目前面向 Linux 宿主机。

  ::: warning
  Docker backend 需要直接访问宿主机 Docker；把 SForge 本身放在容器里运行会遇到 Docker-in-Docker 问题。
  :::

- **Docker Engine**，且 daemon 处于运行状态。验证：

  ```bash
  docker run hello-world
  ```

- **Python 3.11–3.13**。

## 安装 SForge

任务就在仓库里，因此从源码安装：

```bash
git clone https://github.com/ByteDance-Seed/EdgeBench.git
cd EdgeBench
pip install -e .            # 使用 E2B backend 时加上 e2b extra：pip install -e ".[e2b]"
```

以下命令都在仓库根目录执行：SForge 从 `edgebench/` 读取 EdgeBench（换别的 benchmark 用 `-b <目录>` 或 `SFORGE_BENCHMARK`）。列出它的任务：

```bash
sforge list
```

## 运行 Ad Placement Optimization

[Ad Placement Optimization](https://github.com/ByteDance-Seed/EdgeBench/tree/main/edgebench/tasks/ad_placement_optimization) 是一道 C++ 优化题，这里用作一个小的端到端示例。

### 1. 获取镜像

拉取预构建的 work 和 judge 镜像：

```bash
sforge pull --task ad_placement_optimization
```

镜像 tag 是任务目录内容的哈希，例如 `edgebench.work.ad_placement_optimization:7b2f533ff7d4`，所以拉到的镜像一定和你的代码一致。如果你改过这道题，或者不想下载，也可以本地构建：

```bash
sforge build --task ad_placement_optimization
```

镜像的来源见[预构建镜像](/zh/features/prebuilt-images)。

### 2. 运行 Agent

```bash
SFORGE_AGENT_API_KEY="sk-ant-xxxx" \
sforge run --task ad_placement_optimization --agent claude-code \
  --model claude-opus-4-8 \
  --timeout 7200 \
  --run-id ad-placement-001
```

`sforge run` 会在同一进程里启动自己的 judge server。Agent 在 work 容器里工作，用 `sforge-submit` 提交代码，拿到分数和反馈后继续改进，直到超时。它的模型请求经由 judge server 转发，真实 API key 只在 judge server 上，不会进入容器。

## 查看结果

启动结果查看页面：

```bash
sforge viewer
```

然后打开 `http://127.0.0.1:8000/`，可以看到分数曲线、每次提交和 token 用量。要在 Agent 自己的界面里查看对话记录：

```bash
sforge replay --run-id ad-placement-001 --task ad_placement_optimization
```

运行输出都在 `logs/runs/<run-id>/<task-id>/` 下：

```bash
tail -f logs/runs/ad-placement-001/ad_placement_optimization/agent_output.txt
cat logs/runs/ad-placement-001/ad_placement_optimization/final_result.json
```

## 下一步

- 换 Agent 或模型：[支持的 Agent](./agents)。
- API key、代理、资源限制：[环境变量](/zh/configuration/environment-variables)和[网络配置](/zh/configuration/network-setup)。
- 全部命令和参数：[CLI 命令](/zh/reference/cli)。
- 修题或加题：[任务格式](/zh/tasks/task-format)。
