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

"""Claude Code agent — env augmentation, model flag, and stop hook."""

from __future__ import annotations

import json
import logging
import shlex
from pathlib import Path, PurePosixPath

from sforge.harness.agent.base import Agent
from sforge.harness.backend import ContainerBackend, ContainerHandle


class ClaudeCodeAgent(Agent):

    name = "claude-code"
    install_cmds = [
        "sudo -E bash -c 'NODE_MIRROR=${SFORGE_NODEJS_MIRROR_URL:-https://nodejs.org/dist} && curl -fsSL $NODE_MIRROR/v20.18.0/node-v20.18.0-linux-x64.tar.xz | tar -xJ -C /usr/local --strip-components=1'",
        "sudo -E npm install -g @anthropic-ai/claude-code@2.1.159",
    ]
    run_cmd = (
        'claude -p "$(cat {prompt_file})"'
        " --output-format stream-json"
        " --verbose"
        " --dangerously-skip-permissions"
    )
    resume_cmd = (
        'claude --continue -p "Continue working."'
        " --output-format stream-json"
        " --verbose"
        " --dangerously-skip-permissions"
    )
    api_key_env = "ANTHROPIC_AUTH_TOKEN"
    api_base_env = "ANTHROPIC_BASE_URL"
    default_api_base_url = "https://api.anthropic.com"
    model_env = "ANTHROPIC_MODEL"
    stop_hook = "claude"

    def augment_env(self, env: dict[str, str], model: str | None) -> None:
        if self._config.claude_cache_opt:
            env["CLAUDE_CODE_ATTRIBUTION_HEADER"] = "0"
        if not self._config.agent_api_base_url and self._config.agent_api_key:
            env["ANTHROPIC_API_KEY"] = self._config.agent_api_key
        # setdefault so an explicit extra_env value stays authoritative.
        if self._config.agent_effort:
            env.setdefault("CLAUDE_CODE_EFFORT_LEVEL", self._config.agent_effort)

    def format_run_cmd(
        self,
        prompt_path: str,
        *,
        model: str | None = None,
        cwd: str = "",
        internet: bool = True,
        resume: bool = False,
    ) -> str:
        cmd = super().format_run_cmd(
            prompt_path, model=model, cwd=cwd, internet=internet, resume=resume,
        )

        effective_model = (
            model or self._config.agent_model or self.default_model
        )
        if effective_model:
            cmd += f" --model {shlex.quote(effective_model)}"

        if not internet:
            cmd += " --disallowedTools WebSearch,WebFetch"

        if self._config.claude_cache_opt:
            cmd += (
                " --exclude-dynamic-system-prompt-sections"
                """ --settings '{"includeGitInstructions":false}'"""
            )

        return cmd

    def install_stop_hook(
        self,
        backend: ContainerBackend,
        handle: ContainerHandle,
        log_dir: Path,
        logger: logging.Logger,
    ) -> None:
        hook_path = "/tmp/sforge-stop-hook.sh"

        hook_script = _generate_stop_hook()
        local_hook = log_dir / "_stop-hook.sh"
        local_hook.write_text(hook_script)
        backend.copy_to_container(handle, local_hook, PurePosixPath(hook_path))
        backend.exec_run(handle, f"chmod a+x {hook_path}", user="root")
        logger.info("Installed Claude Code stop hook")

        settings_content = _generate_claude_settings(hook_path)
        local_settings = log_dir / "_claude_settings.json"
        local_settings.write_text(settings_content)
        backend.copy_to_container(
            handle,
            local_settings,
            PurePosixPath("/home/agent/.claude/settings.json"),
        )
        result = backend.exec_run(
            handle, "chown -R agent:agent /home/agent/.claude", user="root",
        )
        if result.exit_code != 0:
            raise RuntimeError(
                f"Failed to set Claude Code config ownership: {result.output}"
            )
        logger.info("Configured Claude Code settings with hooks")


class ClaudeCode2_1_214Agent(ClaudeCodeAgent):
    """Claude Code pinned to 2.1.214 — required by Claude 5-family models
    (Fable/Mythos); the 2.1.159 pin predates them. Kept as a separate agent
    so existing claude-code results stay comparable."""

    name = "claude-code-2.1.214"
    install_cmds = [
        ClaudeCodeAgent.install_cmds[0],
        "sudo -E npm install -g @anthropic-ai/claude-code@2.1.214",
    ]


# ---------------------------------------------------------------------------
# Script generators (private to this module)
# ---------------------------------------------------------------------------


def _generate_stop_hook() -> str:
    return r"""#!/bin/bash
cat >/dev/null
echo '{"decision":"block","reason":"Do not stop. Continue working on the implementation."}'
"""


def _generate_claude_settings(hook_path: str) -> str:
    settings: dict = {
        "hooks": {
            "Stop": [
                {
                    "hooks": [
                        {
                            "type": "command",
                            "command": hook_path,
                        }
                    ]
                }
            ],
        }
    }
    return json.dumps(settings, indent=2)
