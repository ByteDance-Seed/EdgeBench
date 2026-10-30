#!/usr/bin/env python3
import random
import warnings
warnings.filterwarnings("ignore")

from nle.nethack import (
    ACTIONS, CompassDirection, CompassDirectionLonger,
    MiscDirection, MiscAction, Command,
)

_ACTIONS_LIST = list(ACTIONS)

def _idx(key_code):
    try:
        return _ACTIONS_LIST.index(key_code)
    except ValueError:
        return 0

N = _idx(CompassDirection.N)
E = _idx(CompassDirection.E)
S = _idx(CompassDirection.S)
W = _idx(CompassDirection.W)
NE = _idx(CompassDirection.NE)
SE = _idx(CompassDirection.SE)
SW = _idx(CompassDirection.SW)
NW = _idx(CompassDirection.NW)
WAIT = _idx(MiscDirection.WAIT)
MORE = _idx(MiscAction.MORE)
UP = _idx(MiscDirection.UP)
DOWN = _idx(MiscDirection.DOWN)
KICK = _idx(Command.KICK)
PICKUP = _idx(Command.PICKUP)
OPEN = _idx(Command.OPEN)
CLOSE = _idx(Command.CLOSE)
EAT = _idx(Command.EAT)
SEARCH = _idx(Command.SEARCH)
PRAY = _idx(Command.PRAY)
APPLY = _idx(Command.APPLY)
ZAP = _idx(Command.ZAP)
THROW = _idx(Command.THROW)
FIRE = _idx(Command.FIRE)
DROP = _idx(Command.DROP)
WIELD = _idx(Command.WIELD)
WEAR = _idx(Command.WEAR)
TAKEOFF = _idx(Command.TAKEOFF)
READ = _idx(Command.READ)
QUAFF = _idx(Command.QUAFF)
INVENTORY = _idx(Command.INVENTORY)
ESC = _idx(Command.ESC)

def get_action(obs, info, step):
    if random.random() < 0.1:
        return SEARCH
    return random.choice([N, S, E, W, WAIT, PICKUP, OPEN, EAT])

if __name__ == "__main__":
    import argparse, gymnasium as gym, nle, numpy as np
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed", type=int, default=0)
    parser.add_argument("--max-steps", type=int, default=5000)
    args = parser.parse_args()
    random.seed(args.seed)
    env = gym.make("NetHackChallenge-v0")
    try:
        env.seed(args.seed)
    except Exception:
        pass
    obs, info = env.reset(), {}
    if isinstance(obs, tuple):
        obs, info = obs[0], obs[1] if len(obs) > 1 else {}
    for step in range(args.max_steps):
        action = get_action(obs, info, step)
        result = env.step(action)
        if len(result) == 5:
            obs, reward, terminated, truncated, info = result
            done = terminated or truncated
        else:
            obs, reward, done, info = result
        if done:
            break
    env.close()
