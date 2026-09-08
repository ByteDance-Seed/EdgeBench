# Supported Agents

SForge manages different Code Agents through a plugin-style agent registry. To run EdgeBench evaluations, simply pick a built-in agent (e.g., `claude-code`) and provide an API key.

## Agent Registry

| Agent | CLI Name | API Key Env | Model Env | Default Model | Stop Hook | Auto-Resume |
|-------|----------|-------------|-----------|---------------|-----------|-------------|
| Claude Code | `claude-code` | `ANTHROPIC_AUTH_TOKEN` | `ANTHROPIC_MODEL` | -- | Yes | Yes |
| Codex | `codex` | `CODEX_API_KEY` | `CODEX_MODEL` | -- | Yes | Yes |
| OpenCode | `opencode` | `ANTHROPIC_API_KEY` | -- | -- | No | Yes |

Use the `--agent` flag to select an Agent:

```bash
sforge run --task ad_placement_optimization --agent claude-code
sforge run --task ad_placement_optimization --agent codex
sforge run --task ad_placement_optimization --agent OpenCode
```

::: details Pinned versions
Each agent installs a fixed release inside the Work container:

| CLI name | Installed release |
|----------|-------------------|
| `claude-code` | Claude Code 2.1.159 |
| `claude-code-2.1.214` | Claude Code 2.1.214 |
| `codex` | Codex 0.130.0 |
| `codex-0.145.0` | Codex 0.145.0 |
| `opencode` | OpenCode 1.18.2 |

`claude-code-2.1.214` and `codex-0.145.0` are newer pins kept as separate
agents so existing results stay comparable. Claude 5-family models
(Fable/Mythos) require `claude-code-2.1.214`.
:::

::: details OpenCode notes
- Models are addressed as `provider/model`; a bare model name is treated as
  `anthropic/<model>`.
- The default model, custom base URL (`SFORGE_AGENT_API_BASE_URL`), and
  permissions are injected via the `OPENCODE_CONFIG_CONTENT` environment
  variable. No config file is written into the container.
- `SFORGE_AGENT_API_BASE_URL` follows the Claude Code convention (no `/v1`);
  SForge appends `/v1` for OpenCode's AI SDK client.
- When the task runs without internet, `webfetch` and `websearch` are denied so
  the model does not waste turns on blocked requests.
- OpenCode has no Stop-hook mechanism; long runs rely on the harness
  auto-resume loop (`opencode run --continue`).
:::

## Agent Configuration

### API Key

Set via the `SFORGE_AGENT_API_KEY` environment variable. The harness maps this to the agent-specific env var (e.g., `ANTHROPIC_AUTH_TOKEN` for Claude Code, `CODEX_API_KEY` for Codex):

```bash
SFORGE_AGENT_API_KEY="sk-xxxx" sforge run --task ad_placement_optimization --agent claude-code
```

### API Endpoint

Set a custom API endpoint with `SFORGE_AGENT_API_BASE_URL` (for proxies or private deployments):

```bash
SFORGE_AGENT_API_BASE_URL="https://your-proxy.com/v1" \
SFORGE_AGENT_API_KEY="sk-xxxx" \
sforge run --task ad_placement_optimization --agent claude-code
```

### Model Override

Override the model using the `--model` CLI flag or the `SFORGE_AGENT_MODEL` environment variable:

```bash
sforge run --task ad_placement_optimization --agent claude-code --model claude-opus-4-8
```

### Reasoning Effort

Use `--effort` or `SFORGE_AGENT_EFFORT` to select `low`, `medium`, `high`, or
`max`. If neither is set, the Agent keeps its own default.

| Agent | Native setting | Notes |
|-------|----------------|-------|
| Claude Code | `CLAUDE_CODE_EFFORT_LEVEL` | Uses the selected value directly |
| Codex | `model_reasoning_effort` | Maps `max` to Codex's `xhigh` value |
| OpenCode | `reasoningEffort` | Applies to non-Anthropic providers; Anthropic providers retain their own thinking configuration |

### Extra Environment Variables

Pass additional environment variables to the agent container using `SFORGE_AGENT_EXTRA_ENV`:

```bash
SFORGE_AGENT_EXTRA_ENV="KEY1=VAL1,KEY2=VAL2" \
sforge run --task ad_placement_optimization --agent claude-code
```

## How Agents Work

The complete Agent lifecycle is:

1. **Create container**: create a Docker container from the Work image and inject environment variables such as API key and Judge URL
2. **Install Agent runtime**: run the Agent's `install_cmds` inside the container, such as installing Node.js or npm packages
3. **Install evaluation tools**:
   - `sforge-submit`: installed into `/usr/local/bin/`; the Agent calls this command to submit code
   - Stop Hook (optional): prevents the Agent from exiting too early
   - Auto-eval daemon (optional): periodically evaluates in the background
4. **Generate enhanced prompt**: combine the original task description with evaluation instructions and strategy suggestions
5. **Run Agent**: execute the Agent's `run_cmd`; the Agent starts working inside the container
6. **Collect results**: after the Agent times out or finishes, read the best score from the state file

During the process, the Agent can call `sforge-submit` at any time to submit code and receive feedback. The background auto-eval daemon also periodically submits evaluations.

## Stop Hook

Stop Hook is an important SForge mechanism that prevents the Agent from exiting too early.

### How It Works

When an Agent such as Claude Code decides the task is complete and tries to exit, the Stop Hook intercepts the exit request and returns a blocking signal asking the Agent to keep working. This ensures that the Agent can fully use the allocated time and continue improving the code.

### Supported Agents

| Agent | Hook Type | Description |
|-------|-----------|-------------|
| `claude-code` | Claude Code Stop Hook | Registered via `.claude/settings.json` |
| `codex` | Codex Stop Hook | Registered via `/etc/codex/hooks.json` |
| `opencode` | -- | No hook mechanism; early exits are covered by auto-resume |

### Disabling the Stop Hook

If you do not need Stop Hook, for example during debugging, disable it with `--disable-stop-hook`:

```bash
sforge run --task ad_placement_optimization --agent claude-code --disable-stop-hook
```

## Auto-Resume

Auto-resume handles **abnormal agent exits** (API disconnects, transient errors, etc.) that bypass the stop hook. When the agent process dies unexpectedly before the timeout, the harness automatically re-launches it using the agent's native session resume mechanism.

### How It Works

1. Agent exits abnormally (not due to timeout)
2. Harness detects the early exit
3. Agent is re-launched with its resume command (e.g., `claude --continue` for Claude Code)
4. The remaining timeout budget is passed to the resumed session
5. The agent picks up from its last conversation state and continues working

### Supported Agents

| Agent | Resume Mechanism |
|-------|------------------|
| `claude-code` | `claude --continue -p "Continue working."` |
| `codex` | `codex exec resume --last "Continue working."` |
| `opencode` | `opencode run --continue "Continue working."` |

### Safety Guards

- If the agent exits in **under 1 second**, the harness assumes a systematic failure and stops retrying
- Maximum of **100 resume attempts** per run

### Disabling Auto-Resume

```bash
sforge run --task ad_placement_optimization --agent claude-code --disable-auto-resume
```

## Using Third-Party Models

Both Claude Code and Codex support third-party models for evaluation — point `SFORGE_AGENT_API_BASE_URL` at a compatible API endpoint and set the model name with `--model`.

Claude Code has internal multi-tier model routing (opus/sonnet/haiku tiers, subagent calls) and context window management, so using it with a third-party model requires additional configuration for cache optimization, model routing variables, and context window settings. See [Single Task (Docker) — Using a Third-Party Model](/en/examples/single-task-docker#using-a-third-party-model) for details.

## Custom Agents

SForge currently supports one way to add a custom agent: implement it in the SForge source tree and register it in the agent factory. There is no separate runtime plugin/module loading path.

### Steps

1. Create a new file under `sforge/harness/agent/`, for example `my_agent.py`.
2. Define a class that extends `Agent` from `sforge.harness.agent.base`.
3. Set the required class attributes:
   - `name` -- CLI name used by `--agent`
   - `install_cmds` -- commands run inside the work container to install the agent runtime
   - `run_cmd` -- command template used to start the agent; it should read `{prompt_file}`
   - `api_key_env` -- environment variable expected by the agent for its API key
4. Optionally set `api_base_env`, `model_env`, `default_model`, `stop_hook`, and `resume_cmd`.
5. Register the class in `sforge/harness/agent/factory.py` by adding it to `_REGISTRY`.

Minimal example:

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

Then register it:

```python
from sforge.harness.agent.my_agent import MyAgent

_REGISTRY = {
    # ... existing agents ...
    "my-agent": MyAgent,
}
```

After registration, run it with:

```bash
SFORGE_AGENT_API_KEY="..." sforge run --task ad_placement_optimization --agent my-agent
```

If your agent needs custom environment mapping, command formatting, stop-hook installation, or resume behavior, override the corresponding methods on `Agent` such as `augment_env()`, `format_run_cmd()`, or `install_stop_hook()`.
