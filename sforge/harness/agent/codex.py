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
from sforge.harness.constants import CONTAINER_DIR


class CodexAgent(Agent):

    name = "codex"
    npm_package = "@openai/codex"
    default_version = "0.145.0"
    session_dirs = ("/root/.codex/sessions",)
    # Point codex at the configured gateway (container env carries the URL).
    provider_setup = '''if [ -n "$OPENAI_BASE_URL" ]; then
    mkdir -p /root/.codex
    cat > /root/.codex/config.toml << EOF
model_provider = "sforge-proxy"
model_verbosity = "medium"
model = "${CODEX_MODEL:-gpt-5.5}"

[model_providers.sforge-proxy]
name = "sforge-proxy"
base_url = "${OPENAI_BASE_URL}"
env_key = "OPENAI_API_KEY"
EOF
fi'''
    # --json: stdout is JSONL events, like Claude Code's stream-json.
    run_cmd = 'codex exec --json --dangerously-bypass-approvals-and-sandbox "$(cat {prompt_file})"'
    resume_cmd = 'codex exec resume --last --json --dangerously-bypass-approvals-and-sandbox "Continue working."'
    api_key_env = "OPENAI_API_KEY"
    api_base_env = "OPENAI_BASE_URL"
    default_api_base_url = "https://api.openai.com/v1"
    model_env = "CODEX_MODEL"
    stop_hook = "codex"

    def install(self, backend, handle, logger) -> None:
        super().install(backend, handle, logger)
        result = backend.exec_run(handle, ["/bin/bash", "-c", self.provider_setup])
        if result.exit_code != 0:
            raise RuntimeError(f"Failed to configure Codex provider: {result.output}")

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
        hook_path = f"{CONTAINER_DIR}/codex-stop-hook.sh"

        hook_script = _generate_codex_stop_hook()
        local_hook = log_dir / "_codex-stop-hook.sh"
        local_hook.write_text(hook_script)
        backend.copy_to_container(handle, local_hook, PurePosixPath(hook_path))
        backend.exec_run(handle, f"chmod a+x {hook_path}")
        logger.info("Installed Codex stop hook")

        hooks_content = _generate_codex_hooks(hook_path)
        local_hooks = log_dir / "_codex_hooks.json"
        local_hooks.write_text(hooks_content)
        backend.exec_run(handle, "mkdir -p /etc/codex")
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
            CONTAINER_DIR / "codex-config-append.toml",
        )

        enable_hooks_cmd = r"""
set -e
CONFIG=/root/.codex/config.toml
TMP=$(mktemp)
mkdir -p /root/.codex
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
    cat /opt/sforge/codex-config-append.toml >> "$TMP"
fi
mv "$TMP" "$CONFIG"
"""
        result = backend.exec_run(
            handle, ["/bin/bash", "-lc", enable_hooks_cmd],
        )
        if result.exit_code != 0:
            raise RuntimeError(f"Failed to configure Codex hooks: {result.output}")
        logger.info("Configured Codex hooks")


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
