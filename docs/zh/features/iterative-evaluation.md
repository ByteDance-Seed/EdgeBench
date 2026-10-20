---
title: 迭代评测框架
---

# 迭代评测框架

SForge 采用迭代式“评测-改进”循环：Agent 修改代码，提交评测，根据反馈继续改进，直到超时。

这套机制分成三类：

| 机制 | 作用 |
|------|------|
| `sforge-submit` | Agent 主动提交代码并获得即时反馈 |
| Auto-eval | 定期自动评测当前代码，增加采样点 |
| Stop hook / Auto-resume | 让 Agent 在超时前持续工作 |
| Submission limits | 控制 Agent 主动提交的次数和频率 |

## 工作流程

1. Agent 在 **Work 容器** 中工作
2. Agent 调用 `sforge-submit` 主动提交当前代码
3. Judge Server 启动临时 **Judge 容器**，运行 `eval_cmd`
4. SForge 返回 `pass_rate`、`score`、失败项和摘要
5. Agent 根据反馈继续修改并再次提交
6. Auto-eval 在后台定期提交当前代码，记录额外采样点
7. 最终结果取所有提交中的最佳成绩

## 主动提交：`sforge-submit`

`sforge-submit` 会安装到 Work 容器的 `/usr/local/bin/sforge-submit`。

它会：

- 从 `submit_paths` 打包代码，并排除 `submit_exclude`
- 提交到 Judge Server
- 轮询评测结果
- 显示通过率、分数、失败项和摘要
- 更新 `/tmp/sforge_state.json`

常用命令：

| 命令 | 说明 |
|------|------|
| `sforge-submit` | 提交并等待结果 |
| `sforge-submit --details` / `-d` | 提交并等待逐项详情 |
| `sforge-submit --no-wait` | 提交快照，接受后返回提交 ID |
| `sforge-submit --result ID --details` | 等待已有提交的反馈，不重复提交 |
| `sforge-submit --result ID --no-wait --details` | 只查询一次，返回 pending 或终态反馈 |
| `sforge-submit --list` / `-l` | 列出历史提交 |

异步提交后，可以先继续独立工作，再查询同一 ID。pending 响应不包含分数，也不更新
展示缓存。后续修改不会改变已接受的快照；可能需要恢复的候选版本应另行保留。
详见[提交快照与读取结果](../reference/judge-api.md#提交快照与读取结果)。

## Auto-eval：增加采样点

Auto-eval 是后台自动评测守护进程。它的目的不是给 Agent 注入新反馈，而是**定期记录当前代码状态，增加评测采样点**。

这对长时间运行很有用：即使 Agent 没有及时调用 `sforge-submit`，SForge 仍然能记录中间版本，避免只看到最终一次结果。

特点：

- 默认间隔：`300` 秒
- 通过 `--eval-interval` 调整间隔
- 通过 `--disable-auto-eval` 禁用
- 使用独立轮次：`auto-1`、`auto-2`、...
- 结果不会注入 Agent 上下文
- Auto-eval 提交不受 `--max-submissions` 和 `--submission-cooldown` 限制

```bash
# 每 600 秒自动采样一次
sforge run --task ad_placement_optimization --agent claude-code --eval-interval 600

# 禁用自动采样
sforge run --task ad_placement_optimization --agent claude-code --disable-auto-eval
```

## 让 Agent 持续工作

### Stop hook

Stop hook 用于阻止 Agent 提前“认为完成”并退出。Agent 尝试退出时，hook 会要求它继续工作，直到运行超时。

- 适合防止 Agent 过早停止
- 默认对支持 stop hook 的 Agent 启用
- 调试或短跑时可禁用

```bash
sforge run --task ad_placement_optimization --agent claude-code --disable-stop-hook
```

### Auto-resume

Auto-resume 用于处理异常退出，例如 API 断连、瞬时错误或 Agent 进程意外结束。这类退出可能绕过 stop hook。

- 异常退出后，SForge 使用 Agent 原生恢复机制继续会话
- 剩余 timeout 会传递给恢复后的会话
- 对支持 `resume_cmd` 的 Agent 默认启用
- 安全保护：30 秒内退出或恢复次数过多时停止重试

```bash
sforge run --task ad_placement_optimization --agent claude-code --disable-auto-resume
```

## 提交次数和冷却时间

有些任务需要限制 Agent 主动评测的次数，或防止过于频繁提交。可以使用：

| 参数 | 说明 |
|------|------|
| `--max-submissions N` | 限制 Agent 主动提交总次数 |
| `--submission-cooldown S` | 限制两次 Agent 主动提交之间至少间隔 S 秒 |

```bash
sforge run \
  --task ad_placement_optimization \
  --agent claude-code \
  --max-submissions 10 \
  --submission-cooldown 120
```

这些限制只作用于 Agent 主动调用的 `sforge-submit`。Auto-eval 采样不计入次数，也不受冷却时间限制。

如果触发限制，`sforge-submit` 会提示剩余次数或需要等待的时间；Agent 应继续本地检查和改进，稍后再提交。

## 评分和最终结果

每次提交都会生成一条记录，包括通过率、分数、摘要和详情。

| 指标 | 说明 |
|------|------|
| `pass_rate` | 测试通过比例 |
| `score` | 连续分数，常用于优化任务 |
| `score_direction` | `maximize` 或 `minimize` |

最终结果取所有提交中的最佳成绩，包括：

- Agent 主动提交：`agent-1`、`agent-2`、...
- Auto-eval 采样：`auto-1`、`auto-2`、...

最优提交选择策略由任务 JSON 的 `judge.selection` 控制：

- `pass_rate_first`：优先通过率，100% 或通过率相同后再比分数
- `score_first`：直接比较分数
- `valid_then_score`：先过滤无效提交，再比较分数

## 状态文件

Work 容器内的 `/tmp/sforge_state.json` 记录提交历史：

```json
{
  "best_pass_rate": 0.95,
  "best_score": 250,
  "best_round": "agent-3",
  "submissions": []
}
```
