# Introduction

## What is SForge

SForge is a general evaluation harness for long-horizon, iterative coding tasks. An agent such as Claude Code or Codex works in an isolated work container and submits its code to a separate judge as often as it likes, improving on the feedback until time runs out. The best score across its submissions is the result.

## SForge and EdgeBench

SForge is not tied to one benchmark: it runs any benchmark written in its [task format](/en/tasks/task-format), a directory with a `benchmark.toml` and one directory per task.

[EdgeBench](https://github.com/ByteDance-Seed/EdgeBench/tree/main/edgebench) is the main benchmark run with SForge. It lives in the same repository under `edgebench/` and is the default: SForge uses it unless you pass another benchmark directory with `-b <dir>`. Its 51 public tasks span Python, C/C++, Rust, Java, Zig, Lean, Coq and more, and include optimization, systems engineering, scientific computing, theorem proving, knowledge work and interactive text games. The examples in these docs use it.

## Key Mechanisms

1. **Two-container isolation**: the hidden tests and the grader live only in the judge image; the agent never sees them.
2. **[Iterative evaluation](/en/features/iterative-evaluation)**: every submission gets a raw score and the grader's feedback, and a background auto-eval records progress even when the agent does not submit.
3. **[Long-horizon execution](/en/guide/agents#stop-hook)**: a stop hook keeps the agent working until the time budget ends, and auto-resume restarts it after a crash.

## Architecture

```
┌─────────────────────────┐            ┌────────────────────────────────┐
│     Work container      │            │  Judge server (host)           │
│                         │  archive   │                                │
│  workspace + docs       │ ─────────> │  POST /api/v1/submit           │
│  no hidden tests        │   (HTTP)   │    → fresh judge container     │
│                         │            │    → extract archive, grade    │
│  agent works here       │ <───────── │    → score + feedback          │
│  sforge-submit          │  results   │                                │
│                         │            │  /api/v1/llm/…  LLM gateway    │
│  model requests ────────┼──────────> │    → model API (real key)      │
└─────────────────────────┘            └────────────────────────────────┘
```

The judge server runs on the host, inside `sforge run` by default or as a separate `sforge serve`. It also forwards the agent's model requests, so the API key stays on the host and every request is counted.

Each task has up to three images, named after the benchmark (`edgebench` below):

| Image | Contents | Agent can see? |
|-------|----------|----------------|
| `edgebench.base.<name>:<hash>` | Shared toolchain from `bases/<name>/` (e.g. a C++ or Lean + Mathlib environment) | — |
| `edgebench.work.<task>:<hash>` | The workspace: starter code, docs, tools | Yes |
| `edgebench.judge.<task>:<hash>` | Workspace plus grader, hidden tests and data | No |

Tags are content hashes of each image's inputs, so an image is rebuilt exactly when they change. The agent CLI is not part of the images; it is copied in at start-up.
