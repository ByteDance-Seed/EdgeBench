"""
Environment utilities for Loco-RL benchmark.

Provides:
  - make_env(env_id, seed, render_mode)
  - make_vec_env(env_id, n_envs, seed)
  - NormalizeObsWrapper
  - get_env_info(env_id)
"""

import numpy as np
import gymnasium as gym
from gymnasium import Wrapper
from multiprocessing import Process, Pipe
from typing import Optional, List, Tuple


# ── Wrapper: Observation Normalization ────────────────────────────────────────

class NormalizeObsWrapper(Wrapper):
    """
    Normalizes observations using running mean and variance.
    Uses Welford's online algorithm. Thread-safe for single-process use.
    """

    def __init__(self, env: gym.Env, epsilon: float = 1e-8, clip: float = 10.0):
        super().__init__(env)
        self.epsilon = epsilon
        self.clip = clip
        obs_shape = env.observation_space.shape
        self.mean = np.zeros(obs_shape, dtype=np.float64)
        self.var = np.ones(obs_shape, dtype=np.float64)
        self.count = 0.0

    def _update_stats(self, obs: np.ndarray):
        """Update running mean and variance (Welford's)."""
        self.count += 1.0
        delta = obs - self.mean
        self.mean += delta / self.count
        delta2 = obs - self.mean
        self.var += delta * delta2  # sum of squared deviations

    def _normalize(self, obs: np.ndarray) -> np.ndarray:
        std = np.sqrt(self.var / max(self.count, 1.0) + self.epsilon)
        return np.clip((obs - self.mean) / std, -self.clip, self.clip).astype(np.float32)

    def reset(self, **kwargs):
        obs, info = self.env.reset(**kwargs)
        self._update_stats(obs)
        return self._normalize(obs), info

    def step(self, action):
        obs, reward, terminated, truncated, info = self.env.step(action)
        self._update_stats(obs)
        return self._normalize(obs), reward, terminated, truncated, info

    def get_stats(self) -> Tuple[np.ndarray, np.ndarray]:
        """Return (mean, std) for saving/restoring normalization state."""
        std = np.sqrt(self.var / max(self.count, 1.0) + self.epsilon)
        return self.mean.copy(), std

    def set_stats(self, mean: np.ndarray, std: np.ndarray):
        """Restore normalization state from saved mean/std."""
        self.mean = mean.copy().astype(np.float64)
        self.var = (std ** 2 - self.epsilon) * max(self.count, 1.0)
        self.var = np.maximum(self.var, 0.0)


# ── Wrapper: Time Limit ───────────────────────────────────────────────────────

class TimeLimitWrapper(Wrapper):
    """
    Truncates episodes at a maximum number of steps.
    Useful when the base environment does not enforce a time limit.
    """

    def __init__(self, env: gym.Env, max_steps: int = 1600):
        super().__init__(env)
        self.max_steps = max_steps
        self._step_count = 0

    def reset(self, **kwargs):
        self._step_count = 0
        return self.env.reset(**kwargs)

    def step(self, action):
        obs, reward, terminated, truncated, info = self.env.step(action)
        self._step_count += 1
        if self._step_count >= self.max_steps:
            truncated = True
        return obs, reward, terminated, truncated, info


# ── Single Environment Factory ─────────────────────────────────────────────────

def make_env(
    env_id: str = "BipedalWalker-v3",
    seed: int = 0,
    render_mode: Optional[str] = None,
    normalize_obs: bool = False,
) -> gym.Env:
    """
    Creates and wraps a single environment.

    Args:
        env_id: Gymnasium environment ID.
        seed: Random seed.
        render_mode: Render mode ('human', 'rgb_array', or None).
        normalize_obs: If True, wraps with NormalizeObsWrapper.

    Returns:
        Wrapped gymnasium environment.
    """
    env = gym.make(env_id, render_mode=render_mode)
    env.reset(seed=seed)
    env.action_space.seed(seed)
    if normalize_obs:
        env = NormalizeObsWrapper(env)
    return env


# ── Vectorized Environment (SubprocVecEnv) ─────────────────────────────────────

def _worker(conn, env_id: str, seed: int):
    """Worker process for SubprocVecEnv."""
    import gymnasium as gym
    import numpy as np

    env = gym.make(env_id, render_mode=None)
    env.reset(seed=seed)
    env.action_space.seed(seed)

    while True:
        cmd, data = conn.recv()
        if cmd == "reset":
            obs, info = env.reset()
            conn.send((obs, info))
        elif cmd == "step":
            obs, reward, terminated, truncated, info = env.step(data)
            done = terminated or truncated
            if done:
                obs, _ = env.reset()
            conn.send((obs, reward, done, terminated, truncated, info))
        elif cmd == "close":
            env.close()
            conn.close()
            break
        elif cmd == "get_spaces":
            conn.send((env.observation_space, env.action_space))
        else:
            raise RuntimeError(f"Unknown command: {cmd}")


class SubprocVecEnv:
    """
    Vectorized environment using subprocess parallelism.
    Runs N environments in separate processes, communicating via Pipes.

    Usage:
        vec_env = SubprocVecEnv(env_id="BipedalWalker-v3", n_envs=16, seed=0)
        obs = vec_env.reset()             # shape: (n_envs, obs_dim)
        obs, rewards, dones, infos = vec_env.step(actions)
        vec_env.close()
    """

    def __init__(self, env_id: str, n_envs: int, seed: int = 0):
        self.n_envs = n_envs
        self.env_id = env_id

        self.parent_conns, self.child_conns = zip(*[Pipe() for _ in range(n_envs)])
        self.procs = []
        for i in range(n_envs):
            p = Process(
                target=_worker,
                args=(self.child_conns[i], env_id, seed + i),
                daemon=True,
            )
            p.start()
            self.procs.append(p)

        # Get space info from first worker
        self.parent_conns[0].send(("get_spaces", None))
        obs_space, act_space = self.parent_conns[0].recv()
        self.observation_space = obs_space
        self.action_space = act_space
        self.obs_dim = obs_space.shape[0]
        self.action_dim = act_space.shape[0]

    def reset(self) -> np.ndarray:
        """Reset all environments. Returns obs array (n_envs, obs_dim)."""
        for conn in self.parent_conns:
            conn.send(("reset", None))
        results = [conn.recv() for conn in self.parent_conns]
        obs = np.stack([r[0] for r in results])
        return obs.astype(np.float32)

    def step(self, actions: np.ndarray):
        """
        Step all environments with given actions.
        actions: (n_envs, action_dim)
        Returns: obs, rewards, dones, infos
        """
        for conn, action in zip(self.parent_conns, actions):
            conn.send(("step", action))
        results = [conn.recv() for conn in self.parent_conns]
        obs = np.stack([r[0] for r in results]).astype(np.float32)
        rewards = np.array([r[1] for r in results], dtype=np.float32)
        dones = np.array([r[2] for r in results], dtype=bool)
        infos = [r[5] for r in results]
        return obs, rewards, dones, infos

    def close(self):
        for conn in self.parent_conns:
            conn.send(("close", None))
        for p in self.procs:
            p.join(timeout=5)

    def __del__(self):
        try:
            self.close()
        except Exception:
            pass


def make_vec_env(
    env_id: str = "BipedalWalker-v3",
    n_envs: int = 8,
    seed: int = 0,
) -> SubprocVecEnv:
    """
    Creates N parallel environments using multiprocessing.

    Args:
        env_id: Gymnasium environment ID.
        n_envs: Number of parallel environments.
        seed: Base seed (each env gets seed+i).

    Returns:
        SubprocVecEnv instance.
    """
    return SubprocVecEnv(env_id=env_id, n_envs=n_envs, seed=seed)


# ── Environment Info ───────────────────────────────────────────────────────────

ENV_INFO = {
    "BipedalWalker-v3": {
        "obs_dim": 24,
        "action_dim": 4,
        "episode_time_limit": 1600,
        "reward_threshold": 300.0,
        "random_baseline": -0.3,
        "description": "2D bipedal walking on flat terrain with hills",
    },
    "BipedalWalkerHardcore-v3": {
        "obs_dim": 24,
        "action_dim": 4,
        "episode_time_limit": 1600,
        "reward_threshold": 300.0,
        "random_baseline": -100.0,
        "description": "2D bipedal walking with obstacles (stumps, stairs, pitfalls)",
    },
}


def get_env_info(env_id: str) -> dict:
    """
    Returns environment metadata: obs_dim, action_dim, episode_time_limit, etc.

    Args:
        env_id: Gymnasium environment ID.

    Returns:
        dict with environment metadata.
    """
    if env_id in ENV_INFO:
        return ENV_INFO[env_id].copy()
    # Fall back: create env and query it
    env = gym.make(env_id, render_mode=None)
    info = {
        "obs_dim": env.observation_space.shape[0],
        "action_dim": env.action_space.shape[0],
        "episode_time_limit": getattr(env, "_max_episode_steps", 1600),
        "reward_threshold": None,
        "random_baseline": None,
        "description": env_id,
    }
    env.close()
    return info


if __name__ == "__main__":
    # Quick smoke tests
    print("Testing make_env...")
    env = make_env("BipedalWalker-v3", seed=0)
    obs, _ = env.reset()
    print(f"  obs shape: {obs.shape}")
    obs, r, term, trunc, _ = env.step(env.action_space.sample())
    print(f"  step reward: {r:.3f}")
    env.close()

    print("Testing NormalizeObsWrapper...")
    env = make_env("BipedalWalker-v3", seed=0, normalize_obs=True)
    obs, _ = env.reset()
    print(f"  normalized obs mean: {obs.mean():.3f}")
    env.close()

    print("Testing get_env_info...")
    info = get_env_info("BipedalWalker-v3")
    print(f"  {info}")

    print("Testing make_vec_env (n_envs=4)...")
    vec_env = make_vec_env("BipedalWalker-v3", n_envs=4, seed=0)
    obs = vec_env.reset()
    print(f"  vec obs shape: {obs.shape}")
    actions = np.random.uniform(-1, 1, (4, 4)).astype(np.float32)
    obs, rewards, dones, infos = vec_env.step(actions)
    print(f"  vec rewards: {rewards}")
    vec_env.close()

    print("All environment utility tests passed.")
