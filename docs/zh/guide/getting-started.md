# 快速开始

本指南只覆盖一条最短路径：安装 SForge、拉取任务定义、拉取预构建任务镜像、启动 Judge Server、运行 Agent、查看结果。默认使用 **Docker backend**。

::: tip 规模
Docker backend 只适合小批量任务。在单机上并发运行大量任务（约 20 个以上）即使是高性能服务器也会被耗尽——完整套件请使用 [Kubernetes backend](/zh/configuration/container-backends)，并采用[官方 leaderboard 配置](/zh/examples/all-tasks-k8s)。
:::

::: warning 费用
前沿模型的运行费用很高：单个任务跑满官方 12 小时预算，API 费用可达**数百甚至上千美元**。建议先按本指南用单任务 + 较短 `--timeout` 试跑，摸清费用水平后再扩大规模。
:::

## 前置依赖

- **Linux**：SForge 目前面向 Linux 宿主机。

  ::: warning
  默认 Docker backend 需要直接访问宿主机 Docker；在容器内运行会遇到 Docker-in-Docker 问题。
  :::

- **Docker Engine**：用于拉取任务镜像，并运行 Work/Judge 容器；Docker daemon 必须处于运行状态，可用以下命令验证：

  ```bash
  docker run hello-world
  ```

- **Python >= 3.10**。

## 安装 SForge

安装发布包：

```bash
pip install sforge
```

如需使用 [E2B 后端](/zh/configuration/container-backends#e2b-后端)，请带上 `e2b` extra：`pip install "sforge[e2b]"`。

也可以从源码安装：

```bash
git clone https://github.com/ByteDance-Seed/EdgeBench.git
cd SForge
pip install -e .
```

确认 CLI 可用：

```bash
sforge --help
```

## 运行 Ad Placement Optimization

[Ad Placement Optimization](https://huggingface.co/datasets/ByteDance-Seed/EdgeBench/blob/main/ad_placement_optimization.json) 是 EdgeBench 里的一个 C++ 优化任务，这里用它演示完整流程。

### 1. 拉取任务定义

```bash
sforge fetch-tasks edgebench
```

该命令会把默认 `edgebench` 的任务定义下载到 `./tasks`。你可以用下面命令确认任务可见：

```bash
sforge list
```

### 2. 拉取镜像

```bash
sforge pull --task ad_placement_optimization --registry seededge
```

这会拉取该任务的 base、work、judge 预构建镜像。镜像名由 benchmark 名、镜像角色、任务/基础镜像 key 和内容哈希组成，例如：

- `<benchmark>.base.cpp:<hash>`
- `<benchmark>.work.ad_placement_optimization:<hash>`
- `<benchmark>.judge.ad_placement_optimization:<hash>`

### 3. 启动 Judge Server

打开第二个终端：

```bash
sforge serve
```

Judge Server 默认监听 `0.0.0.0:8080`。

### 4. 运行 Agent

回到第一个终端：

```bash
SFORGE_AGENT_API_KEY="sk-ant-xxxx" \
sforge run --task ad_placement_optimization --agent claude-code \
  --model claude-opus-4-8 \
  --timeout 7200 \
  --run-id ad-placement-001
```

Agent 会在 Work 容器中工作，向 Judge Server 提交代码，接收测试反馈，并持续迭代直到超时或完成。

## 查看结果

启动 Web UI 可以实时查看运行结果：

```bash
sforge visualizer
```

然后打开 `http://127.0.0.1:8000/`。

如果更习惯手动查看文件，运行产物也会保存在 `logs/runs/<run-id>/<task-id>/`：

```bash
tail -f logs/runs/ad-placement-001/ad_placement_optimization/agent_output.txt
cat logs/runs/ad-placement-001/ad_placement_optimization/final_result.json
```

## 接下来

- 需要切换 Agent 或模型：看[支持的 Agent](./agents)。
- 需要配置 API key、镜像源、代理或资源限制：看[环境变量](/zh/configuration/environment-variables)和[网络配置](/zh/configuration/network-setup)。
- 需要完整命令和 flag：看 [CLI 命令参考](/zh/reference/cli)。
- 需要开发新的 benchmark 或任务：看[开发者文档](/zh/tasks/integration-guide)。
