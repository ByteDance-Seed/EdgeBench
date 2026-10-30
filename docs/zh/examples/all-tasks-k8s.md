---
title: "全部任务 (Kubernetes)"
---

# 全部任务 (Kubernetes)

在 Kubernetes 集群上运行完整的公开 EdgeBench 套件（51 道题）。

::: tip 官方 leaderboard 配置
本示例中的实验 YAML 就是 **EdgeBench 官方 leaderboard 配置**（12 小时预算、启用 stop hook 和 auto-eval；CPU 和内存来自各任务的 `task.toml`）。要得到与 leaderboard 可比的结果，只修改 `env` 和 `model`。
:::

::: warning 费用
使用前沿模型（如 Claude Opus）时，单个任务跑满 12 小时预算的 API 费用可达**数百甚至上千美元**；完整跑一遍 51 道题的花费是五位数美元。请先用较短的 `--timeout` 在单个任务上摸清费用水平。
:::

## 前置依赖

| 依赖 | 检查方式 |
|------|----------|
| 已配置 `kubectl` 的 Linux 主机 | `kubectl cluster-info` |
| NetworkPolicy 支持（用于网络隔离） | CNI 会执行 NetworkPolicy；kubeconfig 可以在目标 namespace 创建/删除 `NetworkPolicy` |
| 本机有一个 Pod 能访问到的地址 | 例如内网 IP |
| Python 3.11–3.13 | `python --version` |

## 步骤

### 1. 安装 SForge

```bash
git clone https://github.com/ByteDance-Seed/EdgeBench.git
cd EdgeBench
pip install -e .
sforge list            # 确认任务可见
```

### 2. 确定 Pod 从哪里拉镜像

默认情况下 Pod 从 `docker.io/seededge` 拉取预构建镜像。Docker Hub 对匿名拉取限流，有些镜像也很大
（Lean 任务约 15 GB），因此多次运行时，建议把镜像同步到与集群**同一网络**内的 registry：

```bash
sforge pull --all                                  # 从 Docker Hub 拉到本地 Docker（先 docker login）
sforge push --all --registry <registry-ip>:5000
export SFORGE_K8S_IMAGE_REGISTRY=<registry-ip>:5000
```

之后 Pod 拉取 `<registry-ip>:5000/<镜像>:<tag>`。验证：

```bash
curl -s http://<registry-ip>:5000/v2/_catalog | head -c 300
```

<details>
<summary>搭建私有 Docker registry</summary>

如果还没有私有 registry，一条命令即可启动：

```bash
docker run -d -p 5000:5000 --restart=always --name registry registry:2
```

**配置 insecure（HTTP）registry：** Docker 默认只信任 HTTPS registry。对于局域网内的 HTTP registry，
需要在每台推送或拉取的机器（包括 K8s 节点）上配置信任：

1. 编辑 `/etc/docker/daemon.json`（不存在则新建）：

   ```json
   {
     "insecure-registries": ["<registry-ip>:5000"]
   }
   ```

2. 重启 Docker：

   ```bash
   sudo systemctl restart docker
   ```

3. 对于使用 containerd 的 K8s 节点，在**集群每个节点**的 `/etc/containerd/config.toml` 中添加该
   registry（Pod 可能被调度到任意节点）：

   ```toml
   [plugins."io.containerd.grpc.v1.cri".registry.configs."<registry-ip>:5000".tls]
     insecure_skip_verify = true
   ```

   然后重启 containerd：`sudo systemctl restart containerd`

</details>

### 3. 配置 LLM 评分任务

`college_english_exam_bank` 用 LLM 评分，要在本机传入凭据
（见 [LLM 评分任务](/zh/examples/single-task-docker#llm-评分任务)）：

```bash
export SFORGE_JUDGE_EXTRA_ENV="SFORGE_JUDGE_API_KEY=your-key,SFORGE_JUDGE_API_BASE_URL=https://api.openai.com/v1,SFORGE_JUDGE_MODEL=gpt-5.5"
```

### 4. 运行实验

带注释的 [`experiment.yaml`](https://github.com/ByteDance-Seed/EdgeBench/blob/main/examples/all-tasks-k8s/experiment.yaml)
列出了所有任务及其运行设置，字段说明见[实验配置](/zh/configuration/experiments)。

```bash
sforge run --experiment examples/all-tasks-k8s/experiment.yaml \
  --judge-advertise <本机IP> --judge-port 8080 \
  --run-id edgebench-001
```

`sforge run` 在本机 8080 端口提供 judge，Pod 通过 `http://<本机IP>:8080` 访问。

任务会在总共 600 秒内错开启动。监控进度：

```bash
sforge viewer
# 打开 http://127.0.0.1:8000
```

或查看某个任务的日志：

```bash
tail -f logs/runs/edgebench-001/ad_placement_optimization/agent_output.txt
```


## 其他实验配置

示例目录还包含其他 Agent 和第三方模型的实验配置：

- [`experiment-codex.yaml`](https://github.com/ByteDance-Seed/EdgeBench/blob/main/examples/all-tasks-k8s/experiment-codex.yaml) — Codex + GPT-5.5
- [`experiment-deepseek.yaml`](https://github.com/ByteDance-Seed/EdgeBench/blob/main/examples/all-tasks-k8s/experiment-deepseek.yaml) — Claude Code + DeepSeek V4 Pro（1M 上下文）
- [`experiment-glm.yaml`](https://github.com/ByteDance-Seed/EdgeBench/blob/main/examples/all-tasks-k8s/experiment-glm.yaml) — Claude Code + GLM 5.1（200K 上下文）

```bash
sforge run --experiment examples/all-tasks-k8s/experiment-codex.yaml \
  --judge-advertise <本机IP> --judge-port 8080 \
  --run-id edgebench-codex-001
```

`SFORGE_K8S_*` 变量见[环境变量](/zh/configuration/environment-variables#容器后端)。
