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

"""Agent factory and registry."""

from __future__ import annotations

from sforge.harness.agent.base import Agent
from sforge.harness.config import SForgeConfig

from sforge.harness.agent.claude_code import ClaudeCode2_1_214Agent, ClaudeCodeAgent
from sforge.harness.agent.codex import CodexAgent
from sforge.harness.agent.opencode import OpenCodeAgent

# ---------------------------------------------------------------------------
# Registry: name → agent class
# ---------------------------------------------------------------------------

_REGISTRY: dict[str, type[Agent]] = {
    "claude-code": ClaudeCodeAgent,
    "claude-code-2.1.214": ClaudeCode2_1_214Agent,
    "codex": CodexAgent,
    "opencode": OpenCodeAgent,
}


# ---------------------------------------------------------------------------
# Lookup helpers
# ---------------------------------------------------------------------------


def get_agent_class(name: str) -> type[Agent]:
    """Look up an agent class by name.  Raises :class:`ValueError` if not found."""
    if name not in _REGISTRY:
        available = ", ".join(sorted(_REGISTRY.keys()))
        raise ValueError(f"Unknown agent: {name!r}. Available: {available}")
    return _REGISTRY[name]


def list_agent_classes() -> list[type[Agent]]:
    """Return all registered agent classes."""
    return list(_REGISTRY.values())


# ---------------------------------------------------------------------------
# Factory
# ---------------------------------------------------------------------------


def create_agent(name: str, config: SForgeConfig) -> Agent:
    """Create an :class:`Agent` instance for the named agent."""
    cls = get_agent_class(name)
    return cls(config)
