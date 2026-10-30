---
title: "单任务运行 (E2B)"
---

# 单任务运行 (E2B)

在 [E2B](https://e2b.dev) 云端 Sandbox 中运行一道 EdgeBench 任务（`ad_placement_optimization`）。不需要本地 Docker daemon 或 Kubernetes 集群；唯一需要自己托管的是 judge，而它由 `sforge run` 自动启动。

::: tip
E2B 套餐限制并发数和 Sandbox 生命周期；`--timeout` 要明显小于套餐允许的最长 Sandbox 生命周期。详见[容器后端](/zh/configuration/container-backends#e2b)。
:::

::: warning 费用
前沿模型的运行费用很高——单个任务跑满官方 12 小时预算，API 费用可达数百甚至上千美元，另有 E2B Sandbox 费用。建议先用较短的 `--timeout`（本例为 2 小时）试跑，摸清费用水平后再扩大规模。
:::

## 前置依赖

| 依赖 | 检查方式 |
|------|----------|
| E2B 账号和 API key | 从 E2B 控制台获取 `E2B_API_KEY` |
| 一台有**公网可达**地址的主机 | Sandbox 通过公网访问其上的 judge |
| Python 3.11–3.13 | `python --version` |

## 使用 Claude Code + Anthropic API

### 1. 安装带 E2B extra 的 SForge

```bash
git clone https://github.com/ByteDance-Seed/EdgeBench.git
cd EdgeBench
pip install -e ".[e2b]"
export E2B_API_KEY="e2b_xxxx"
```

### 2. 构建任务的 Template

E2B Sandbox 从 Template 启动，而不是从 Docker 镜像启动。每个任务镜像需要从 Docker Hub 上的预构建镜像
构建一个 Template，每个任务版本只需做一次。在仓库根目录执行：

```bash
python - ad_placement_optimization <<'EOF'
import sys
from e2b import Template
from sforge.harness.backend.e2b_backend import e2b_template_reference
from sforge.harness.config import load_config
from sforge.harness.docker_build import remote_ref
from sforge.harness.task_spec import load_task

config = load_config({"benchmark_dir": "edgebench"})
for task_id in sys.argv[1:]:
    spec = load_task(config.benchmark.root / "tasks" / task_id)
    for key in (spec.work_image_key, spec.judge_image_key):
        name = e2b_template_reference(key)  # edgebench.work.ad_placement_optimization:<hash> -> edgebench-work-ad-placement-optimization:<hash>
        Template.build(Template().from_image(remote_ref(config.image_registry, key)), name,
                       cpu_count=4, memory_mb=16384)
        print("built", name)
EOF
```

CPU 和内存在构建 Template 时就固定了，请选择套餐允许、任务够用的值。SForge 按推导出的名称查找
Template；Template 在共享 namespace 下或用了其他名称时，见[容器后端](/zh/configuration/container-backends#e2b)。

### 3. 运行 Agent

```bash
SFORGE_AGENT_API_KEY="sk-ant-xxxx" \
sforge run --backend e2b \
  --task ad_placement_optimization --agent claude-code \
  --model claude-opus-4-8[1m] \
  --timeout 7200 \
  --judge-advertise YOUR_PUBLIC_HOST --judge-port 8080 \
  --run-id ad-placement-optimization-e2b-001
```

`sforge run` 在本机 8080 端口提供 judge，Sandbox 通过 `http://YOUR_PUBLIC_HOST:8080` 访问，所以该端口
必须对公网开放。API key 只留在本机。

### 4. 查看结果

```bash
sforge viewer
# 打开 http://127.0.0.1:8000
```

或直接查看文件：

```bash
ls logs/runs/ad-placement-optimization-e2b-001/ad_placement_optimization/
cat logs/runs/ad-placement-optimization-e2b-001/ad_placement_optimization/final_result.json
```

运行结束后 Sandbox 会自动删除。


## 使用第三方模型

模型路由和上下文窗口配置与 Docker 示例完全相同，只是 backend 参数不同。请参照
[使用第三方模型](/zh/examples/single-task-docker#使用第三方模型)，并在 `sforge run` 命令中加上 E2B 参数，例如：

```bash
export SFORGE_AGENT_API_KEY="your-deepseek-key"
export SFORGE_AGENT_API_BASE_URL="https://api.deepseek.com/anthropic"
export SFORGE_AGENT_EXTRA_ENV="ANTHROPIC_MODEL=deepseek-v4-pro[1m],ANTHROPIC_DEFAULT_OPUS_MODEL=deepseek-v4-pro[1m],ANTHROPIC_DEFAULT_SONNET_MODEL=deepseek-v4-pro[1m],ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-v4-pro[1m],CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-pro[1m]"

sforge run --backend e2b \
  --task ad_placement_optimization --agent claude-code \
  --model deepseek-v4-pro[1m] \
  --timeout 7200 \
  --judge-advertise YOUR_PUBLIC_HOST --judge-port 8080 \
  --run-id ad-placement-deepseek-e2b-001
```


## LLM 评分任务

`college_english_exam_bank` 需要评分凭据，设置方法与 Docker 相同，见
[LLM 评分任务](/zh/examples/single-task-docker#llm-评分任务)。
