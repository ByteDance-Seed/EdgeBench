---
title: Judge HTTP API
---

# Judge HTTP API

Judge 服务器提供 REST API，用于提交代码归档、轮询评测结果、以及管理交互式游戏会话。通过 `sforge serve --port 8080` 启动。

## 基础 URL

```
http://localhost:8080
```

所有端点均以 `/api/v1` 为前缀。

## 认证机制

Judge API 使用**基于 Token 的会话模型**。在提交之前，客户端必须先注册会话以获取 Token。Token 编码了任务 ID、运行 ID 和自增的轮次计数器。

## 接口列表

### 任务发现

列出从 `tasks/` 目录加载的所有可用任务。

```http
GET /api/v1/tasks
```

**响应：**

```json
[
  {"task_id": "ad_placement_optimization", "name": "Ad Placement Optimization"},
  {"task_id": "gitlet", "name": "Gitlet"},
  {"task_id": "tinykv", "name": "TinyKV"}
]
```

### 会话注册

注册新会话并获取 Token，用于后续提交。

```http
POST /api/v1/register
Content-Type: application/json

{
  "task_id": "ad_placement_optimization",
  "run_id": "run-001"
}
```

**响应：**

```json
{
  "token": "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4"
}
```

Token 是一个 32 字符的十六进制字符串，内部维护任务 ID、运行 ID 以及两个独立的计数器：Agent 提交（`agent-1`、`agent-2`、...）和自动评测提交（`auto-1`、`auto-2`、...）。

### 提交归档

提交代码归档进行评测。服务器从 Token 中解析任务 ID 和运行 ID，并分配递增的轮次 ID。

```http
POST /api/v1/submit
Content-Type: multipart/form-data

token: a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4
archive: @solution.tar.gz
kind: agent
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `token` | string | 是 | 从 `/register` 获取的会话 Token |
| `archive` | file | 是 | `.tar.gz` 格式的解决方案归档 |
| `kind` | string | 否 | `"agent"`（默认）或 `"auto"`。决定递增哪个轮次计数器。 |

**响应：**

```json
{
  "submission_id": "a1b2c3d4e5f6",
  "round_id": "agent-1",
  "status": "queued"
}
```

提交异步处理——服务器立即返回 `status: "queued"`。通过 result 接口轮询结果。

### 获取结果

轮询提交的评测结果。

```http
GET /api/v1/result/{submission_id}
```

**响应（排队中/运行中）：**

```json
{
  "submission_id": "a1b2c3d4e5f6",
  "status": "running",
  "report": null,
  "error": null
}
```

**响应（已完成）：**

```json
{
  "submission_id": "a1b2c3d4e5f6",
  "status": "completed",
  "report": {
    "total_tests": 50,
    "passed": 45,
    "failed": 5,
    "errors": 0,
    "pass_rate": 0.9,
    "score": null,
    "valid": true,
    "summary": "45/50 tests passed. Failed: test_forward, test_backward, ...",
    "test_details": [...]
  },
  "error": null
}
```

**响应（错误）：**

```json
{
  "submission_id": "a1b2c3d4e5f6",
  "status": "error",
  "report": null,
  "error": "Container exited with code 137 (OOM killed)"
}
```

**状态值：**

| 状态 | 说明 |
|------|------|
| `queued` | 已接收提交，等待处理 |
| `running` | Judge 容器正在运行测试 |
| `completed` | 评测完成，报告可用 |
| `error` | 评测失败（容器崩溃、超时等） |

### 运行历史

获取某次运行会话的完整提交历史，包括最佳分数的选定结果。

**通过 Token 查询：**

```http
GET /api/v1/history?token=<token>
```

**通过运行 ID 查询：**

```http
GET /api/v1/runs/{run_id}/history?task_id=<task_id>
```

**响应：**

```json
{
  "run_id": "run-001",
  "best_pass_rate": 0.95,
  "best_score": null,
  "best_round": "agent-3",
  "agent_submissions": 4,
  "auto_submissions": 2,
  "entries": [
    {
      "type": "submission",
      "status": "completed",
      "submission_id": "abc123",
      "task_id": "ad_placement_optimization",
      "round": "agent-1",
      "pass_rate": 0.8,
      "score": null,
      "passed": 40,
      "failed": 10,
      "total_tests": 50,
      "valid": true,
      "summary": "40/50 tests passed. Failed: ..."
    }
  ]
}
```

`best_*` 字段根据任务配置的选择策略计算（参见[Benchmark 与任务接入](/zh/tasks/integration-guide#选择策略)）。

### 游戏接口

对于 `game_mode: true` 的任务，Judge 服务器在专用容器中管理交互式游戏会话。

#### 创建新游戏

```http
POST /api/v1/game/{run_id}/{task_id}/new
Content-Type: application/json
{}
```

**响应：**

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

#### 执行动作

```http
POST /api/v1/game/{run_id}/{task_id}/{session_id}/step
Content-Type: application/json

{"action": "go north"}
```

**响应：**

```json
{
  "session_id": "abc123def456",
  "observation": "You enter a dimly lit hallway...",
  "score": 10,
  "peak_score": 10,
  "max_score": 100,
  "done": false,
  "moves": 1
}
```

#### 查询状态

```http
GET /api/v1/game/{run_id}/{task_id}/{session_id}/status
```

**响应：**

```json
{
  "session_id": "abc123def456",
  "score": 10,
  "peak_score": 10,
  "max_score": 100,
  "done": false,
  "moves": 1
}
```

#### 关闭会话

```http
POST /api/v1/game/{run_id}/{task_id}/{session_id}/close
```

**响应：**

```json
{
  "session_id": "abc123def456",
  "final_score": 25,
  "peak_score": 30,
  "max_score": 100,
  "moves": 15
}
```

#### 关闭所有会话

关闭指定运行和任务的所有活跃游戏会话。

```http
POST /api/v1/game/{run_id}/{task_id}/close-all
```

**响应：**

```json
{"closed": 3}
```

游戏会话有 10 分钟的空闲超时。当游戏结束（`done: true`）或被显式关闭时，会话会自动归档。系统最多支持 200 个并发游戏会话。

## curl 示例

### 注册、提交和轮询

```bash
# 1. 注册会话
TOKEN=$(curl -s -X POST http://localhost:8080/api/v1/register \
  -H "Content-Type: application/json" \
  -d '{"task_id": "ad_placement_optimization", "run_id": "run-001"}' \
  | jq -r '.token')

echo "Token: $TOKEN"

# 2. 提交归档
SUBMISSION_ID=$(curl -s -X POST http://localhost:8080/api/v1/submit \
  -F "token=$TOKEN" \
  -F "archive=@solution.tar.gz" \
  -F "kind=agent" \
  | jq -r '.submission_id')

echo "Submission: $SUBMISSION_ID"

# 3. 轮询结果（重复直到 status 为 "completed" 或 "error"）
curl -s http://localhost:8080/api/v1/result/$SUBMISSION_ID | jq .

# 4. 查看运行历史
curl -s "http://localhost:8080/api/v1/history?token=$TOKEN" | jq .
```

### 轮询循环

```bash
while true; do
  STATUS=$(curl -s http://localhost:8080/api/v1/result/$SUBMISSION_ID | jq -r '.status')
  echo "Status: $STATUS"
  if [ "$STATUS" = "completed" ] || [ "$STATUS" = "error" ]; then
    curl -s http://localhost:8080/api/v1/result/$SUBMISSION_ID | jq .
    break
  fi
  sleep 5
done
```
