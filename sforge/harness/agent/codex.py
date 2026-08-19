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

"""Codex agent — internet blocking and stop hook."""

from __future__ import annotations

import json
import logging
from pathlib import Path, PurePosixPath

from sforge.harness.agent.base import Agent
from sforge.harness.backend import ContainerBackend, ContainerHandle


class CodexAgent(Agent):

    name = "codex"
    install_cmds = [
        "sudo -E bash -c 'NODE_MIRROR=${SFORGE_NODEJS_MIRROR_URL:-https://nodejs.org/dist} && curl -fsSL $NODE_MIRROR/v20.18.0/node-v20.18.0-linux-x64.tar.xz | tar -xJ -C /usr/local --strip-components=1'",
        "sudo -E npm install -g @openai/codex@0.130.0",
        '''if [ -n "$OPENAI_BASE_URL" ]; then
    mkdir -p ~/.codex
    cat > ~/.codex/config.toml << EOF
model_provider = "sforge-proxy"
model_verbosity = "medium"
model = "${CODEX_MODEL:-gpt-5.5}"

[model_providers.sforge-proxy]
name = "sforge-proxy"
base_url = "${OPENAI_BASE_URL}"
env_key = "OPENAI_API_KEY"
EOF
fi''',
    ]
    run_cmd = 'codex exec --dangerously-bypass-approvals-and-sandbox "$(cat {prompt_file})"'
    resume_cmd = 'codex exec resume --last --dangerously-bypass-approvals-and-sandbox "Continue working."'
    api_key_env = "OPENAI_API_KEY"
    api_base_env = "OPENAI_BASE_URL"
    default_api_base_url = "https://api.openai.com"
    model_env = "CODEX_MODEL"
    stop_hook = "codex"

    def augment_env(self, env: dict[str, str], model: str | None) -> None:
        if not self._config.agent_api_base_url:
            if "OPENAI_API_KEY" in env and "CODEX_API_KEY" not in env:
                env["CODEX_API_KEY"] = env["OPENAI_API_KEY"]

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

        effort = self._config.agent_effort
        if effort:
            # codex vocabulary tops out at "xhigh" where ours says "max".
            effort = {"max": "xhigh"}.get(effort, effort)
            cmd = cmd.replace(
                "codex exec", f'codex exec -c model_reasoning_effort="{effort}"', 1,
            )

        if not internet:
            cmd = cmd.replace(
                "codex exec", 'codex exec -c web_search="disabled"', 1,
            )

        return cmd

    def install_stop_hook(
        self,
        backend: ContainerBackend,
        handle: ContainerHandle,
        log_dir: Path,
        logger: logging.Logger,
    ) -> None:
        hook_path = "/tmp/sforge-codex-stop-hook.sh"

        hook_script = _generate_codex_stop_hook()
        local_hook = log_dir / "_codex-stop-hook.sh"
        local_hook.write_text(hook_script)
        backend.copy_to_container(handle, local_hook, PurePosixPath(hook_path))
        backend.exec_run(handle, f"chmod a+x {hook_path}", user="root")
        logger.info("Installed Codex stop hook")

        hooks_content = _generate_codex_hooks(hook_path)
        local_hooks = log_dir / "_codex_hooks.json"
        local_hooks.write_text(hooks_content)
        backend.exec_run(handle, "mkdir -p /etc/codex", user="root")
        backend.copy_to_container(
            handle,
            local_hooks,
            PurePosixPath("/etc/codex/hooks.json"),
        )

        config_append = _generate_codex_config_append()
        local_config_append = log_dir / "_codex_config_append.toml"
        local_config_append.write_text(config_append)
        backend.copy_to_container(
            handle,
            local_config_append,
            PurePosixPath("/tmp/sforge-codex-config-append.toml"),
        )

        enable_hooks_cmd = r"""
set -e
CONFIG=/home/agent/.codex/config.toml
TMP=$(mktemp)
mkdir -p /home/agent/.codex
touch "$CONFIG"
if grep -Eq '^[[:space:]]*hooks[[:space:]]*=' "$CONFIG"; then
    sed -E 's/^[[:space:]]*hooks[[:space:]]*=.*/hooks = true/' "$CONFIG" > "$TMP"
elif grep -Eq '^[[:space:]]*\[features\][[:space:]]*$' "$CONFIG"; then
    awk '
        /^[[:space:]]*\[features\][[:space:]]*$/ {
            print
            print "hooks = true"
            next
        }
        { print }
    ' "$CONFIG" > "$TMP"
else
    cp "$CONFIG" "$TMP"
    cat /tmp/sforge-codex-config-append.toml >> "$TMP"
fi
mv "$TMP" "$CONFIG"
chown -R agent:agent /home/agent/.codex
"""
        result = backend.exec_run(
            handle, ["/bin/bash", "-lc", enable_hooks_cmd], user="root",
        )
        if result.exit_code != 0:
            raise RuntimeError(f"Failed to configure Codex hooks: {result.output}")
        logger.info("Configured Codex hooks")


class Codex0_145_0Agent(CodexAgent):
    """Codex pinned to 0.145.0. Kept as a separate agent so existing
    codex (0.130.0) results stay comparable."""

    name = "codex-0.145.0"
    install_cmds = [
        CodexAgent.install_cmds[0],
        "sudo -E npm install -g @openai/codex@0.145.0",
        CodexAgent.install_cmds[2],
    ]


# ---------------------------------------------------------------------------
# Script generators (private to this module)
# ---------------------------------------------------------------------------


def _generate_codex_stop_hook() -> str:
    return r"""#!/bin/bash
cat >/dev/null
echo '{"decision":"block","reason":"Do not stop. Continue working on the implementation."}'
"""


def _generate_codex_hooks(hook_path: str) -> str:
    hooks: dict = {
        "hooks": {
            "Stop": [
                {
                    "hooks": [
                        {
                            "type": "command",
                            "command": hook_path,
                            "timeout": 30,
                            "statusMessage": "SForge stop hook",
                        }
                    ]
                }
            ],
        }
    }
    return json.dumps(hooks, indent=2)


def _generate_codex_config_append() -> str:
    return """\n[features]\nhooks = true\n"""
