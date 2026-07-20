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

"""opencode agent — env-based config, model flag, permission handling.

opencode (npm ``opencode-ai``) differs from Claude Code in two ways that
matter to the harness:

* All configuration (default model, provider base URL, permissions) is
  passed via the ``OPENCODE_CONFIG_CONTENT`` env var instead of CLI flags
  or config files, so no container-side config install step is needed.
* There is no Stop-hook mechanism, so early exits are handled entirely by
  the harness auto-resume loop (``opencode run --continue``).
"""

from __future__ import annotations

import json
import shlex

from sforge.harness.agent.base import Agent

# Permission set used when the task runs without internet: web tools are
# denied outright so the model doesn't waste turns on blocked requests.
# ``deny`` rules are enforced even under ``--auto``.
_NO_INTERNET_PERMISSION = json.dumps(
    {"edit": "allow", "bash": "allow", "webfetch": "deny", "websearch": "deny"},
    separators=(",", ":"),
)


class OpenCodeAgent(Agent):

    name = "opencode"
    install_cmds = [
        "sudo -E bash -c 'NODE_MIRROR=${SFORGE_NODEJS_MIRROR_URL:-https://nodejs.org/dist} && curl -fsSL $NODE_MIRROR/v20.18.0/node-v20.18.0-linux-x64.tar.xz | tar -xJ -C /usr/local --strip-components=1'",
        "sudo -E npm install -g opencode-ai@1.18.2",
    ]
    run_cmd = 'opencode run --format json --auto "$(cat {prompt_file})"'
    resume_cmd = 'opencode run --continue --format json --auto "Continue working."'
    api_key_env = "ANTHROPIC_API_KEY"
    # opencode reads no base-URL env var; the base URL is embedded into
    # OPENCODE_CONFIG_CONTENT in augment_env().  default_api_base_url is
    # still needed for the network-isolation allowlist.
    default_api_base_url = "https://api.anthropic.com"

    def augment_env(self, env: dict[str, str], model: str | None) -> None:
        config = self._config
        qualified = _qualify_model(
            model or config.agent_model or self.default_model
        )

        cfg: dict = {
            "permission": {
                "edit": "allow",
                "bash": "allow",
                "webfetch": "allow",
            },
        }
        if qualified:
            # small_model too, or title generation falls back to an
            # Anthropic haiku model that third-party endpoints reject.
            cfg["model"] = qualified
            cfg["small_model"] = qualified

        provider_id, _, model_id = (qualified or "anthropic/").partition("/")
        provider_cfg: dict = {}
        if config.agent_api_base_url:
            provider_cfg["options"] = {
                "baseURL": _sdk_base_url(config.agent_api_base_url),
            }
        if model_id:
            # Declare the model so opencode accepts ids unknown to models.dev.
            provider_cfg["models"] = {model_id: {}}
        if provider_cfg:
            cfg["provider"] = {provider_id: provider_cfg}

        env.setdefault("OPENCODE_CONFIG_CONTENT", json.dumps(cfg))
        env.setdefault("OPENCODE_DISABLE_AUTOUPDATE", "1")
        env.setdefault("OPENCODE_DISABLE_LSP_DOWNLOAD", "1")

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

        qualified = _qualify_model(
            model or self._config.agent_model or self.default_model
        )
        if qualified:
            cmd += f" --model {shlex.quote(qualified)}"

        if not internet:
            # OPENCODE_PERMISSION overrides the config permissions;
            # OPENCODE_DISABLE_MODELS_FETCH stops the models.dev refresh
            # from stalling behind the network isolation.
            cmd = (
                f"OPENCODE_PERMISSION={shlex.quote(_NO_INTERNET_PERMISSION)}"
                " OPENCODE_DISABLE_MODELS_FETCH=1 " + cmd
            )

        return cmd


def _qualify_model(model: str | None) -> str | None:
    """opencode expects ``provider/model``; default bare names to anthropic."""
    if not model:
        return None
    return model if "/" in model else f"anthropic/{model}"


def _sdk_base_url(base_url: str) -> str:
    """SForge base URLs follow the Claude Code convention (no ``/v1``),
    while the AI SDK expects the versioned root it appends ``/messages`` to.
    """
    base = base_url.rstrip("/")
    return base if base.endswith("/v1") else f"{base}/v1"
