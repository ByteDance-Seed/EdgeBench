---
title: Judge HTTP API
---

# Judge HTTP API

The judge server exposes a REST API for registering runs, submitting archives, polling results, forwarding model requests and managing game sessions. It runs inside `sforge run` by default, or standalone with `sforge serve --port 8080`. All endpoints are under `/api/v1`.

## Who Calls What

| Caller | Credential | Endpoints |
|--------|------------|-----------|
| `sforge run` (host) | admin secret | `register`, auto-eval `submit`, full `history`, `usage` |
| Agent in the work container | session token | `submit`, `result`, agent `history`, `llm/...`, game endpoints |

The admin secret (`SFORGE_ADMIN_SECRET`) never enters a container. The work container gets only its session token (`SFORGE_TOKEN`) and the judge URL (`SFORGE_JUDGE_URL`).

## Session Registration

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

Optional fields: `judge_cpu_limit`, `judge_mem_limit`, `max_agent_submissions`, `submission_cooldown`, and backend settings (`backend`, `k8s_*`, `e2b_*`) so the judge creates its containers on the same backend as the run.

**Response:**

```json
{"token": "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4"}
```

The token identifies the task and run and counts agent rounds (`agent-1`, `agent-2`, ...) and auto-eval rounds (`auto-1`, ...) separately.

## Submit Archive

```http
POST /api/v1/submit
Content-Type: multipart/form-data

token: <token>
archive: @solution.tar.gz
kind: agent
```

| Field | Required | Description |
|-------|----------|-------------|
| `token` | yes | Session token |
| `archive` | yes | `.tar.gz` of the workspace; filtered by the task's submission paths |
| `kind` | no | `agent` (default) or `auto`; `auto` also needs `admin_secret` |
| `admin_secret` | for `auto` | Admin secret |

**Response:**

```json
{
  "submission_id": "a1b2c3d4e5f6",
  "round_id": "agent-1",
  "status": "queued",
  "remaining_submissions": 9
}
```

`remaining_submissions` is set when the run has `max_agent_submissions`. Over the limit, or within the cooldown, the server answers `429` with the reason. Grading is asynchronous: poll the result.

## Get Result

```http
GET /api/v1/result/{submission_id}
```

**Response (completed):**

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

The report is the grader's `result.json` plus timing. The 0–100 score is not included: agents only see raw scores.

| Status | Description |
|--------|-------------|
| `queued` | Received, waiting for a judge container |
| `running` | The grader is running |
| `completed` | Graded; `report` is available (it may still be `valid: false`) |
| `error` | Grading failed outright; see `error` |

## Run History

```http
GET /api/v1/history?token=<token>
```

**Response (agent view):**

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

Without the admin secret, the history holds only agent submissions and no 0–100 scores. With `admin_secret=<secret>` it also includes auto-eval rounds and `score_0_100`. The best entry is the best valid `score` in the task's direction.

## Token Usage

```http
GET /api/v1/usage?token=<token>&admin_secret=<secret>
```

Totals the LLM gateway recorded for the run: requests and tokens (input, cache read, cache write, output, reasoning), overall and by model. `sforge run` stores them in `final_result.json` as `usage`.

## LLM Gateway

```http
ANY /api/v1/llm/{token}/{path}
```

The agent's API base URL points here; `{path}` is the upstream API path (`v1/messages`, `responses`, `chat/completions`, ...). The judge server forwards the request to the run's `llm_base_url`, replaces the placeholder key the container holds with the real key, streams the response back, and appends the usage of each request to `logs/runs/<run>/<task>/llm_requests.jsonl`. Anthropic Messages, OpenAI Responses and Chat Completions usage formats are understood. Outbound requests honour the host's `SFORGE_HTTPS_PROXY` / `SFORGE_NO_PROXY`.

## Game Endpoints

For game tasks the judge server runs each session in its own game container.

| Method | Endpoint | Body / Response |
|--------|----------|-----------------|
| `POST` | `/api/v1/game/{run_id}/{task_id}/new` | `{}` → session with the first observation |
| `POST` | `/api/v1/game/{run_id}/{task_id}/{session_id}/step` | `{"action": "go north"}` → next observation |
| `GET` | `/api/v1/game/{run_id}/{task_id}/{session_id}/status` | → score, peak, moves, done |
| `POST` | `/api/v1/game/{run_id}/{task_id}/{session_id}/close` | → `final_score`, `peak_score`, `max_score`, `moves` |
| `POST` | `/api/v1/game/{run_id}/{task_id}/close-all` | → `{"closed": n}` |

Session responses look like:

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

See [Game Mode](/en/features/game-mode) for limits.

## curl Example

Against a standalone `sforge serve` on the same machine (which keeps its admin secret in `logs/.judge-admin-secret`):

```bash
SECRET=$(cat logs/.judge-admin-secret)

# 1. Register a session
TOKEN=$(curl -s -X POST http://localhost:8080/api/v1/register \
  -H 'Content-Type: application/json' \
  -d "{\"task_id\": \"ad_placement_optimization\", \"run_id\": \"manual-001\", \"admin_secret\": \"$SECRET\"}" \
  | jq -r .token)

# 2. Submit an archive
SUBMISSION_ID=$(curl -s -X POST http://localhost:8080/api/v1/submit \
  -F token=$TOKEN -F archive=@solution.tar.gz | jq -r .submission_id)

# 3. Poll until done
while true; do
  STATUS=$(curl -s http://localhost:8080/api/v1/result/$SUBMISSION_ID | jq -r .status)
  if [ "$STATUS" = "completed" ] || [ "$STATUS" = "error" ]; then
    curl -s http://localhost:8080/api/v1/result/$SUBMISSION_ID | jq .
    break
  fi
  sleep 5
done

# 4. Run history
curl -s "http://localhost:8080/api/v1/history?token=$TOKEN" | jq .
```

For grading a single archive, `sforge eval` is simpler.
