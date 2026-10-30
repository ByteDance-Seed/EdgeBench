---
title: 结果查看与回放
---

# 结果查看与回放

## 结果查看页面

一个基于运行目录的小型 Web 界面：

```bash
sforge viewer                          # http://127.0.0.1:8000
sforge viewer --runs-dir logs/runs --host 0.0.0.0 --port 8000
```

| 页面 | 路径 | 内容 |
|------|------|------|
| 运行列表 | `/` | 所有运行和任务及其最佳分数 |
| 运行详情 | `/run/{run_id}/{task_id}` | 分数随时间的曲线、每次提交（分数、是否有效、摘要）、按模型统计的 token 用量，以及原始文件链接 |

页面每次请求都重新读取 `logs/runs`，所以能看到正在进行的运行。它没有登录，除非网络可信，请保持绑定 `127.0.0.1`（默认）。

## 回放

结果页面不渲染 Agent 的对话记录。`sforge replay` 在 Agent 自己的界面里打开一次运行存档的会话：

```bash
sforge replay --run-id ad-placement-001 --task ad_placement_optimization
sforge replay --run-id ad-placement-001 --task ad_placement_optimization --session <session-id>
```

运行期间，SForge 每 60 秒以及结束时把 Agent 的原生会话文件从容器里拷出来（`logs/runs/<run>/<task>/sessions/`）。回放会把它们拷到一个临时配置目录，并以恢复模式启动本机安装的 CLI（`claude --resume` 或 `codex resume`），对话记录的显示与 Agent 中完全一致。除非你输入内容，否则不会向模型发送任何请求。回放支持 `claude-code` 和 `codex` 的运行，需要本机装有对应的 CLI。
