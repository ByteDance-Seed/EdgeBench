---
title: Game Mode
---

# Game Mode

In game tasks the agent plays an interactive text adventure over HTTP instead of submitting code. The score is the game's own score.

## How It Works

- The task's `task.toml` has a `[game]` section whose `server_cmd` starts the game server in the judge image.
- For each game session the judge server starts a dedicated game container and relays the agent's actions to it.
- The agent can open many sessions to explore different strategies; the best session score is the result.
- The work container gets `GAME_SERVER_URL`, the base URL of the game endpoints for its run.

## Game API

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/v1/game/{run_id}/{task_id}/new` | Start a new session |
| `POST` | `/api/v1/game/{run_id}/{task_id}/{sid}/step` | Take an action (`{"action": "..."}`) |
| `GET` | `/api/v1/game/{run_id}/{task_id}/{sid}/status` | Check session status |
| `POST` | `/api/v1/game/{run_id}/{task_id}/{sid}/close` | End a session |
| `POST` | `/api/v1/game/{run_id}/{task_id}/close-all` | End all sessions of a run |

## Response Format

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

## Game Tasks

| Task | Game |
|------|------|
| `anchorhead_text_adventure` | Anchorhead (Z-machine, via Jericho) |
| `trinity_text_adventure` | Trinity |
| `tryst_text_adventure` | Tryst of Fate |

## Session Management

- Sessions close automatically after **10 minutes** idle
- At most **200** concurrent sessions per judge server, and **3** per run and task: starting a fourth closes the oldest
- Each session's steps are logged under `logs/runs/<run>/<task>/submissions/game-<n>/`
