# Supported Agents

| Agent | `--agent` | Default release | Stop hook | Auto-resume |
|-------|-----------|-----------------|-----------|-------------|
| Claude Code | `claude-code` | 2.1.258 | Yes | Yes |
| Codex | `codex` | 0.145.0 | Yes | Yes |
| OpenCode | `opencode` | 1.18.2 | No | Yes |

Append `@<version>` to run another release, e.g. `--agent codex@0.130.0`; runs record the resolved `name@version`.

The agent CLI is not part of the task images. On first use SForge builds a bundle on the host (a pinned Node.js plus the npm package, cached in `~/.cache/sforge/agents`) and copies it into each work container, so containers need no network to install it. Building needs a Linux x86_64 host; `SFORGE_NODEJS_MIRROR_URL` and `npm_config_registry` set download mirrors.

## API Key, Model and Effort

```bash
SFORGE_AGENT_API_KEY="sk-..." \
sforge run --task ad_placement_optimization --agent claude-code \
  --model claude-opus-4-8 --effort high
```

Set `SFORGE_AGENT_API_BASE_URL` for an endpoint other than the agent's default. The key stays on the host: the agent talks to the judge server's LLM gateway, which adds the key and records token usage (`llm_requests.jsonl`, and `usage` in `final_result.json`).

`--effort` (`low`, `medium`, `high`, `max`) maps to `CLAUDE_CODE_EFFORT_LEVEL` for Claude Code, `model_reasoning_effort` for Codex (`max` becomes `xhigh`) and `reasoningEffort` for OpenCode (non-Anthropic providers only). Unset, each agent keeps its own default.

`SFORGE_AGENT_EXTRA_ENV="KEY1=VAL1,KEY2=VAL2"` passes extra variables into the work container.

## Third-Party Models

Point `SFORGE_AGENT_API_BASE_URL` at a compatible endpoint and set `--model`. Claude Code also needs its model-routing and context-window variables; see [Using a Third-Party Model](/en/examples/single-task-docker#using-a-third-party-model). For OpenCode, models are named `provider/model` (a bare name means `anthropic/<model>`).

## Stop Hook

When the agent decides it is done, the stop hook tells it to keep improving until the time budget runs out. Claude Code and Codex use their native hooks; OpenCode has none and relies on auto-resume. `--disable-stop-hook` turns it off, e.g. for debugging.

## Auto-Resume

If the agent exits before the timeout (an API disconnect, a crash), SForge relaunches it with its resume command (`claude --continue`, `codex exec resume --last`, `opencode run --continue`) and the remaining time. It gives up when the agent exits within one second or after 100 resumes. `--disable-auto-resume` turns it off.

## Custom Agents

Add a class under `sforge/harness/agent/` that extends `Agent`, and register it in `_REGISTRY` in `sforge/harness/agent/factory.py`:

```python
from sforge.harness.agent.base import Agent


class MyAgent(Agent):
    name = "my-agent"                 # the --agent name
    npm_package = "my-agent-cli"      # installed into the bundle
    default_version = "1.2.3"
    run_cmd = 'my-agent run --prompt "$(cat {prompt_file})"'
    resume_cmd = 'my-agent resume --prompt "Continue working."'
    api_key_env = "MY_AGENT_API_KEY"
    model_env = "MY_AGENT_MODEL"
```

Override `augment_env()`, `format_run_cmd()` or `install_stop_hook()` for agent-specific behaviour, and `install()` for an agent that is not distributed through npm.
