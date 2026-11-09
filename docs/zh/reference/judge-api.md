---
title: Judge HTTP API
---

# Judge HTTP API

Judge server 提供 REST API，用于登记运行、提交 archive、轮询结果、转发模型请求和管理游戏会话。默认运行在 `sforge run` 内部，也可以用 `sforge serve --port 8080` 单独启动。所有端点都在 `/api/v1` 下。

## 谁调用什么

| 调用方 | 凭据 | 端点 |
|--------|------|------|
| `sforge run`（宿主机） | admin secret | `register`、auto-eval 的 `submit`、完整 `history`、`usage` |
| work 容器里的 Agent | session token | `submit`、`result`、Agent 视角的 `history`、`llm/...`、游戏端点 |
| 反馈读取方 | feedback relay ID | 只读登记 `context` 与该登记的 Agent `result` |

Admin secret（`SFORGE_ADMIN_SECRET`）从不进入容器。Work 容器拿到自己的 session token（`SFORGE_TOKEN`）、judge URL（`SFORGE_JUDGE_URL`）和只读反馈 URL（`SFORGE_FEEDBACK_URL`）。反馈 URL 是读取反馈的凭据，不能用于提交、读取 auto-eval 或访问其他 run/task。已记录登记绑定的结果进一步限定在该登记内。

## 登记会话

```http
POST /api/v1/register
Content-Type: application/json

{
  "task_id": "ad_placement_optimization",
  "run_id": "run-001",
  "admin_secret": "<secret>",
  "llm_base_url": "https://api.anthropic.com",
  "llm_api_key": "sk-ant-..."
}
```

可选字段：`judge_cpu_limit`、`judge_mem_limit`、`max_agent_submissions`、`submission_cooldown`，以及 backend 设置（`backend`、`k8s_*`、`e2b_*`），让 judge 在与运行相同的 backend 上创建容器。

**响应：**

```json
{
  "token": "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4",
  "feedback_relay_id": "<opaque-read-capability>",
  "evaluation_context": {
    "schema_version": "sforge_run_evaluation_context_v1",
    "task_id": "ad_placement_optimization",
    "run_id": "run-001",
    "registration_id": "<server-assigned-id>",
    "evaluation_conditions": null
  }
}
```

Token 标识任务和运行，并分别计数 Agent 轮次（`agent-1`、`agent-2`、...）和 auto-eval 轮次（`auto-1`、...）。

评测条件已知时，同一 run/task 在条件和登记选项完全相同时返回原 token、relay 与计数器；条件或选项变化返回 `409`，需要新的 `run_id`。重试不能重置提交预算或切换运行的模型网关。条件未知的登记保留原有登记行为，不声明归因已验证。

## 提交 Archive

```http
POST /api/v1/submit
Content-Type: multipart/form-data

token: <token>
archive: @solution.tar.gz
kind: agent
```

| 字段 | 必填 | 说明 |
|------|------|------|
| `token` | 是 | Session token |
| `archive` | 是 | 工作区的 `.tar.gz`，按该题的提交路径过滤 |
| `kind` | 否 | `agent`（默认）或 `auto`；`auto` 还需要 `admin_secret` |
| `admin_secret` | `auto` 时 | Admin secret |
| `include_receipt` | 否 | `true` 附带已接受归档的 receipt；默认 `false` 保留原响应 |

**响应：**

```json
{
  "submission_id": "a1b2c3d4e5f6",
  "round_id": "agent-1",
  "status": "queued",
  "remaining_submissions": 9
}
```

运行设置了 `max_agent_submissions` 时才有 `remaining_submissions`。超过次数或处于冷却期时，服务器返回 `429` 并说明原因。评分是异步的：需要轮询结果。

## 获取结果

```http
GET /api/v1/result/{submission_id}
```

**响应（已完成）：**

```json
{
  "submission_id": "a1b2c3d4e5f6",
  "status": "completed",
  "report": {
    "task_id": "ad_placement_optimization",
    "submission_id": "a1b2c3d4e5f6",
    "score": 43623268300.0,
    "valid": true,
    "summary": "50/50 cases ok",
    "details": [{"name": "case_0000", "status": "PASSED", "score": 1.0}],
    "metrics": {},
    "timed_out": false,
    "runtime_seconds": 41.2,
    "submitted_at": 1761600000.0,
    "error": null
  },
  "error": null
}
```

报告就是评分程序的 `result.json` 加上计时信息。不包含 0–100 分数：Agent 只看到原始分数。

| 状态 | 说明 |
|------|------|
| `queued` | 已收到，等待 judge 容器 |
| `running` | 评分程序正在运行 |
| `completed` | 评分完成，`report` 可用（仍可能是 `valid: false`） |
| `error` | 评分直接失败，见 `error` |

## 评测条件与只读反馈

接受测量前，先读取一次原登记上下文：

```http
GET /api/v1/feedback/{feedback_relay_id}/context
```

响应与登记返回的 `sforge_run_evaluation_context_v1` 对象相同。条件可用时，`evaluation_conditions` 对象恰好包含以下字段：

| 字段 | 含义 |
|------|------|
| `schema_version` | `sforge_evaluation_conditions_v1` |
| `task_sha256` | Task loader 实际解析的 `task.toml` 字节的 SHA-256 |
| `benchmark_sha256` | Benchmark loader 实际解析的 `benchmark.toml` 字节的 SHA-256 |
| `task_spec_sha256` | 有效逻辑任务的 SHA-256，包括指令、judge 命令、分数方向/缩放及 Blob 路径和摘要清单；不含宿主机路径 |
| `native_source_sha256` | 服务启动时一次观察的已安装 Python 框架源码清单的 SHA-256 |
| `judge_image_id` | 登记时解析、评分时实际使用的本地 Docker 内容 ID（`sha256:...`） |
| `execution_config_sha256` | 有效 judge CPU/内存/环境/网络、超时及平台的 SHA-256 |
| `score_direction` | 冻结任务的 `maximize` 或 `minimize` |
| `selection` | `valid_then_score`：已有的有效且已完成筛选、原始分数方向比较与并列取首条规则 |

服务为已接受的工作冻结已加载任务、有效配置及 backend。登记后修改文件或镜像标签，不会改变原上下文或后续提交实际使用的镜像。Blob 下载与 SHA 校验仍归原生镜像构建路径负责；Docker ID 标识镜像中实际的评测器与数据。摘要不代表评分确定性或封闭性，也不证明外部可变服务/数据未变。协议不暴露评测器内容或原始环境变量值。

一次请求读取结果原文与来源：

```http
GET /api/v1/feedback/{feedback_relay_id}/result/{submission_id}?include_receipt=true
```

响应在原结果之上增加：

```json
{
  "receipt": {
    "schema_version": "sforge_submission_receipt_v1",
    "task_id": "ad_placement_optimization",
    "round_id": "agent-1",
    "archive_sha256": "<sha256-of-accepted-upload-bytes>",
    "archive_bytes": 1234,
    "evaluation_context": {
      "schema_version": "sforge_run_evaluation_context_v1",
      "task_id": "ad_placement_optimization",
      "run_id": "run-001",
      "registration_id": "<original-server-assigned-id>",
      "evaluation_conditions": null
    }
  }
}
```

上例展示条件未知的情况；条件已知时包含表中描述的对象。归档摘要覆盖按提交路径过滤之前收到的压缩上传字节。`GET /api/v1/result/{submission_id}?include_receipt=true` 与带 `include_receipt=true` 表单字段的 `POST /api/v1/submit` 也提供同一可选 receipt。省略开关时保留原反馈正文，报告仍只含原始分数。

读取方每个结果只需一次 GET，即可将其上下文与安装时快照比较。上下文缺失、条件未知或不匹配时，测量归因必须保留未知，原生反馈仍可使用。读取 context/result 不会重扫源码、查询当前镜像、构建镜像或下载 Blob。不支持的 backend、游戏会话、未准备镜像及未经 loader 观察的手工 TaskSpec 返回 `evaluation_conditions: null`。旧结果缺少来源时返回 null 上下文/摘要，不借用当前条件。本接口不增加 checkpoint/restore 机制。

对其他 run/task/已记录登记、auto-eval 和未知 ID，relay 返回 `404`。没有登记绑定的旧结果仍只在匹配的 run/task 内可见，归因信息不会被恢复。Relay 没有提交、历史、模型网关或 admin 路由。已有 session-token API 和生成的提交客户端保持可用；保留上传归档与异步客户端选项属于独立的客户端功能。

## 运行历史

```http
GET /api/v1/history?token=<token>
```

**响应（Agent 视角）：**

```json
{
  "run_id": "run-001",
  "best_score": 43623268300.0,
  "best_round": "agent-3",
  "agent_submissions": 4,
  "auto_submissions": 0,
  "entries": [
    {
      "type": "submission",
      "status": "completed",
      "round": "agent-1",
      "score": 41200000000.0,
      "valid": true,
      "summary": "50/50 cases ok"
    }
  ]
}
```

不带 admin secret 时，历史只包含 Agent 的提交，没有 0–100 分数。带上 `admin_secret=<secret>` 时还包括 auto-eval 轮次和 `score_0_100`。最佳条目是按该题方向最好的有效 `score`。

## Token 用量

```http
GET /api/v1/usage?token=<token>&admin_secret=<secret>
```

LLM 网关为该运行记录的汇总：请求数和 token 数（input、cache read、cache write、output、reasoning），总计以及按模型拆分。`sforge run` 把它存到 `final_result.json` 的 `usage` 字段。

## LLM 网关

```http
ANY /api/v1/llm/{token}/{path}
```

Agent 的 API base URL 指向这里；`{path}` 是上游 API 路径（`v1/messages`、`responses`、`chat/completions` 等）。Judge server 把请求转发到该运行的 `llm_base_url`，把容器持有的占位 key 换成真实 key，流式返回响应，并把每个请求的用量追加到 `logs/runs/<run>/<task>/llm_requests.jsonl`。支持 Anthropic Messages、OpenAI Responses 和 Chat Completions 的用量格式。出站请求遵循宿主机的 `SFORGE_HTTPS_PROXY` / `SFORGE_NO_PROXY`。

## 游戏端点

游戏任务的每个会话由 judge server 在独立的游戏容器中运行。

| 方法 | 端点 | 请求体 / 响应 |
|------|------|---------------|
| `POST` | `/api/v1/game/{run_id}/{task_id}/new` | `{}` → 会话及第一条 observation |
| `POST` | `/api/v1/game/{run_id}/{task_id}/{session_id}/step` | `{"action": "go north"}` → 下一条 observation |
| `GET` | `/api/v1/game/{run_id}/{task_id}/{session_id}/status` | → 分数、峰值、步数、是否结束 |
| `POST` | `/api/v1/game/{run_id}/{task_id}/{session_id}/close` | → `final_score`、`peak_score`、`max_score`、`moves` |
| `POST` | `/api/v1/game/{run_id}/{task_id}/close-all` | → `{"closed": n}` |

会话响应形如：

```json
{
  "session_id": "abc123def456",
  "observation": "You are standing in a dark room...",
  "score": 0,
  "peak_score": 0,
  "max_score": 100,
  "done": false,
  "moves": 0
}
```

限制见[游戏模式](/zh/features/game-mode)。

## curl 示例

针对同一台机器上的独立 `sforge serve`（它的 admin secret 保存在 `logs/.judge-admin-secret`）：

```bash
SECRET=$(cat logs/.judge-admin-secret)

# 1. 登记会话
TOKEN=$(curl -s -X POST http://localhost:8080/api/v1/register \
  -H 'Content-Type: application/json' \
  -d "{\"task_id\": \"ad_placement_optimization\", \"run_id\": \"manual-001\", \"admin_secret\": \"$SECRET\"}" \
  | jq -r .token)

# 2. 提交 archive
SUBMISSION_ID=$(curl -s -X POST http://localhost:8080/api/v1/submit \
  -F token=$TOKEN -F archive=@solution.tar.gz | jq -r .submission_id)

# 3. 轮询直到完成
while true; do
  STATUS=$(curl -s http://localhost:8080/api/v1/result/$SUBMISSION_ID | jq -r .status)
  if [ "$STATUS" = "completed" ] || [ "$STATUS" = "error" ]; then
    curl -s http://localhost:8080/api/v1/result/$SUBMISSION_ID | jq .
    break
  fi
  sleep 5
done

# 4. 运行历史
curl -s "http://localhost:8080/api/v1/history?token=$TOKEN" | jq .
```

只给一个 archive 评分时，用 `sforge eval` 更简单。
