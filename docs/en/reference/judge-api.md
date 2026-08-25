---
title: Judge HTTP API
---

# Judge HTTP API

The Judge server exposes a REST API for submitting code archives, polling results, and managing interactive game sessions. Start it with `sforge serve --port 8080`.

## Base URL

```
http://localhost:8080
```

All endpoints are prefixed with `/api/v1`.

## Authentication

The Judge API uses a **token-based session model**. Before submitting, clients must register a session to obtain a token. The token encodes the task ID, run ID, and auto-incrementing round counters.

## Endpoints

### Task Discovery

List all available tasks loaded from the `tasks/` directory.

```http
GET /api/v1/tasks
```

**Response:**

```json
[
  {"task_id": "ad_placement_optimization", "name": "Ad Placement Optimization"},
  {"task_id": "gitlet", "name": "Gitlet"},
  {"task_id": "tinykv", "name": "TinyKV"}
]
```

### Session Registration

Register a new session and receive a token for subsequent submissions.

```http
POST /api/v1/register
Content-Type: application/json

{
  "task_id": "ad_placement_optimization",
  "run_id": "run-001"
}
```

**Response:**

```json
{
  "token": "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4"
}
```

The token is a 32-character hex string. It tracks the task, run, and separate counters for agent submissions (`agent-1`, `agent-2`, ...) and auto-eval submissions (`auto-1`, `auto-2`, ...).

### Submit Archive

Submit a code archive for evaluation. The server resolves the task ID and run ID from the token and assigns an incrementing round ID.

```http
POST /api/v1/submit
Content-Type: multipart/form-data

token: a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4
archive: @solution.tar.gz
kind: agent
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `token` | string | yes | Session token from `/register` |
| `archive` | file | yes | `.tar.gz` archive of the solution |
| `kind` | string | no | `"agent"` (default) or `"auto"`. Determines which round counter is incremented. |

**Response:**

```json
{
  "submission_id": "a1b2c3d4e5f6",
  "round_id": "agent-1",
  "status": "queued"
}
```

Submissions are processed asynchronously --- the server returns immediately with `status: "queued"`. Poll the result endpoint to check progress.

### Get Result

Poll for the result of a submission.

```http
GET /api/v1/result/{submission_id}
```

**Response (queued/running):**

```json
{
  "submission_id": "a1b2c3d4e5f6",
  "status": "running",
  "report": null,
  "error": null
}
```

**Response (completed):**

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

**Response (error):**

```json
{
  "submission_id": "a1b2c3d4e5f6",
  "status": "error",
  "report": null,
  "error": "Container exited with code 137 (OOM killed)"
}
```

**Status values:**

| Status | Description |
|--------|-------------|
| `queued` | Submission received, waiting to be processed |
| `running` | Judge container is running tests |
| `completed` | Grading finished, report is available |
| `error` | Grading failed (container crash, timeout, etc.) |

### Run History

Retrieve the full submission history for a run session, including the best score selection.

**By token:**

```http
GET /api/v1/history?token=<token>
```

**By run ID:**

```http
GET /api/v1/runs/{run_id}/history?task_id=<task_id>
```

**Response:**

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

The `best_*` fields are computed using the task's configured selection policy (see [Benchmark & Task Integration](/en/tasks/integration-guide#selection-strategies)).

### Game Endpoints

For tasks with `game_mode: true`, the Judge server manages interactive game sessions in dedicated containers.

#### Start New Game

```http
POST /api/v1/game/{run_id}/{task_id}/new
Content-Type: application/json
{}
```

**Response:**

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

#### Take Action

```http
POST /api/v1/game/{run_id}/{task_id}/{session_id}/step
Content-Type: application/json

{"action": "go north"}
```

**Response:**

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

#### Get Status

```http
GET /api/v1/game/{run_id}/{task_id}/{session_id}/status
```

**Response:**

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

#### Close Session

```http
POST /api/v1/game/{run_id}/{task_id}/{session_id}/close
```

**Response:**

```json
{
  "session_id": "abc123def456",
  "final_score": 25,
  "peak_score": 30,
  "max_score": 100,
  "moves": 15
}
```

#### Close All Sessions

Close all active game sessions for a given run and task.

```http
POST /api/v1/game/{run_id}/{task_id}/close-all
```

**Response:**

```json
{"closed": 3}
```

Game sessions have a 10-minute idle timeout. Sessions are automatically archived when the game ends (`done: true`) or when they are explicitly closed. A maximum of 200 concurrent game sessions is enforced.

## curl Examples

### Register, submit, and poll

```bash
# 1. Register a session
TOKEN=$(curl -s -X POST http://localhost:8080/api/v1/register \
  -H "Content-Type: application/json" \
  -d '{"task_id": "ad_placement_optimization", "run_id": "run-001"}' \
  | jq -r '.token')

echo "Token: $TOKEN"

# 2. Submit an archive
SUBMISSION_ID=$(curl -s -X POST http://localhost:8080/api/v1/submit \
  -F "token=$TOKEN" \
  -F "archive=@solution.tar.gz" \
  -F "kind=agent" \
  | jq -r '.submission_id')

echo "Submission: $SUBMISSION_ID"

# 3. Poll for result (repeat until status is "completed" or "error")
curl -s http://localhost:8080/api/v1/result/$SUBMISSION_ID | jq .

# 4. Check run history
curl -s "http://localhost:8080/api/v1/history?token=$TOKEN" | jq .
```

### Poll loop

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
