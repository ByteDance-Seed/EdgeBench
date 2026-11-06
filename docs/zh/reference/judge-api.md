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

Admin secret（`SFORGE_ADMIN_SECRET`）从不进入容器。Work 容器只拿到自己的 session token（`SFORGE_TOKEN`）和 judge URL（`SFORGE_JUDGE_URL`）。

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
{"token": "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4"}
```

Token 标识任务和运行，并分别计数 Agent 轮次（`agent-1`、`agent-2`、...）和 auto-eval 轮次（`auto-1`、...）。

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
