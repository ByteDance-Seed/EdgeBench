#!/usr/bin/env python3
"""Starter training script for the Loco-RL benchmark.

Run training in the agent workspace and save submission/policy.pth before
submitting. The judge loads and evaluates the submitted checkpoint; it does not
run this script.
"""

from __future__ import annotations


def train() -> None:
    raise RuntimeError(
        "Implement training here, save submission/policy.pth, then run sebench-submit."
    )


if __name__ == "__main__":
    train()
