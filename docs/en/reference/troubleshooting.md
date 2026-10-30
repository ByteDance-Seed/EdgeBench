---
title: Troubleshooting
---

# Troubleshooting

## Images

| Symptom | Cause | Fix |
|---------|-------|-----|
| `Image '...' not found. Run sforge pull ... or sforge build ...` | The task's images are not in local Docker | `sforge pull --task <id>`, or `sforge build --task <id>` |
| `sforge pull` reports `FAIL` | The tag is not published (a changed task, or CI has not published it yet), Docker Hub is unreachable, or anonymous pulls hit Docker Hub's rate limit (`toomanyrequests`) | Build locally with `sforge build`; `docker login` for the rate limit; for network problems see [Network Setup](/en/configuration/network-setup) |
| `blob ...: cannot download ...` | The blob is not reachable at `SFORGE_BLOB_URL` | Check access to GitHub Release assets, or point `SFORGE_BLOB_URL` at a local `file://` copy |
| `blob ...: downloaded sha256 ... != ...` | The served file is not the declared blob | Remove the mirror or fix the copy; never edit the sha256 to match |
| `docker build exited 1` | A build step failed | Read the build log (below) |

### Build logs

Each image's build log is written to `logs/build_images/<image>_<tag>.log`, for example `logs/build_images/ad_placement_optimization-judge_1c6838c6d7fd.log`. The terminal message is often truncated; the log has the full Docker output.

### Force a rebuild

Tags are content hashes, so editing a task already triggers a rebuild of exactly the affected images. To rebuild an image whose tag exists (for example after a broken build), use:

```bash
sforge build --task ad_placement_optimization --force-rebuild            # work + judge
sforge build --task ad_placement_optimization --force-rebuild-with-base  # also the base
```

## Agent Issues

### Agent bundle build fails

On first use of an agent version, SForge builds its bundle on the host (Node.js plus the npm package) under `~/.cache/sforge/agents`. If downloads fail, set `SFORGE_NODEJS_MIRROR_URL` and/or `npm_config_registry`, or a proxy. Building a bundle needs a Linux x86_64 host.

### The agent cannot reach the model

The agent talks to the judge server's LLM gateway, which forwards to the real API. Check, in order:

1. `SFORGE_AGENT_API_KEY` and `SFORGE_AGENT_API_BASE_URL` on the host that runs `sforge run`.
2. `logs/runs/<run>/<task>/llm_requests.jsonl`: one line per request with the upstream status.
3. Whether the host needs a proxy for the API (`SFORGE_HTTPS_PROXY`).

### Agent stuck or not making progress

```bash
# Full output
cat logs/runs/<run_id>/<task_id>/agent_output.txt

# Assistant text only (Claude Code stream-json)
jq -r 'select(.type == "assistant") | .message.content[] | select(.type == "text") | .text' \
  logs/runs/<run_id>/<task_id>/agent_output.txt

# Or open the session in Claude Code / Codex itself
sforge replay --run-id <run_id> --task <task_id>
```

### Agent exiting too early

The stop hook is on by default for `claude-code` and `codex`; do not pass `--disable-stop-hook`. Abnormal exits are relaunched by auto-resume, unless the agent exits within a second (a systematic failure) or after 100 resumes; see `run_agent.log`.

### Kubernetes and E2B

| Symptom | Cause | Fix |
|---------|-------|-----|
| Pod stays `Pending` or never pulls its image | Scheduling, node selector or registry access | `kubectl -n <namespace> describe pod <pod>` |
| An isolated task reaches the internet on Kubernetes | The CNI does not enforce NetworkPolicy | Use a CNI that does |
| `sforge-submit` cannot connect | The sandbox cannot reach `--judge-advertise` / `--judge-url` | Use an address and open port the pods or Sandboxes can reach |
| E2B: Template not found | No Template for this task version | Build it (see the [E2B example](/en/examples/single-task-e2b)) or set `SFORGE_E2B_TEMPLATE_NAMESPACE` / `SFORGE_E2B_TEMPLATE_MAP` |
| E2B: `Sandbox not found` near the end of a run | The plan's maximum Sandbox lifetime was reached | Shorten `--timeout` |

### No submissions recorded

1. Check `agent_output.txt` for `sforge-submit` calls and their output.
2. Check that the sandbox can reach the judge (`--judge-advertise` / `--judge-url` on k8s and E2B).
3. With `--disable-auto-eval`, a run where the agent never submitted has no submissions.

### Every submission is invalid

Look at one submission's `submissions/<round>/judge_output.txt` and `result.json`. Common causes: the grader found nothing to grade (check the task's `[submission] paths`), the judge timed out, or an LLM-graded task has no credentials (`SFORGE_JUDGE_EXTRA_ENV`).

## Container Cleanup

`sforge run` removes its containers on exit, including on Ctrl+C and `SIGTERM`. After `SIGKILL` or a crash, containers may be left running:

```bash
docker ps --filter "name=sforge"
docker ps --filter "name=sforge" -q | xargs -r docker stop
docker ps --filter "name=sforge" -aq | xargs -r docker rm
```

Leftover iptables chains from isolated Docker runs are removed by the next `sforge run`; see [Single Task (Docker)](/en/examples/single-task-docker#network-isolation) to remove them by hand.

## FAQ

**Q: When are images rebuilt?**
A: Whenever the files that go into them change: `bases/<name>/` for the base, `environment/` for the work image, `environment/` and `judge/` for the judge image. Editing `instruction.md`, `task.toml` or `NOTES.md` does not rebuild anything.

**Q: Does changing `instruction.md` require a rebuild?**
A: No. The prompt is sent at run time, not baked into an image.

**Q: Can I run multiple tasks in parallel?**
A: Yes, pass several task IDs or an experiment file. All tasks of one `sforge run` share its judge server. On Docker, keep it to a few tasks per host.

**Q: How do I compare results across runs?**
A: `sforge viewer`, or each task's `final_result.json`.

**Q: The agent is running but I see no output.**
A: Multi-task runs are silent on the terminal; read the per-task files under `logs/runs/<run_id>/<task_id>/` (listed in [Run Outputs](/en/reference/cli#run-outputs)).

**Q: What is the difference between the judge timeout and `--timeout`?**
A: `[judge] timeout_sec` in `task.toml` limits one grading run; `--timeout` is the agent's total time budget.
