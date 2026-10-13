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

### Preserving a settled judge registration (opt-in)

Start `sforge serve --checkpoints --port 8080` to expose the controller endpoints below. Without `--checkpoints`, all return 404 and no checkpoint bank is created. Disable them by restarting without the flag; retain the private bank and restored run reservations for diagnosis, and use a fresh run ID for a separate experiment.

All checkpoint endpoints require the running judge's `admin_secret` in the JSON body. An agent's submission token identifies a capture source but cannot authorize capture or restore. For another controller, transfer only the authorized `logs/checkpoints/` bank into its own log directory; use that controller's independently created admin secret. Do not transfer the source admin-secret file or session tokens.

```http
POST /api/v1/checkpoint/capture
Content-Type: application/json

{"token":"SOURCE_SESSION_TOKEN","admin_secret":"CURRENT_CONTROLLER_SECRET","capture_id":"11111111111111111111111111111111"}
```

`capture_id` is an optional caller-generated 32-character hexadecimal operation ID. A retry for the same registration returns the original point, even after later submissions; it neither captures the later state nor writes another capsule. Another registration cannot reuse the ID. Omit it for a new manual capture. The response contains `checkpoint_id`, `manifest_sha256`, the task/source run, preserved opportunity counters and remaining cooldown, and the native-selected incumbent's round/size/digest. The private capsule contains all released agent history and full result reports plus the selected archive; it contains no session or admin token. Archive bytes remain opaque and are never extracted during capture/restore.

```http
POST /api/v1/checkpoint/restore
Content-Type: application/json

{"checkpoint_id":"11111111111111111111111111111111","manifest_sha256":"CAPTURED_64_CHARACTER_SHA256","run_id":"fresh-branch","admin_secret":"CURRENT_CONTROLLER_SECRET"}
```

The response issues a fresh submission token for `fresh-branch`. Read back using the existing `/api/v1/history?token=...` and `/api/v1/result/{submission_id}` endpoints. Retained results have fresh lookup IDs and unchanged original reports; `logs/runs/fresh-branch/checkpoint-origin.json` records their source mapping. The selected archive is retained under its original round. Restore performs **no evaluation**. The next `/submit` uses the existing native counter, budget, cooldown and selection rules. Cooldown resumes from the captured remaining **duration** when the fresh registration is published; offline waiting and capsule materialization do not refill evaluation opportunities or spend that duration. A later source improvement is absent from an earlier capsule.

If the restore response is lost, call `POST /api/v1/checkpoint/restore-result` with the **same** JSON body (`checkpoint_id`, `manifest_sha256`, `run_id`, and current `admin_secret`). It returns the original response shape and the already published submission token. It does not allocate another registration, replay grading, or restart cooldown. Readback also remains valid after subsequent submissions and preserves their consumed opportunities. The existing origin marker must match and the registration must still be live; a missing, mismatched, partial or lost registration returns 409. Wrong admin authority returns 403, and malformed bodies return 422. A persisted origin marker alone cannot recreate credentials after a judge process restart. This recovery does not recover a runner's phase deadline: its controller must retain the original activation-time deadline and must not initialize a new duration on retry. A new `run_id` represents a different branch, not recovery of this response.

This version supports settled non-game registrations on the configured Docker backend, with no automatic evaluations. The native Python source, full task specification, actual Docker judge image ID, selection policy/direction and effective CPU/memory limits are bound. Missing/moved bytes, mismatched evaluator facts, queued/running results, consumed rounds without released history, conflicting result/history records and unsupported profiles return 409. Wrong admin authority returns 403; malformed request bodies return 422. Existing run identities, replayed restores and interrupted destination reservations are rejected rather than reset. An ordinary retry can recover an exception rolled back before completion; a process crash leaving a reservation fails closed and needs controller inspection. An accepted restore reserves the entire destination run ID, including against later cold registration while this feature is enabled.

The bank is trusted private controller storage. SHA-256 detects disagreement with the controller's captured reference; it does not authenticate a malicious administrator, certify arbitrary report contents as credential-free, or make a worker checkpoint complete. Restore does not restore worker code beyond the incumbent archive, model sessions, research state, external-effect authority, or the runner's remaining total time budget. A continuation runner must preserve those separately before treating branches as comparable. Do not restart a restored run as a cold registration after disabling checkpoints.

Two native consistency fixes also apply with the feature off: backend preparation failure publishes no token/resource row, and grading failures now release history with `status="error"`, matching `/result`, rather than labeling the history completed. Successful cold registration defaults, submission allocation and ranking are unchanged.

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
