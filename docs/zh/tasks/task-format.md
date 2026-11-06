---
title: 任务格式
---

# 任务格式

SForge 运行的是 benchmark。一个 benchmark 就是一个目录，其中每道题也是一个目录，以明文存放这道题的全部内容：prompt、工作区、评分程序、隐藏测试和数据。镜像是由它构建出来的产物。

```
<benchmark>/
  benchmark.toml           # 名称、镜像 registry、blob 地址
  tasks/<task_id>/         # 一道题一个目录
  bases/<name>/Dockerfile  # 可选：多道题共用的工具链镜像
```

用 `-b <目录>` 或 `SFORGE_BENCHMARK` 把这个目录交给 SForge；都不设置时用 `edgebench/`。本仓库的 [EdgeBench](https://github.com/ByteDance-Seed/EdgeBench/tree/main/edgebench) 在 `edgebench/` 下；它自己的出题规则（固定版本、数据上限、`NOTES.md`、状态）见 [`edgebench/tasks/SCHEMA.md`](https://github.com/ByteDance-Seed/EdgeBench/blob/main/edgebench/tasks/SCHEMA.md)。

## benchmark.toml

```toml
name = "edgebench"               # 镜像名：<name>.{base,work,judge}.<id>:<hash>
registry = "docker.io/seededge"  # 可选：sforge pull 和 Kubernetes 从这里拉镜像
blob_url = "https://github.com/ByteDance-Seed/EdgeBench/releases/download/task-blobs"  # 可选，见 Blob
```

## 题目目录

```
tasks/<task_id>/
  task.toml              # 元数据和运行约定
  instruction.md         # 给 Agent 的 prompt
  environment/
    Dockerfile           # work 镜像（构建上下文：任务目录）
    ...                  # 工作区文件：README、工具、初始代码
  judge/
    Dockerfile           # judge 镜像（构建上下文：任务目录）
    ...                  # 评分程序、隐藏测试、测试数据
```

`NOTES.md`、参考解等其他文件 SForge 不读取。镜像以 root 运行；Agent 由 SForge 在运行时拷入，不要装进镜像。

## task.toml

下面是 SForge 读取的字段；其他 key（例如 EdgeBench 的 `category`、`status`）是自由的元数据。

```toml
id = "ad_placement_optimization"   # 必须与目录名一致
name = "Ad Placement Optimization"
version = "1.0.0"          # 任何可能改变分数的修改都要提升版本

[environment]
base = "cpp"               # bases/<name>；Dockerfile 直接用公开镜像时省略
platform = "linux/amd64"
cwd = "/home/workspace/ad-placement"   # Agent 的工作目录
internet = false           # work 容器能否访问外网
cpus = 4                   # work 容器的 CPU 和内存（可选；运行时可覆盖）
memory = "16g"

[submission]
paths = ["solution.cpp"]   # sforge-submit 提交的内容，相对 cwd（"." 表示全部）
exclude = []               # 要排除的路径前缀或文件名 glob

[judge]
cmd = "bash /judge/run.sh" # 提交解压到 cwd 后，在 cwd 中运行
timeout_sec = 600
internet = false           # 默认：judge 容器没有网络
cpus = 4                   # judge 容器的 CPU 和内存，同 work 容器
memory = "16g"

[score]
direction = "maximize"     # maximize | minimize
rescale = { kind = "piecewise_max", baseline = 0.0, rank30 = 47169682940.0, rank1 = 49702568341.0, super_anchor = 50000000000.0 }

[[blobs]]                  # 只用于放在 git 之外的数据
path = "judge/blobs/hidden.tar.gz"
sha256 = "..."

[game]                     # 只用于游戏类任务
server_cmd = "..."
```

`rescale` 把原始分映射到 0–100。可用的 kind 包括 `linear`、`log_max`、`log_min`、`log_anchor`、`piecewise_max`、`piecewise_min` 和 `piecewise_log_min`，参数见 `sforge/harness/score_rescale.py`。

## 评分约定

- SForge 在一个全新的 judge 容器中把过滤后的提交解压到 `cwd`，然后在那里运行 `[judge] cmd`。
- 评分程序**必须**写出 `/opt/sforge/result.json`：

  ```json
  {"score": 43623268300.0, "valid": true, "summary": "50/50 cases ok",
   "details": [{"name": "case_0000", "status": "PASSED", "score": 1.0}],
   "metrics": {}}
  ```

  `score` 是原始分，`valid` 为 true 时必须给出。`valid: false` 表示拒绝这次提交。`summary`、`details` 和 `metrics` 只作为反馈。
- stdout 和 stderr 只是日志，SForge 不解析。
- judge 容器通过 `SFORGE_CPUS` 和 `SFORGE_MEMORY` 得到自己的资源限制（work 容器同样有自己的一份）。并发数请按 `SFORGE_CPUS` 设置：在 CPU 配额下，`nproc` 和 `os.cpu_count()` 看到的是宿主机的核数。
- 没有 `result.json`、分数不是数字或 judge 超时，这次提交都无效。编译失败或空提交，只要评分程序能给出分数，就应当是有效分（通常为 0）。
- 一次运行的最终结果是所有有效提交中按 `direction` 最好的 `score`。

## 镜像与 base

镜像 tag 是 SForge 计算的内容哈希，前缀是 benchmark 的 `name`：

| 镜像 | tag 哈希的内容 |
|------|----------------|
| `<name>.base.<base>:<hash>` | `bases/<base>/` |
| `<name>.work.<id>:<hash>` | `environment/` 和 base 的 tag |
| `<name>.judge.<id>:<hash>` | `environment/`、`judge/` 和 base 的 tag |

Blob 按声明的 sha256 计入哈希。修改 `task.toml` 或 `instruction.md` 不会触发镜像重建。使用 base 的任务 Dockerfile 以 `ARG BASE_IMAGE` / `FROM ${BASE_IMAGE}` 开头；`sforge build` 会先构建 base 并传入它的 tag。

## Blob

放不进 git 的大数据打成 blob：在 `[[blobs]]` 里列出 tar 包及其 sha256，文件放在任务目录中被 gitignore 的路径下，由 Dockerfile `ADD`。构建前，`sforge build` 会校验每个 blob，缺失的从 `$SFORGE_BLOB_URL/<sha256>` 下载，没有设置时用 benchmark 的 `blob_url`。`file://` 地址可以指向本地副本。

## 修改或新增任务

```bash
# 1. 修改 edgebench/tasks/<task_id>/（可能改变分数时提升 version）

# 2. 构建：base、work 和 judge 镜像，并下载所需的 blob
sforge build --task <task_id>

# 3. 用新的 judge 给一个提交包评分
tar -czf sub.tar.gz -C <workspace> .
sforge eval --task <task_id> --archive sub.tar.gz

# 4. 可选：让 Agent 实际跑一遍
sforge run --task <task_id> --agent claude-code --timeout 3600
```

`tools/judge_local.py` 可以绕过 judge server，直接用 judge 镜像给一个 archive 评分，并输出一行 JSON 结果。

EdgeBench 题目问题的报告和修复流程见 [CONTRIBUTING.md](https://github.com/ByteDance-Seed/EdgeBench/blob/main/CONTRIBUTING.md#fixing-an-edgebench-task)，出题规则见 [`edgebench/tasks/SCHEMA.md`](https://github.com/ByteDance-Seed/EdgeBench/blob/main/edgebench/tasks/SCHEMA.md)。CI 会构建改动的镜像，合并后发布到 Docker Hub（见[预构建镜像](/zh/features/prebuilt-images)）。
