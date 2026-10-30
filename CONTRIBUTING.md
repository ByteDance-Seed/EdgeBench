# Contributing to SForge

Thank you for your interest in contributing to SForge! This document covers the guidelines and workflow for contributing to the harness codebase.

## Prerequisites

- Python 3.11–3.13
- Docker Engine 24+
- `pip` for local editable installs

## Getting Started

```bash
# Clone the repository
git clone https://github.com/ByteDance-Seed/EdgeBench.git && cd EdgeBench

# Install locally for development
pip install -e .

# EdgeBench is in edgebench/; verify the CLI sees its tasks
sforge list
```

## Project Structure

```
sforge/
├── cli.py                  # CLI entry point (list/pull/build/push/run/eval/serve/viewer/replay)
├── viewer.py               # sforge viewer: run list, score curves, token usage
├── replay.py               # sforge replay: open archived sessions in the agent's UI
├── harness/
│   ├── config.py           # SForgeConfig — environment variable injection
│   ├── constants.py        # Paths and other constants
│   ├── task_spec.py        # Benchmark and TaskSpec (benchmark.toml, task.toml)
│   ├── agent/              # Pluggable agent abstraction
│   ├── backend/            # Container backends (Docker, K8s, E2B)
│   ├── docker_build.py     # Image build/pull/push, blobs
│   ├── run_agent.py        # Agent execution orchestration
│   ├── run_evaluation.py   # Judge submission grading
│   ├── judge_server.py     # FastAPI REST API
│   ├── llm_gateway.py      # Model-request forwarding and token accounting
│   ├── evolve_scripts.py   # In-container script generators
│   ├── grading.py          # EvalReport and scoring
│   └── score_rescale.py    # Raw task score -> 0..100
tools/judge_local.py        # Run a judge image on a submission archive
tools/ci_images.py          # Build/push a benchmark's missing images (used by CI)
edgebench/                  # The EdgeBench benchmark (CC BY 4.0)
├── benchmark.toml          # Name, image registry, blob URL
├── tasks/                  # One directory per task (rules: tasks/SCHEMA.md)
└── bases/                  # Shared base images used by tasks
docs/                       # Documentation site (VitePress, en + zh)
```

## Development Workflow

1. Create a feature branch from `main`.
2. Make your changes — keep commits focused and atomic.
3. Run the checks described below before opening a PR.
4. Open a pull request with a clear description of *what* and *why*.

## Code Style

The project follows standard Python conventions. No automated formatter is enforced yet, but please adhere to the existing style:

- **Type annotations** — use modern syntax (`str | None`, `dict[str, str]`). All modules should include `from __future__ import annotations`.
- **Dataclasses** — prefer `@dataclass` for structured data over plain dicts or tuples.
- **Naming** — `snake_case` for functions/variables, `PascalCase` for classes, `UPPER_SNAKE_CASE` for constants. Prefix private helpers with `_`.
- **Docstrings** — module-level docstrings are encouraged. Keep function/class docstrings short and only when the name is not self-explanatory.
- **Comments** — explain *why*, not *what*. Avoid obvious or redundant comments.

## License Headers

All `.py` source files outside `edgebench/` must include the Apache 2.0 license header at the top:

```python
# Copyright (c) 2026 ByteDance Ltd. and/or its affiliates
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
```

For files with a shebang (`#!/usr/bin/env python3`), the license header goes immediately after the shebang line.

Contributions to `edgebench/` are licensed under CC BY 4.0 ([`edgebench/LICENSE`](edgebench/LICENSE)). Keep the license files and headers of third-party code inside a task as they are.

## Running Tests

```bash
python -m pytest tests/ -v
```

## Common Contribution Scenarios

### Adding a New Agent

1. Create `sforge/harness/agent/<agent_name>.py` — subclass `Agent` from `sforge.harness.agent.base`.
2. Register the agent in `sforge/harness/agent/factory.py`.
3. Set `npm_package` and `default_version` (the CLI is installed from a host-built bundle), `run_cmd`, `api_key_env`, and optionally `api_base_env`, `model_env`, `stop_hook` and `resume_cmd`. See [Custom Agents](https://bytedance-seed.github.io/EdgeBench/en/guide/agents#custom-agents).

### Fixing an EdgeBench Task

The tasks were migrated from v1 without fixing their graders, so scores stay comparable with the
leaderboard; known problems are listed in each task's `NOTES.md`. Fixes come one task at a time:

1. **Report it.** Open a *Task finding* issue: the claim, who is scored wrongly and by how much, and
   how to reproduce it on the current judge image.
2. **Fix it in a pull request** against `edgebench/tasks/<task_id>/`. Bump `version` in `task.toml`,
   describe the change and its score effect under **Changes** in `NOTES.md`, and remove the fixed
   entry from **Known issues**.
3. **Show old vs new.** Grade the same submissions with the old and the new judge on the same host
   and put the table in the pull request. Build with `sforge build --task <task_id>` and grade with
   `sforge eval --task <task_id> --archive <sub.tar.gz>`, or run any judge image directly with
   `tools/judge_local.py --image <tag>`; the old judge's tag stays on Docker Hub.
4. **Review.** A fix is merged when the problem is real on the current judge, a good-faith solver is
   scored wrongly or non-repeatably because of it, and the fix removes it without changing scores for
   correct work (or, if the score scale changes, says how old scores map). Someone who knows the
   field reviews findings about scoring logic.
5. **Publish.** CI builds the changed images on the pull request and publishes them as
   `docker.io/seededge/edgebench.<role>.<name>` after merge. A new blob must be uploaded to the
   `task-blobs` Release before the change merges.

A task becomes `status = "verified"` once a review of the task as a whole leaves no open blocking issue.
New tasks follow the same rules; see SForge's [Task Format](https://bytedance-seed.github.io/EdgeBench/en/tasks/task-format)
and [`edgebench/tasks/SCHEMA.md`](edgebench/tasks/SCHEMA.md).

### Modifying the Judge Server API

The judge server (`sforge/harness/judge_server.py`) is a FastAPI app. When changing endpoints:

- Keep the `/api/v1/` prefix for all routes.
- Submissions are async — `POST /submit` enqueues, `GET /result/{id}` polls.
- Ensure backward compatibility or bump the API version.

## Pull Request Guidelines

- Keep PRs focused — one logical change per PR.
- Include a summary of what changed and why in the PR description.
- If your change affects tasks or the judge API, describe how you tested it end-to-end (e.g., `sforge build` + `sforge eval`, or `sforge run`).
- Do not commit files that contain secrets, API keys, or credentials.

## Reporting Issues

When filing a bug report, please include:

- The command you ran and its full output.
- Your Python version (`python --version`) and OS.
- Docker version (`docker --version`).
- The task ID and agent involved, if applicable.
