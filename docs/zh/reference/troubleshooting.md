---
title: 故障排除
---

# 故障排除

## 镜像

| 现象 | 原因 | 处理方式 |
|------|------|----------|
| `Image '...' not found. Run sforge pull ... or sforge build ...` | 本地 Docker 中没有该题的镜像 | `sforge pull --task <id>` 或 `sforge build --task <id>` |
| `sforge pull` 显示 `FAIL` | 该 tag 尚未发布（改过的任务，或 CI 还没发布）、访问不到 Docker Hub，或匿名拉取触发了 Docker Hub 限流（`toomanyrequests`） | 用 `sforge build` 本地构建；限流时先 `docker login`；网络问题见[网络配置](/zh/configuration/network-setup) |
| `blob ...: cannot download ...` | `SFORGE_BLOB_URL` 处访问不到该 blob | 检查对 GitHub Release 资源的访问，或把 `SFORGE_BLOB_URL` 指向本地 `file://` 副本 |
| `blob ...: downloaded sha256 ... != ...` | 拿到的文件不是声明的 blob | 去掉镜像源或修正副本；不要改 sha256 去迁就 |
| `docker build exited 1` | 某个构建步骤失败 | 查看构建日志（见下） |

### 构建日志

每个镜像的构建日志写在 `logs/build_images/<镜像>_<tag>.log`，例如 `logs/build_images/ad_placement_optimization-judge_1c6838c6d7fd.log`。终端里的报错常被截断，日志里有完整的 Docker 输出。

### 强制重建

Tag 是内容哈希，修改任务本身就会精确重建受影响的镜像。要重建一个 tag 已存在的镜像（例如之前构建出了问题），使用：

```bash
sforge build --task ad_placement_optimization --force-rebuild            # work + judge
sforge build --task ad_placement_optimization --force-rebuild-with-base  # 连同 base
```

## Agent 问题

### 构建 Agent bundle 失败

首次使用某个 Agent 版本时，SForge 在宿主机上构建它的 bundle（Node.js 加 npm 包），放在 `~/.cache/sforge/agents`。下载失败时，设置 `SFORGE_NODEJS_MIRROR_URL` 和/或 `npm_config_registry`，或设置代理。构建 bundle 需要 Linux x86_64 宿主机。

### Agent 访问不到模型

Agent 访问的是 judge server 的 LLM 网关，由网关转发到真实 API。按顺序检查：

1. 运行 `sforge run` 的机器上的 `SFORGE_AGENT_API_KEY` 和 `SFORGE_AGENT_API_BASE_URL`。
2. `logs/runs/<run>/<task>/llm_requests.jsonl`：每个请求一行，含上游状态码。
3. 宿主机访问 API 是否需要代理（`SFORGE_HTTPS_PROXY`）。

### Agent 卡住或没有进展

```bash
# 完整输出
cat logs/runs/<run_id>/<task_id>/agent_output.txt

# 只看 assistant 文本（Claude Code stream-json）
jq -r 'select(.type == "assistant") | .message.content[] | select(.type == "text") | .text' \
  logs/runs/<run_id>/<task_id>/agent_output.txt

# 或在 Claude Code / Codex 里打开会话
sforge replay --run-id <run_id> --task <task_id>
```

### Agent 过早退出

`claude-code` 和 `codex` 默认启用 stop hook；不要传 `--disable-stop-hook`。异常退出会被自动恢复重新拉起，除非 Agent 在一秒内退出（视为系统性故障）或已恢复 100 次；见 `run_agent.log`。

### Kubernetes 和 E2B

| 现象 | 原因 | 处理方式 |
|------|------|----------|
| Pod 一直 `Pending` 或拉不到镜像 | 调度、节点选择器或 registry 访问问题 | `kubectl -n <namespace> describe pod <pod>` |
| Kubernetes 上隔离的任务能访问外网 | CNI 不执行 NetworkPolicy | 换用执行 NetworkPolicy 的 CNI |
| `sforge-submit` 连不上 | Sandbox 访问不到 `--judge-advertise` / `--judge-url` | 使用 Pod 或 Sandbox 能访问到的地址和开放端口 |
| E2B：找不到 Template | 该任务版本没有 Template | 构建 Template（见 [E2B 示例](/zh/examples/single-task-e2b)），或设置 `SFORGE_E2B_TEMPLATE_NAMESPACE` / `SFORGE_E2B_TEMPLATE_MAP` |
| E2B：运行快结束时报 `Sandbox not found` | 达到了套餐允许的最长 Sandbox 生命周期 | 缩短 `--timeout` |

### 没有提交记录

1. 在 `agent_output.txt` 中查找 `sforge-submit` 调用及其输出。
2. 确认 sandbox 能访问 judge（k8s 和 E2B 上的 `--judge-advertise` / `--judge-url`）。
3. 使用了 `--disable-auto-eval` 且 Agent 从未提交时，不会有任何提交记录。

### 每次提交都无效

查看某次提交的 `submissions/<round>/judge_output.txt` 和 `result.json`。常见原因：评分程序找不到要评的内容（检查该题的 `[submission] paths`）、judge 超时，或 LLM 评分任务缺少凭据（`SFORGE_JUDGE_EXTRA_ENV`）。

## 容器清理

`sforge run` 退出时会删除自己的容器，包括 Ctrl+C 和 `SIGTERM`。遇到 `SIGKILL` 或崩溃时，可能残留运行中的容器：

```bash
docker ps --filter "name=sforge"
docker ps --filter "name=sforge" -q | xargs -r docker stop
docker ps --filter "name=sforge" -aq | xargs -r docker rm
```

隔离的 Docker 运行留下的 iptables 链会在下一次 `sforge run` 时清理；手动清理见[单任务运行 (Docker)](/zh/examples/single-task-docker#网络隔离)。

## FAQ

**问：什么时候会重建镜像？**
答：构成镜像的文件变化时：base 对应 `bases/<name>/`，work 镜像对应 `environment/`，judge 镜像对应 `environment/` 和 `judge/`。修改 `instruction.md`、`task.toml` 或 `NOTES.md` 不会重建任何镜像。

**问：修改 `instruction.md` 需要重建吗？**
答：不需要。Prompt 在运行时发送，不打进镜像。

**问：可以并行运行多道题吗？**
答：可以，传多个任务 ID 或使用实验配置。一次 `sforge run` 的所有任务共用它的 judge server。Docker 上每台机器只跑少量任务。

**问：如何比较多次运行的结果？**
答：用 `sforge viewer`，或查看每道题的 `final_result.json`。

**问：Agent 在运行但终端没有输出。**
答：多任务运行时终端不输出详情；请查看 `logs/runs/<run_id>/<task_id>/` 下的文件（见[运行输出](/zh/reference/cli#运行输出)）。

**问：judge 超时和 `--timeout` 有什么区别？**
答：`task.toml` 中的 `[judge] timeout_sec` 限制单次评分；`--timeout` 是 Agent 的总时间预算。
