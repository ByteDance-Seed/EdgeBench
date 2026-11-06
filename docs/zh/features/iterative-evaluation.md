---
title: 迭代评测
---

# 迭代评测

运行期间 Agent 可以随时提交，每次都会得到分数和反馈：

1. Agent 在 work 容器里调用 `sforge-submit`。
2. Judge server 在新的 judge 容器里用该题的评分程序评分。
3. Agent 读到原始分数、提交是否有效以及评分程序的反馈，继续改进。

[Stop hook 和自动恢复](/zh/guide/agents#stop-hook)会让 Agent 一直工作到时间预算用完。

## sforge-submit

| 命令 | 说明 |
|------|------|
| `sforge-submit` | 提交该题的提交路径并等待结果 |
| `sforge-submit -d` | 同时显示逐项详情 |
| `sforge-submit -l` | 列出之前的提交 |

`--max-submissions N` 限制 Agent 的提交次数，`--submission-cooldown S` 要求两次提交至少间隔 S 秒；触发限制时 `sforge-submit` 会告诉 Agent。

## Auto-Eval

SForge 还会每 300 秒（`--eval-interval`）在后台评测一次当前工作区，轮次记为 `auto-1`、`auto-2`……Agent 看不到这些结果；它们保证 Agent 即使没有提交，进度也会被计入。Auto-eval 不受提交限制约束，用 `--disable-auto-eval` 关闭。

## 计分

评分程序把原始 `score`、`valid` 和反馈（`summary`、`details`、`metrics`）写入 `result.json`，见[任务格式](/zh/tasks/task-format#评分约定)。无效提交、崩溃和 judge 超时都不计分。

一次运行的结果是 Agent 提交和 auto-eval 中按该题 `direction` 最好的有效分数。用于 leaderboard 时，再按该题的 `[score] rescale` 映射到 0–100；Agent 只看到原始分数。运行结束时的工作区会被存档但不评分，所以只有提交过的状态才算数。

所有输出都写在 `logs/runs/<run-id>/<task-id>/` 下，见[运行输出](/zh/reference/cli#运行输出)。
