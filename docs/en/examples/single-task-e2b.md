---
title: "Single Task (E2B)"
---

# Single Task (E2B)

Run one EdgeBench task (`ad_placement_optimization`) in [E2B](https://e2b.dev) cloud Sandboxes. No local Docker daemon or Kubernetes cluster is needed; the only thing you host yourself is the judge, which `sforge run` starts for you.

::: tip
Your E2B plan bounds concurrency and Sandbox lifetime; keep `--timeout` well below the plan's maximum Sandbox lifetime. See [Container Backends](/en/configuration/container-backends#e2b).
:::

::: warning Cost
Frontier-model runs are expensive — one task over the official 12-hour budget can cost hundreds to over a thousand USD in API usage, plus E2B Sandbox time. Start with a short `--timeout` (this example uses 2 hours) to gauge your burn rate before scaling up.
:::

## Prerequisites

| Requirement | Check |
|-------------|-------|
| E2B account and API key | `E2B_API_KEY` from the E2B dashboard |
| A host with a **publicly routable** address | Sandboxes reach the judge on it over the internet |
| Python 3.11–3.13 | `python --version` |

## Using Claude Code with Anthropic API

### 1. Install SForge with the E2B extra

```bash
git clone https://github.com/ByteDance-Seed/EdgeBench.git
cd EdgeBench
pip install -e ".[e2b]"
export E2B_API_KEY="e2b_xxxx"
```

### 2. Build the task's Templates

E2B Sandboxes start from Templates, not Docker images. Build one Template per task
image from the pre-built images on Docker Hub; this is a one-time step per task version.
Run from the repository root:

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

CPU and memory are fixed when a Template is built; pick values your plan allows and the
task needs. SForge finds the Templates by the derived name; for Templates under a
shared namespace or other names, see [Container Backends](/en/configuration/container-backends#e2b).

### 3. Run the agent

```bash
SFORGE_AGENT_API_KEY="sk-ant-xxxx" \
sforge run --backend e2b \
  --task ad_placement_optimization --agent claude-code \
  --model claude-opus-4-8[1m] \
  --timeout 7200 \
  --judge-advertise YOUR_PUBLIC_HOST --judge-port 8080 \
  --run-id ad-placement-optimization-e2b-001
```

`sforge run` serves the judge on port 8080 of this machine, and the Sandboxes reach
it at `http://YOUR_PUBLIC_HOST:8080`, so that port must be open to the internet. The
API key stays on this machine.

### 4. View results

```bash
sforge viewer
# Open http://127.0.0.1:8000
```

Or inspect files directly:

```bash
ls logs/runs/ad-placement-optimization-e2b-001/ad_placement_optimization/
cat logs/runs/ad-placement-optimization-e2b-001/ad_placement_optimization/final_result.json
```

Sandboxes are deleted automatically when the run finishes.


## Using a Third-Party Model

The model-routing and context-window settings are identical to the Docker
example; only the backend flags change. Follow
[Using a Third-Party Model](/en/examples/single-task-docker#using-a-third-party-model)
and add the E2B flags to the `sforge run` command, for example:

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


## LLM-Graded Tasks

`college_english_exam_bank` needs grading credentials, set exactly as on Docker; see
[LLM-Graded Tasks](/en/examples/single-task-docker#llm-graded-tasks).
