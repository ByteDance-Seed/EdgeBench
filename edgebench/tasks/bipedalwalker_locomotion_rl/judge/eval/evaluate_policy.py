"""
Policy evaluator for Loco-RL benchmark.

Usage:
    python evaluate_policy.py --policy <path_to_policy.pth> --env <env_id> \
        [--n_episodes 100] [--seed 0]

Loads a saved policy checkpoint and evaluates it over N episodes,
reporting mean/std/min/max episode reward.
"""

import os
import sys
import argparse
import importlib.util
import math
import numpy as np
import torch
import torch.nn as nn
from torch.distributions import Normal
import gymnasium as gym


# ── Policy definition (must match train_baseline.py) ─────────────────────────

class Policy(nn.Module):
    """
    Actor-Critic MLP. Flexible hidden_dim.
    """
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
        self.log_std = nn.Parameter(torch.zeros(action_dim))

        self.critic = nn.Sequential(
            nn.Linear(obs_dim, hidden_dim),
            nn.Tanh(),
            nn.Linear(hidden_dim, hidden_dim),
            nn.Tanh(),
            nn.Linear(hidden_dim, 1),
        )

        for m in self.modules():
            if isinstance(m, nn.Linear):
                nn.init.orthogonal_(m.weight, gain=math.sqrt(2))
                nn.init.zeros_(m.bias)
        nn.init.orthogonal_(self.actor[-2].weight, gain=0.01)

    def get_action(self, obs: torch.Tensor):
        """Returns (action, log_prob, value)."""
        action_mean = self.actor(obs)
        std = self.log_std.exp().expand_as(action_mean)
        dist = Normal(action_mean, std)
        action = dist.sample()
        action = action.clamp(-1.0, 1.0)
        log_prob = dist.log_prob(action).sum(-1)
        value = self.critic(obs).squeeze(-1)
        return action, log_prob, value

    def get_deterministic_action(self, obs: torch.Tensor) -> torch.Tensor:
        """Returns deterministic action (mean), clamped to [-1, 1]."""
        return self.actor(obs).clamp(-1.0, 1.0)

    def get_value(self, obs: torch.Tensor) -> torch.Tensor:
        return self.critic(obs).squeeze(-1)


# ── Checkpoint loading ─────────────────────────────────────────────────────────

def _submitted_policy_module():
    """Load optional submission/policy.py for custom architectures."""
    policy_py = os.path.join(os.path.dirname(os.path.dirname(__file__)), "submission", "policy.py")
    if not os.path.exists(policy_py):
        return None
    spec = importlib.util.spec_from_file_location("_sebench_submitted_policy", policy_py)
    if spec is None or spec.loader is None:
        raise ValueError("could not load submission/policy.py")
    module = importlib.util.module_from_spec(spec)
    sys.modules["_sebench_submitted_policy"] = module
    spec.loader.exec_module(module)
    return module


def _checkpoint_state_dict(checkpoint):
    if isinstance(checkpoint, dict) and "state_dict" in checkpoint:
        return checkpoint["state_dict"]
    if isinstance(checkpoint, dict):
        tensors = {k: v for k, v in checkpoint.items() if isinstance(v, torch.Tensor)}
        return tensors or None
    return None


def _build_custom_policy(module, checkpoint, path: str):
    """Instantiate a submitted policy module if it provides a supported hook."""
    if hasattr(module, "load_policy"):
        policy = module.load_policy(path)
        if not isinstance(policy, nn.Module):
            raise TypeError("submission.policy.load_policy(path) must return torch.nn.Module")
        policy.eval()
        return policy

    if hasattr(module, "build_policy"):
        policy = module.build_policy(checkpoint)
        if not isinstance(policy, nn.Module):
            raise TypeError("submission.policy.build_policy(checkpoint) must return torch.nn.Module")
        state_dict = _checkpoint_state_dict(checkpoint)
        if state_dict:
            policy.load_state_dict(state_dict, strict=False)
        policy.eval()
        return policy

    if hasattr(module, "Policy"):
        cls = module.Policy
        if isinstance(checkpoint, dict):
            kwargs = {
                "obs_dim": checkpoint.get("obs_dim", 24),
                "action_dim": checkpoint.get("action_dim", 4),
            }
            for key in ("hidden_dim", "hidden_sizes", "activation"):
                if key in checkpoint:
                    kwargs[key] = checkpoint[key]
        else:
            kwargs = {"obs_dim": 24, "action_dim": 4}
        try:
            policy = cls(**kwargs)
        except TypeError:
            policy = cls()
        state_dict = _checkpoint_state_dict(checkpoint)
        if state_dict:
            policy.load_state_dict(state_dict, strict=False)
        if not isinstance(policy, nn.Module):
            raise TypeError("submission.policy.Policy must be a torch.nn.Module")
        policy.eval()
        return policy

    raise ValueError(
        "submission/policy.py must define load_policy(path), build_policy(checkpoint), or Policy"
    )


def load_policy(path: str) -> Policy:
    """
    Load a policy from a checkpoint file.
    Supports arbitrary submitted architectures via submission/policy.py, with a
    backward-compatible fallback for the starter Policy checkpoint format.
    """
    checkpoint = torch.load(path, map_location="cpu", weights_only=False)

    custom = _submitted_policy_module()
    if custom is not None:
        return _build_custom_policy(custom, checkpoint, path)

    # Extract metadata
    if isinstance(checkpoint, dict) and "state_dict" in checkpoint:
        state_dict = checkpoint["state_dict"]
        obs_dim = checkpoint.get("obs_dim", 24)
        action_dim = checkpoint.get("action_dim", 4)
        hidden_dim = checkpoint.get("hidden_dim", 64)
    elif isinstance(checkpoint, dict):
        # Try to infer dimensions from weight shapes
        state_dict = checkpoint
        obs_dim = 24
        action_dim = 4
        # Try to infer hidden_dim
        hidden_dim = 64
        if "actor.0.weight" in state_dict:
            hidden_dim = state_dict["actor.0.weight"].shape[0]
    else:
        raise ValueError(f"Unexpected checkpoint format: {type(checkpoint)}")

    policy = Policy(obs_dim=obs_dim, action_dim=action_dim, hidden_dim=hidden_dim)
    # Fix common shape mismatches before loading
    fixed_sd = {}
    for k, v in state_dict.items():
        if k == "log_std" and v.dim() > 1:
            v = v.squeeze()           # [1,4] → [4]
        if k in dict(policy.named_parameters()):
            expected = dict(policy.named_parameters())[k].shape
            if v.shape == expected:
                fixed_sd[k] = v
            else:
                print(f"  Skipping {k}: shape {v.shape} != expected {expected}")
        else:
            fixed_sd[k] = v
    policy.load_state_dict(fixed_sd, strict=False)
    policy.eval()
    return policy


def _as_action_tensor(action) -> torch.Tensor:
    if isinstance(action, tuple):
        action = action[0]
    if isinstance(action, list):
        action = action[0] if len(action) == 1 and hasattr(action[0], "shape") else action
    if not isinstance(action, torch.Tensor):
        action = torch.as_tensor(action, dtype=torch.float32)
    action = action.detach().cpu().float()
    if action.ndim == 1:
        action = action.unsqueeze(0)
    return action[:, :4].clamp(-1.0, 1.0)


def deterministic_action(policy: nn.Module, obs: torch.Tensor) -> torch.Tensor:
    """Call a submitted policy using the supported deterministic-action hooks."""
    if hasattr(policy, "get_deterministic_action"):
        return _as_action_tensor(policy.get_deterministic_action(obs))
    if hasattr(policy, "act"):
        try:
            return _as_action_tensor(policy.act(obs, deterministic=True))
        except TypeError:
            return _as_action_tensor(policy.act(obs))
    return _as_action_tensor(policy(obs))


# ── Evaluation ─────────────────────────────────────────────────────────────────

def evaluate_policy(
    policy: Policy,
    env_id: str,
    n_episodes: int = 100,
    seed: int = 0,
    seeds: list[int] | None = None,
    deterministic: bool = True,
    verbose: bool = True,
) -> dict:
    """
    Evaluate a policy on the given environment.

    Returns dict with keys: mean_reward, std_reward, min_reward, max_reward.
    """
    env = gym.make(env_id, render_mode=None)
    episode_rewards = []

    episode_seeds = list(seeds) if seeds is not None else [seed + ep for ep in range(n_episodes)]
    n_episodes = len(episode_seeds)

    for ep, ep_seed in enumerate(episode_seeds):
        obs, _ = env.reset(seed=ep_seed)
        ep_reward = 0.0
        done = False
        while not done:
            obs_t = torch.FloatTensor(obs).unsqueeze(0)
            with torch.no_grad():
                if deterministic:
                    action = deterministic_action(policy, obs_t)
                else:
                    action, _, _ = policy.get_action(obs_t)
            action_np = action.squeeze(0).numpy()
            obs, reward, terminated, truncated, _ = env.step(action_np)
            ep_reward += reward
            done = terminated or truncated
        episode_rewards.append(ep_reward)
        if verbose and (ep + 1) % 10 == 0:
            print(f"  Episode {ep + 1}/{n_episodes}: reward={ep_reward:.2f}")

    env.close()

    results = {
        "mean_reward": float(np.mean(episode_rewards)),
        "std_reward": float(np.std(episode_rewards)),
        "min_reward": float(np.min(episode_rewards)),
        "max_reward": float(np.max(episode_rewards)),
        "n_episodes": n_episodes,
        "env_id": env_id,
        "episode_rewards": episode_rewards,
    }
    return results


def print_results(results: dict):
    print(f"mean_reward={results['mean_reward']:.2f}, "
          f"std_reward={results['std_reward']:.2f}, "
          f"min_reward={results['min_reward']:.2f}, "
          f"max_reward={results['max_reward']:.2f}")


# ── CLI ───────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Evaluate a saved policy checkpoint.")
    parser.add_argument("--policy", required=True, help="Path to policy.pth checkpoint")
    parser.add_argument("--env", default="BipedalWalker-v3",
                        choices=["BipedalWalker-v3", "BipedalWalkerHardcore-v3"],
                        help="Environment to evaluate on")
    parser.add_argument("--n_episodes", type=int, default=100, help="Number of evaluation episodes")
    parser.add_argument("--seed", type=int, default=0, help="Random seed (base)")
    parser.add_argument("--seeds", default="", help="Comma-separated explicit episode seeds")
    parser.add_argument("--stochastic", action="store_true",
                        help="Use stochastic policy (default: deterministic)")
    parser.add_argument("--verbose", action="store_true", help="Print per-episode results")
    args = parser.parse_args()

    if not os.path.exists(args.policy):
        print(f"ERROR: Policy file not found: {args.policy}")
        sys.exit(1)

    print(f"Loading policy from {args.policy}...")
    policy = load_policy(args.policy)
    print(f"  Policy: obs_dim={policy.obs_dim}, action_dim={policy.action_dim}, hidden_dim={policy.hidden_dim}")

    explicit_seeds = None
    if args.seeds.strip():
        explicit_seeds = [int(chunk.strip()) for chunk in args.seeds.split(",") if chunk.strip()]
        if not explicit_seeds:
            print("ERROR: --seeds was provided but no valid integer seeds were parsed")
            sys.exit(2)

    episode_count = len(explicit_seeds) if explicit_seeds is not None else args.n_episodes
    print(f"Evaluating on {args.env} ({episode_count} episodes)...")
    results = evaluate_policy(
        policy=policy,
        env_id=args.env,
        n_episodes=args.n_episodes,
        seed=args.seed,
        seeds=explicit_seeds,
        deterministic=not args.stochastic,
        verbose=args.verbose,
    )
    print_results(results)


if __name__ == "__main__":
    main()
