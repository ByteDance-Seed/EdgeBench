# 简介

## 什么是 SForge

SForge 是面向长程、迭代式编程任务的通用评测框架。Claude Code、Codex 等 Agent 在隔离的 work 容器里工作，可以随时把代码提交给独立的 judge 评分，根据反馈持续改进直到时间用完。所有提交中的最好成绩就是结果。

## SForge 与 EdgeBench

SForge 不绑定某一个 benchmark：任何按其[任务格式](/zh/tasks/task-format)组织的 benchmark 它都能运行，即一个包含 `benchmark.toml`、每道题一个子目录的目录。

[EdgeBench](https://github.com/ByteDance-Seed/EdgeBench/tree/main/edgebench) 是用 SForge 运行的主要 benchmark，放在同一仓库的 `edgebench/` 下，也是默认的 benchmark：不用 `-b <目录>` 指定别的 benchmark 时，SForge 就用它。51 道公开题覆盖 Python、C/C++、Rust、Java、Zig、Lean、Coq 等语言，类型包括优化问题、系统工程、科学计算、定理证明、知识工作和交互式文字游戏。本文档的示例都用它。

## 核心机制

1. **双容器隔离**：隐藏测试和评分程序只在 judge 镜像里，Agent 看不到。
2. **[迭代评测](/zh/features/iterative-evaluation)**：每次提交都会得到原始分数和评分程序的反馈；后台的 auto-eval 还会定期评测，即使 Agent 不提交，进度也会被记录。
3. **[长程执行](/zh/guide/agents#stop-hook)**：Stop hook 让 Agent 一直工作到时间预算用完，自动恢复会在崩溃后重新拉起 Agent。

## 架构

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

Judge server 运行在宿主机上：默认在 `sforge run` 进程内，也可以用 `sforge serve` 单独启动。它同时转发 Agent 的模型请求，因此 API key 只留在宿主机上，每个请求的用量也都被记录。

每道题最多有三个镜像，以 benchmark 名命名（下表为 `edgebench`）：

| 镜像 | 内容 | Agent 可见？ |
|------|------|-------------|
| `edgebench.base.<name>:<hash>` | 来自 `bases/<name>/` 的共享工具链（如 C++ 或 Lean + Mathlib 环境） | — |
| `edgebench.work.<task>:<hash>` | 工作区：初始代码、文档、工具 | 是 |
| `edgebench.judge.<task>:<hash>` | 工作区加上评分程序、隐藏测试和数据 | 否 |

Tag 是镜像输入内容的哈希，输入变了才会重建。Agent CLI 不打进镜像，而是在启动时拷入容器。
