"""Default policy interface for Loco-RL submissions.

You may replace this module with any PyTorch architecture. The judge supports
three hooks, in priority order:

1. load_policy(path) -> nn.Module
2. build_policy(checkpoint) -> nn.Module
3. Policy class plus checkpoint state_dict

The returned module should implement get_deterministic_action(obs), act(obs),
or forward(obs), producing a 4D action in [-1, 1].
"""

from __future__ import annotations

import torch
import torch.nn as nn


class Policy(nn.Module):
    def __init__(self, obs_dim: int = 24, action_dim: int = 4, hidden_dim: int = 64):
        super().__init__()
        self.obs_dim = obs_dim
        self.action_dim = action_dim
        self.hidden_dim = hidden_dim
        self.actor = nn.Sequential(
            nn.Linear(obs_dim, hidden_dim),
            nn.Tanh(),
            nn.Linear(hidden_dim, hidden_dim),
            nn.Tanh(),
            nn.Linear(hidden_dim, action_dim),
            nn.Tanh(),
        )

    def forward(self, obs: torch.Tensor) -> torch.Tensor:
        return self.actor(obs).clamp(-1.0, 1.0)

    def get_deterministic_action(self, obs: torch.Tensor) -> torch.Tensor:
        return self.forward(obs)


def build_policy(checkpoint):
    hidden_dim = 64
    if isinstance(checkpoint, dict):
        hidden_dim = int(checkpoint.get("hidden_dim", hidden_dim))
    return Policy(hidden_dim=hidden_dim)
