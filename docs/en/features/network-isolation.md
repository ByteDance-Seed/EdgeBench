---
title: Network Isolation
---

# Network Isolation

An isolated work container can reach only the judge server. The agent still has its model, because model requests go through the judge server's LLM gateway, and needs nothing else: everything a task uses is in its images, and the agent is copied in at start-up.

Each task sets `internet` under `[environment]` in its `task.toml`; most tasks are isolated. Override it for a run with `--disable-internet` or `--enable-internet`, or per task with `internet:` in an [experiment file](/en/configuration/experiments).

Judge containers have no network at all unless the task sets `[judge] internet = true` (only the LLM-graded task does), since graders run submitted code. Game containers keep networking so the judge server can reach them; they run no submitted code.

| Backend | Enforced by | Requires |
|---------|-------------|----------|
| Docker | iptables rules on the host, removed when the run ends | Passwordless `sudo iptables` |
| Kubernetes | A NetworkPolicy per Pod that allows only the judge and DNS | A CNI that enforces NetworkPolicy; check with a small task first |
| E2B | The Sandbox's network rules (`update_network`) | — |

Isolated containers get no proxy variables. If the host needs a proxy to reach the model API, set `SFORGE_HTTPS_PROXY`; the LLM gateway uses it.

## For Task Authors

With `internet = false`, everything the agent needs must be in the work image: do not ask it to download dependencies or clone repositories. SForge adds a network notice to the prompt. Set `[judge] internet = true` only when grading itself needs the network, and say why in `NOTES.md`.
