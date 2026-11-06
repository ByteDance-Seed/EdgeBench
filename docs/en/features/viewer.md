---
title: Viewer and Replay
---

# Viewer and Replay

## Run Viewer

A small web UI over the run directories:

```bash
sforge viewer                          # http://127.0.0.1:8000
sforge viewer --runs-dir logs/runs --host 0.0.0.0 --port 8000
```

| Page | Path | Shows |
|------|------|-------|
| Runs | `/` | Every run and task with its best score |
| Run detail | `/run/{run_id}/{task_id}` | Score curve over time, every submission (score, validity, summary), token usage by model, and links to the raw files |

The viewer reads `logs/runs` on every request, so it shows runs in progress. It has no login; bind it to `127.0.0.1` (the default) unless your network is trusted.

## Replay

The viewer does not render agent transcripts. `sforge replay` opens a run's archived session in the agent's own UI instead:

```bash
sforge replay --run-id ad-placement-001 --task ad_placement_optimization
sforge replay --run-id ad-placement-001 --task ad_placement_optimization --session <session-id>
```

During a run SForge copies the agent's native session files out of the container every 60 seconds and at the end (`logs/runs/<run>/<task>/sessions/`). Replay copies them into a throwaway config home and starts the locally installed CLI in resume mode (`claude --resume` or `codex resume`), so the transcript renders exactly as the agent shows it. Nothing is sent to a model unless you type. Replay supports `claude-code` and `codex` runs; it needs that CLI installed on your machine.
