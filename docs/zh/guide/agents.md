# 支持的 Agent

| Agent | `--agent` | 默认版本 | Stop hook | 自动恢复 |
|-------|-----------|----------|-----------|----------|
| Claude Code | `claude-code` | 2.1.258 | 支持 | 支持 |
| Codex | `codex` | 0.145.0 | 支持 | 支持 |
| OpenCode | `opencode` | 1.18.2 | 不支持 | 支持 |

在名字后加 `@<版本>` 可以使用其他版本，例如 `--agent codex@0.130.0`；运行记录中会写明实际使用的 `name@version`。

Agent CLI 不打进任务镜像。首次使用时，SForge 在宿主机上构建一个 bundle（固定版本的 Node.js 加 npm 包，缓存在 `~/.cache/sforge/agents`），再拷入每个 work 容器，所以容器安装 Agent 不需要网络。构建 bundle 需要 Linux x86_64 宿主机；下载镜像源用 `SFORGE_NODEJS_MIRROR_URL` 和 `npm_config_registry` 设置。

## API key、模型和推理强度

```bash
SFORGE_AGENT_API_KEY="sk-..." \
sforge run --task ad_placement_optimization --agent claude-code \
  --model claude-opus-4-8 --effort high
```

使用 Agent 默认 API 以外的端点时，设置 `SFORGE_AGENT_API_BASE_URL`。API key 只留在宿主机上：Agent 访问的是 judge server 的 LLM 网关，由网关加上 key 并记录 token 用量（`llm_requests.jsonl`，以及 `final_result.json` 中的 `usage`）。

`--effort`（`low`、`medium`、`high`、`max`）对应 Claude Code 的 `CLAUDE_CODE_EFFORT_LEVEL`、Codex 的 `model_reasoning_effort`（`max` 映射为 `xhigh`），以及 OpenCode 的 `reasoningEffort`（只对非 Anthropic provider 生效）。不设置时，各 Agent 使用自己的默认值。

`SFORGE_AGENT_EXTRA_ENV="KEY1=VAL1,KEY2=VAL2"` 可以向 work 容器传入额外的环境变量。

## 使用第三方模型

把 `SFORGE_AGENT_API_BASE_URL` 指向兼容的端点，并用 `--model` 指定模型。Claude Code 还需要设置模型路由和上下文窗口变量，见[使用第三方模型](/zh/examples/single-task-docker#使用第三方模型)。OpenCode 的模型名写作 `provider/model`（只写模型名时视为 `anthropic/<model>`）。

## Stop Hook

Agent 认为做完时，stop hook 会让它继续改进，直到时间预算用完。Claude Code 和 Codex 使用各自原生的 hook；OpenCode 没有 hook 机制，依靠自动恢复。调试时可以用 `--disable-stop-hook` 关闭。

## 自动恢复

Agent 在超时前退出（API 断连、崩溃）时，SForge 用它的恢复命令（`claude --continue`、`codex exec resume --last`、`opencode run --continue`）和剩余时间重新拉起。如果 Agent 在一秒内退出，或已恢复 100 次，就不再重试。用 `--disable-auto-resume` 关闭。

## 自定义 Agent

在 `sforge/harness/agent/` 下新建一个继承 `Agent` 的类，并在 `sforge/harness/agent/factory.py` 的 `_REGISTRY` 中注册：

```python
from sforge.harness.agent.base import Agent


class MyAgent(Agent):
    name = "my-agent"                 # --agent 使用的名字
    npm_package = "my-agent-cli"      # 装进 bundle 的 npm 包
    default_version = "1.2.3"
    run_cmd = 'my-agent run --prompt "$(cat {prompt_file})"'
    resume_cmd = 'my-agent resume --prompt "Continue working."'
    api_key_env = "MY_AGENT_API_KEY"
    model_env = "MY_AGENT_MODEL"
```

需要定制行为时，重写 `augment_env()`、`format_run_cmd()` 或 `install_stop_hook()`；不通过 npm 分发的 Agent 重写 `install()`。
