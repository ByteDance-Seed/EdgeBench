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

### 封存并接续原生评测注册（显式开启）

使用 `sforge serve --checkpoints --port 8080` 开启以下控制器接口；默认关闭时接口返回 404，也不创建 checkpoint 库。停用时去掉此开关重启，保留私有库及接续运行的占用标记供检查；独立实验使用新的 run ID。

所有 checkpoint 接口都要求 JSON 正文中的当前评测控制器 `admin_secret`。Agent 的提交 token 只能标识捕获来源，不能授权捕获或恢复。迁往另一控制器时，只把获授权的 `logs/checkpoints/` 库转入其自身日志目录，使用新控制器独立生成的管理密钥；不要复制原管理密钥文件或会话 token。

- `POST /api/v1/checkpoint/capture`：正文包含 `token`、`admin_secret`，可选 `capture_id`（调用者生成的 32 位十六进制操作 ID）。同一注册重试同一 ID 返回首次捕获的点，不采用后来的提交，也不重复保存；其他注册不能复用。省略该字段表示新的手动捕获。响应包含 `checkpoint_id`、`manifest_sha256`、题目/来源 run、已用轮次/剩余冷却，以及原生选优的 incumbent 轮次、大小和摘要。私有 capsule 保留已公开的 agent 历史、完整结果及被选中的归档，不包含提交或管理 token。归档按原始字节保留，不解包。
- `POST /api/v1/checkpoint/restore`：正文包含 `checkpoint_id`、捕获响应中的 `manifest_sha256`、全新的 `run_id` 和当前 `admin_secret`。响应返回新的提交 token。通过原有 `/api/v1/history?token=...` 和 `/api/v1/result/{submission_id}` 读回。历史结果使用新的查询 ID，原报告保持不变；`logs/runs/新run/checkpoint-origin.json` 保存来源映射，incumbent 保留原轮次。

恢复不会评测或多消费一轮。后续提交仍由原生 `consume_round`、预算、冷却及选优规则决定。冷却在新注册发布时，从捕获时剩余的**时长**重新计时；离线等待和 capsule 物化既不会补发机会，也不会消耗这段时长；旧 capsule 不包含来源后来取得的提升。

若恢复响应丢失，用**相同**的正文（`checkpoint_id`、`manifest_sha256`、`run_id` 及当前 `admin_secret`）调用 `POST /api/v1/checkpoint/restore-result`。响应结构与首次恢复相同，返回已发布的原提交 token；不创建注册、不重放评测、不重置冷却。后续提交发生后仍可读回，已用机会保持不变。来源标记必须匹配且原注册仍存活；缺失、错配、部分激活或已丢失的注册返回 409，管理授权错误返回 403，非法正文返回 422。评测进程重启后，仅凭磁盘来源标记不能重新生成凭证。此操作不恢复 runner 的阶段截止时间：控制器必须保存首次激活时的原截止时间，重试不能重新计一段预算。更换 `run_id` 是另一个分支，不是恢复原响应。

当前版本支持配置的 Docker backend 上已结算的非 game 注册，不支持自动评测历史。绑定原生 Python 源码、完整题目规格、实际 Docker 评测镜像 ID、选优策略/方向及有效 CPU/内存限制。字节缺失或变化、来源/评测不符、未完成结果、已消费却无公开历史的轮次、结果/历史冲突及不支持的配置返回 409；管理授权错误返回 403，非法正文返回 422。已有 run、重复恢复和中断留下的目标占用会拒绝，不会重置预算。完成前的异常回滚可重试；进程崩溃遗留的占用需要控制器检查。开启期间，已恢复 run ID 也不能再次冷注册，且整个 run ID 均被占用。

库是受信任的控制器私有状态；SHA-256 只能核对捕获引用，不能防止恶意管理员修改，也不能证明任意报告不含敏感内容。此接口不是完整 worker checkpoint：除 incumbent 外的工作代码、模型会话、研究状态、外部副作用权限及 runner 剩余总预算须由其各自 owner 保留，之后才能判断分支是否可比。停用后不要把已恢复 run 重新冷注册。

另有两个默认路径一致性修复：backend 准备失败时不发布 token/资源行；评测失败的历史改为 `status="error"`，与 `/result` 一致。成功冷注册的默认值、轮次分配及评分/选优规则不变。

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
