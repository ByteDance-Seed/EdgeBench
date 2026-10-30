"""
Baseline PPO implementation for BipedalWalker-v3.

Deliberately weak: single environment, tiny network (hidden_dim=32),
bad hyperparameters (lr=1e-4, gamma=0.9, n_steps=128, batch_size=32).
Trains for exactly 200,000 environment steps.
"""

import os
import math
import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim
from torch.distributions import Normal
import gymnasium as gym

# ── Constants ────────────────────────────────────────────────────────────────
ENV_ID = "BipedalWalker-v3"
TOTAL_STEPS = 200_000
HIDDEN_DIM = 32          # deliberately tiny
LEARNING_RATE = 1e-4     # too small
GAMMA = 0.90             # too low (ignores future too much)
GAE_LAMBDA = 0.95
N_STEPS = 128            # rollout length per update
BATCH_SIZE = 32          # mini-batch size
N_EPOCHS = 4             # PPO epochs per update
CLIP_EPS = 0.2
VALUE_COEF = 0.5
ENTROPY_COEF = 0.01
MAX_GRAD_NORM = 0.5
SEED = 42


# ── Policy Network ────────────────────────────────────────────────────────────
class Policy(nn.Module):
    """
    Actor-Critic MLP.
    obs_dim=24, action_dim=4, hidden_dim configurable (baseline uses 32).
    """
    def __init__(self, obs_dim: int = 24, action_dim: int = 4, hidden_dim: int = 64):
        super().__init__()
        self.obs_dim = obs_dim
        self.action_dim = action_dim
        self.hidden_dim = hidden_dim

        # Actor
        self.actor = nn.Sequential(
            nn.Linear(obs_dim, hidden_dim),
            nn.Tanh(),
            nn.Linear(hidden_dim, hidden_dim),
            nn.Tanh(),
            nn.Linear(hidden_dim, action_dim),
            nn.Tanh(),
        )
        self.log_std = nn.Parameter(torch.zeros(action_dim))

        # Critic
        self.critic = nn.Sequential(
            nn.Linear(obs_dim, hidden_dim),
            nn.Tanh(),
            nn.Linear(hidden_dim, hidden_dim),
            nn.Tanh(),
            nn.Linear(hidden_dim, 1),
        )

        # Orthogonal init
        for m in self.modules():
            if isinstance(m, nn.Linear):
                nn.init.orthogonal_(m.weight, gain=math.sqrt(2))
                nn.init.zeros_(m.bias)
        # smaller gain for action head
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

    def evaluate_action(self, obs: torch.Tensor, action: torch.Tensor):
        """Returns (log_prob, value, entropy) for given obs-action pairs."""
        action_mean = self.actor(obs)
        std = self.log_std.exp().expand_as(action_mean)
        dist = Normal(action_mean, std)
        log_prob = dist.log_prob(action).sum(-1)
        entropy = dist.entropy().sum(-1)
        value = self.critic(obs).squeeze(-1)
        return log_prob, value, entropy

    def get_value(self, obs: torch.Tensor):
        return self.critic(obs).squeeze(-1)


# ── PPO Trainer ───────────────────────────────────────────────────────────────
class PPOBuffer:
    """Simple rollout buffer for single environment."""
    def __init__(self, n_steps: int, obs_dim: int, action_dim: int):
        self.n_steps = n_steps
        self.obs = np.zeros((n_steps, obs_dim), dtype=np.float32)
        self.actions = np.zeros((n_steps, action_dim), dtype=np.float32)
        self.rewards = np.zeros(n_steps, dtype=np.float32)
        self.values = np.zeros(n_steps, dtype=np.float32)
        self.log_probs = np.zeros(n_steps, dtype=np.float32)
        self.dones = np.zeros(n_steps, dtype=np.float32)
        self.ptr = 0

    def add(self, obs, action, reward, value, log_prob, done):
        self.obs[self.ptr] = obs
        self.actions[self.ptr] = action
        self.rewards[self.ptr] = reward
        self.values[self.ptr] = value
        self.log_probs[self.ptr] = log_prob
        self.dones[self.ptr] = float(done)
        self.ptr += 1

    def full(self):
        return self.ptr >= self.n_steps

    def reset(self):
        self.ptr = 0

    def compute_returns(self, last_value: float, gamma: float, gae_lambda: float):
        """Compute GAE advantages and returns."""
        advantages = np.zeros(self.n_steps, dtype=np.float32)
        last_gae = 0.0
        for t in reversed(range(self.n_steps)):
            if t == self.n_steps - 1:
                next_non_terminal = 1.0 - self.dones[t]
                next_value = last_value
            else:
                next_non_terminal = 1.0 - self.dones[t + 1]
                next_value = self.values[t + 1]
            delta = self.rewards[t] + gamma * next_value * next_non_terminal - self.values[t]
            last_gae = delta + gamma * gae_lambda * next_non_terminal * last_gae
            advantages[t] = last_gae
        returns = advantages + self.values
        return advantages, returns


def train():
    torch.manual_seed(SEED)
    np.random.seed(SEED)

    env = gym.make(ENV_ID, render_mode=None)
    env.reset(seed=SEED)

    obs_dim = env.observation_space.shape[0]   # 24
    action_dim = env.action_space.shape[0]     # 4

    policy = Policy(obs_dim=obs_dim, action_dim=action_dim, hidden_dim=HIDDEN_DIM)
    optimizer = optim.Adam(policy.parameters(), lr=LEARNING_RATE)

    buffer = PPOBuffer(N_STEPS, obs_dim, action_dim)

    obs, _ = env.reset()
    episode_reward = 0.0
    episode_rewards = []
    total_steps = 0
    n_updates = 0

    print(f"Baseline PPO training on {ENV_ID}")
    print(f"  hidden_dim={HIDDEN_DIM}, lr={LEARNING_RATE}, gamma={GAMMA}")
    print(f"  total_steps={TOTAL_STEPS}, n_steps={N_STEPS}, batch_size={BATCH_SIZE}")

    while total_steps < TOTAL_STEPS:
        # ── Collect rollout ──────────────────────────────────────────────────
        buffer.reset()
        while not buffer.full():
            obs_t = torch.FloatTensor(obs).unsqueeze(0)
            with torch.no_grad():
                action, log_prob, value = policy.get_action(obs_t)
            action_np = action.squeeze(0).numpy()
            log_prob_np = log_prob.item()
            value_np = value.item()

            next_obs, reward, terminated, truncated, _ = env.step(action_np)
            done = terminated or truncated

            buffer.add(obs, action_np, reward, value_np, log_prob_np, done)
            obs = next_obs
            episode_reward += reward
            total_steps += 1

            if done:
                episode_rewards.append(episode_reward)
                episode_reward = 0.0
                obs, _ = env.reset()

        # Bootstrap value for GAE
        obs_t = torch.FloatTensor(obs).unsqueeze(0)
        with torch.no_grad():
            last_value = policy.get_value(obs_t).item()

        advantages, returns = buffer.compute_returns(last_value, GAMMA, GAE_LAMBDA)

        # Normalize advantages
        adv_mean, adv_std = advantages.mean(), advantages.std() + 1e-8
        advantages = (advantages - adv_mean) / adv_std

        # Convert to tensors
        b_obs = torch.FloatTensor(buffer.obs)
        b_actions = torch.FloatTensor(buffer.actions)
        b_log_probs = torch.FloatTensor(buffer.log_probs)
        b_advantages = torch.FloatTensor(advantages)
        b_returns = torch.FloatTensor(returns)

        # ── PPO update ───────────────────────────────────────────────────────
        indices = np.arange(N_STEPS)
        for _ in range(N_EPOCHS):
            np.random.shuffle(indices)
            for start in range(0, N_STEPS, BATCH_SIZE):
                end = start + BATCH_SIZE
                mb_idx = indices[start:end]

                new_log_probs, values, entropy = policy.evaluate_action(
                    b_obs[mb_idx], b_actions[mb_idx]
                )

                ratio = (new_log_probs - b_log_probs[mb_idx]).exp()
                mb_adv = b_advantages[mb_idx]

                # Policy loss (clipped PPO)
                loss_pi = -torch.min(
                    ratio * mb_adv,
                    ratio.clamp(1 - CLIP_EPS, 1 + CLIP_EPS) * mb_adv
                ).mean()

                # Value loss
                loss_v = 0.5 * (values - b_returns[mb_idx]).pow(2).mean()

                # Entropy bonus
                loss_ent = -entropy.mean()

                loss = loss_pi + VALUE_COEF * loss_v + ENTROPY_COEF * loss_ent

                optimizer.zero_grad()
                loss.backward()
                nn.utils.clip_grad_norm_(policy.parameters(), MAX_GRAD_NORM)
                optimizer.step()

        n_updates += 1

        # Progress logging every 10k steps
        if total_steps % 10_000 < N_STEPS and len(episode_rewards) > 0:
            avg_r = np.mean(episode_rewards[-20:]) if len(episode_rewards) >= 20 else np.mean(episode_rewards)
            print(f"Step {total_steps}: avg_reward={avg_r:.2f}")

    env.close()

    # Final progress print
    if episode_rewards:
        avg_r = np.mean(episode_rewards[-20:])
        print(f"Step {total_steps}: avg_reward={avg_r:.2f} (final)")
    print(f"Training complete. {n_updates} updates, {total_steps} steps.")

    # ── Save checkpoint ───────────────────────────────────────────────────────
    os.makedirs("submission", exist_ok=True)
    checkpoint = {
        "state_dict": policy.state_dict(),
        "obs_dim": obs_dim,
        "action_dim": action_dim,
        "hidden_dim": HIDDEN_DIM,
    }
    torch.save(checkpoint, "submission/policy.pth")
    print("Checkpoint saved to submission/policy.pth")
    return policy


if __name__ == "__main__":
    train()
