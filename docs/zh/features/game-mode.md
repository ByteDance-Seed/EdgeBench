---
title: 游戏模式
---

# 游戏模式

在游戏任务中，Agent 通过 HTTP 玩一个交互式文字冒险游戏，而不是提交代码。分数就是游戏自己的分数。

## 工作原理

- 任务的 `task.toml` 有 `[game]` 段，其中 `server_cmd` 在 judge 镜像里启动游戏服务器。
- 每个游戏会话由 judge server 启动一个专用的游戏容器，并把 Agent 的动作转发给它。
- Agent 可以开多个会话尝试不同策略；取最好的会话分数作为结果。
- Work 容器会得到 `GAME_SERVER_URL`，即本次运行的游戏接口基础 URL。

## 游戏 API

| 方法 | 端点 | 说明 |
|------|------|------|
| `POST` | `/api/v1/game/{run_id}/{task_id}/new` | 开始新会话 |
| `POST` | `/api/v1/game/{run_id}/{task_id}/{sid}/step` | 执行动作（`{"action": "..."}`） |
| `GET` | `/api/v1/game/{run_id}/{task_id}/{sid}/status` | 查询会话状态 |
| `POST` | `/api/v1/game/{run_id}/{task_id}/{sid}/close` | 结束会话 |
| `POST` | `/api/v1/game/{run_id}/{task_id}/close-all` | 结束本次运行的所有会话 |

## 响应格式

```json
{
  "session_id": "...",
  "observation": "You are in a dark room...",
  "score": 10,
  "peak_score": 15,
  "max_score": 350,
  "done": false,
  "moves": 5
}
```

## 游戏任务

| 任务 | 游戏 |
|------|------|
| `anchorhead_text_adventure` | Anchorhead（Z-machine，通过 Jericho） |
| `trinity_text_adventure` | Trinity |
| `tryst_text_adventure` | Tryst of Fate |

## 会话管理

- 空闲 **10 分钟**后会话自动关闭
- 每个 judge server 最多 **200** 个并发会话，每个运行的每道题最多 **3** 个：开第 4 个时会关闭最早的一个
- 每个会话的步骤记录在 `logs/runs/<run>/<task>/submissions/game-<n>/`
