# 支持的 Agent

SForge 通过插件式的 Agent 注册表管理不同的 Code Agent。运行 EdgeBench 评测时，只需选择一个内置 Agent（如 `claude-code`）并提供 API Key 即可。

## Agent 注册表

SForge 内置了以下 Agent：

| Agent 名称 | CLI 名称 | API Key 环境变量 | 模型环境变量 | 默认模型 | Stop Hook | Auto-Resume |
|-----------|----------|-----------------|-------------|---------|-----------|-------------|
| Claude Code | `claude-code` | `ANTHROPIC_AUTH_TOKEN` | `ANTHROPIC_MODEL` | — | 支持 | 支持 |
| Codex | `codex` | `CODEX_API_KEY` | `CODEX_MODEL` | — | 支持 | 支持 |
| OpenCode | `opencode` | `ANTHROPIC_API_KEY` | — | — | 不支持 | 支持 |

使用 `--agent` 参数指定要运行的 Agent：

```bash
sforge run --task ad_placement_optimization --agent claude-code
sforge run --task ad_placement_optimization --agent codex
sforge run --task ad_placement_optimization --agent OpenCode
```

::: details 固定版本
每个 Agent 在 Work 容器内安装固定版本：

| CLI 名称 | 安装版本 |
|----------|----------|
| `claude-code` | Claude Code 2.1.159 |
| `claude-code-2.1.214` | Claude Code 2.1.214 |
| `codex` | Codex 0.130.0 |
| `codex-0.145.0` | Codex 0.145.0 |
| `opencode` | OpenCode 1.18.2 |

`claude-code-2.1.214` 和 `codex-0.145.0` 是更新的固定版本，作为独立 Agent 保留以保证
既有结果可比。Claude 5 系列模型（Fable/Mythos）需要使用 `claude-code-2.1.214`。
:::

::: details OpenCode 说明
- 模型名格式为 `provider/model`，裸模型名会视为 `anthropic/<model>`。
- 默认模型、自定义 base URL（`SFORGE_AGENT_API_BASE_URL`）和权限均通过
  `OPENCODE_CONFIG_CONTENT` 环境变量注入，容器内不写配置文件。
- `SFORGE_AGENT_API_BASE_URL` 沿用 Claude Code 约定（不带 `/v1`），SForge 会为
  OpenCode 的 AI SDK 客户端自动补上 `/v1`。
- 任务断网时会禁用 `webfetch` 和 `websearch`，避免模型在被阻断的请求上浪费轮次。
- OpenCode 无 Stop Hook 机制，长时运行依赖自动恢复循环（`opencode run --continue`）。
:::

## Agent 配置

### API Key

通过 `SFORGE_AGENT_API_KEY` 环境变量传入 API Key，SForge 会自动映射到对应 Agent 的环境变量（如 `ANTHROPIC_AUTH_TOKEN`、`CODEX_API_KEY` 等）：

```bash
SFORGE_AGENT_API_KEY="sk-xxxx" sforge run --task ad_placement_optimization --agent claude-code
```

### API 端点

通过 `SFORGE_AGENT_API_BASE_URL` 设置自定义 API 端点（适用于代理或私有部署）：

```bash
SFORGE_AGENT_API_BASE_URL="https://your-proxy.com/v1" \
SFORGE_AGENT_API_KEY="sk-xxxx" \
sforge run --task ad_placement_optimization --agent claude-code
```

### 模型覆盖

通过 `--model` 参数或 `SFORGE_AGENT_MODEL` 环境变量覆盖默认模型：

```bash
sforge run --task ad_placement_optimization --agent claude-code --model claude-opus-4-8
```

### 推理强度

通过 `--effort` 或 `SFORGE_AGENT_EFFORT` 选择 `low`、`medium`、`high` 或
`max`。两者均未设置时，Agent 保持自身默认配置。

| Agent | 原生配置 | 说明 |
|-------|----------|------|
| Claude Code | `CLAUDE_CODE_EFFORT_LEVEL` | 直接使用所选值 |
| Codex | `model_reasoning_effort` | 将 `max` 映射为 Codex 的 `xhigh` |
| OpenCode | `reasoningEffort` | 对非 Anthropic provider 生效；Anthropic provider 保持自身 thinking 配置 |

### 额外环境变量

通过 `SFORGE_AGENT_EXTRA_ENV` 向 Agent 容器注入额外的环境变量（逗号分隔的 `KEY=VALUE` 对）：

```bash
SFORGE_AGENT_EXTRA_ENV="DEBUG=1,CUSTOM_FLAG=true" \
sforge run --task ad_placement_optimization --agent claude-code
```

## Agent 工作原理

Agent 的完整生命周期如下：

1. **创建容器**：基于 Work 镜像创建 Docker 容器，注入环境变量（API Key、Judge URL 等）
2. **安装 Agent 运行时**：在容器内执行 Agent 的 `install_cmds`（如安装 Node.js、npm 包等）
3. **安装评测工具**：
   - `sforge-submit`：安装到 `/usr/local/bin/`，Agent 调用此命令提交代码
   - Stop Hook（可选）：阻止 Agent 提前退出
   - Auto-eval 守护进程（可选）：后台定时自动评测
4. **生成增强提示词**：将原始任务描述与评测说明、策略建议组合
5. **运行 Agent**：执行 Agent 的 `run_cmd`，Agent 开始在容器中工作
6. **收集结果**：Agent 超时或完成后，从状态文件中读取最佳成绩

整个过程中，Agent 可以随时调用 `sforge-submit` 提交代码获取反馈，后台的 auto-eval 守护进程也会定期自动提交评测。

## Stop Hook 机制

Stop Hook 是 SForge 的一个重要机制，用于阻止 Agent 提前退出。

### 工作原理

当 Agent（如 Claude Code）认为任务已完成并尝试退出时，Stop Hook 会拦截退出请求并返回一个阻止信号，要求 Agent 继续工作。这确保了 Agent 能充分利用分配的时间，持续改进代码。

### 适用 Agent

| Agent | Hook 类型 | 说明 |
|-------|----------|------|
| `claude-code` | Claude Code Stop Hook | 通过 `.claude/settings.json` 注册 |
| `codex` | Codex Stop Hook | 通过 `/etc/codex/hooks.json` 注册 |
| `opencode` | — | 无 hook 机制，提前退出由自动恢复兜底 |

### 禁用 Stop Hook

如果不需要 Stop Hook（例如调试时），可以通过 `--disable-stop-hook` 禁用：

```bash
sforge run --task ad_placement_optimization --agent claude-code --disable-stop-hook
```

## 自动恢复（Auto-Resume）

Auto-Resume 处理的是 **Agent 异常退出** 的情况（如 API 断连、瞬时错误等），这类退出会绕过 Stop Hook。当 Agent 进程在超时前意外终止时，框架会使用 Agent 原生的会话恢复机制自动重新启动。

### 工作原理

1. Agent 异常退出（非超时导致）
2. 框架检测到提前退出
3. 使用 Agent 的恢复命令重新启动（如 Claude Code 使用 `claude --continue`）
4. 将剩余超时预算传递给恢复后的会话
5. Agent 从上次对话状态继续工作

### 适用 Agent

| Agent | 恢复机制 |
|-------|---------|
| `claude-code` | `claude --continue -p "Continue working."` |
| `codex` | `codex exec resume --last "Continue working."` |
| `opencode` | `opencode run --continue "Continue working."` |

### 安全保护

- 如果 Agent 在 **1 秒内** 退出，框架判定为系统性故障，停止重试
- 每次运行最多 **100 次** 恢复尝试

### 禁用自动恢复

```bash
sforge run --task ad_placement_optimization --agent claude-code --disable-auto-resume
```

## 使用第三方模型

Claude Code 和 Codex 都支持接入第三方模型进行评测——通过 `SFORGE_AGENT_API_BASE_URL` 指向兼容的 API 端点，再用 `--model` 指定模型名即可。

Claude Code 内部有多层模型路由（opus/sonnet/haiku 层级、subagent 调用）和上下文窗口管理逻辑，因此使用第三方模型时需要额外配置缓存优化、模型路由变量和上下文窗口等设置。详见[单任务运行 (Docker) — 使用第三方模型](/zh/examples/single-task-docker#使用第三方模型)。

## 自定义 Agent

SForge 目前添加自定义 Agent 只有一种方式：在 SForge 源码中实现新的 `Agent` 子类，并在 agent factory 中注册。当前没有单独的运行时插件/外部模块加载机制。

### 步骤

1. 在 `sforge/harness/agent/` 下创建新文件，例如 `my_agent.py`。
2. 定义一个继承 `sforge.harness.agent.base.Agent` 的类。
3. 设置必要的类属性：
   - `name` -- `--agent` 使用的 CLI 名称
   - `install_cmds` -- 在 Work 容器中安装 Agent 运行时的命令
   - `run_cmd` -- 启动 Agent 的命令模板，通常需要读取 `{prompt_file}`
   - `api_key_env` -- 该 Agent 期望接收 API Key 的环境变量名
4. 按需设置 `api_base_env`、`model_env`、`default_model`、`stop_hook`、`resume_cmd`。
5. 在 `sforge/harness/agent/factory.py` 中把新类加入 `_REGISTRY`。

最小示例：

```python
from sforge.harness.agent.base import Agent


class MyAgent(Agent):
    name = "my-agent"
    install_cmds = [
        "pip install my-agent-cli",
    ]
    run_cmd = 'my-agent run --prompt "$(cat {prompt_file})"'
    api_key_env = "MY_AGENT_API_KEY"
    model_env = "MY_AGENT_MODEL"
    resume_cmd = 'my-agent resume --prompt "Continue working."'
```

然后注册：

```python
from sforge.harness.agent.my_agent import MyAgent

_REGISTRY = {
    # ... existing agents ...
    "my-agent": MyAgent,
}
```

注册后即可运行：

```bash
SFORGE_AGENT_API_KEY="..." sforge run --task ad_placement_optimization --agent my-agent
```

如果你的 Agent 需要自定义环境变量映射、命令格式化、Stop Hook 安装或恢复逻辑，可以覆写 `Agent` 上的对应方法，例如 `augment_env()`、`format_run_cmd()` 或 `install_stop_hook()`。
