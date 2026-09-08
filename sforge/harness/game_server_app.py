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

"""Lightweight game HTTP server that runs inside a judge container.

One container = one game session. The judge server on the host starts this
process, proxies agent requests to it, and tears down the container on close.

Usage:
    python -m sforge.harness.game_server_app --rom /path/to/game.z4 --port 8000
"""

from __future__ import annotations

import argparse
import hmac
import os
import sys
import threading

import uvicorn
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel

try:
    import jericho
except ImportError:
    print("ERROR: jericho is not installed", file=sys.stderr)
    sys.exit(1)


class NewGameRequest(BaseModel):
    pass


class StepRequest(BaseModel):
    action: str


class GameResponse(BaseModel):
    observation: str
    score: int
    peak_score: int
    max_score: int
    done: bool
    moves: int


class CloseResponse(BaseModel):
    final_score: int
    peak_score: int
    max_score: int
    moves: int


class GameState:
    def __init__(self, rom_path: str) -> None:
        self.rom_path = rom_path
        self.env: jericho.FrotzEnv | None = None
        self.step_count = 0
        self.max_score = 0
        self.peak_score = 0
        self.current_score = 0
        self.done = False
        self.lock = threading.Lock()


def create_app(rom_path: str) -> FastAPI:
    app = FastAPI(title="SForge Game Server (Container)")
    state = GameState(rom_path)

    # On backends where this port is exposed through a public gateway (e2b),
    # only the judge server knows the per-session token it set in our env.
    token = os.environ.get("SFORGE_GAME_TOKEN", "")
    if token:
        @app.middleware("http")
        async def require_token(request: Request, call_next):
            got = request.headers.get("x-sforge-game-token", "")
            if not hmac.compare_digest(got, token):
                return JSONResponse({"detail": "unauthorized"}, status_code=401)
            return await call_next(request)

    @app.get("/health")
    def health() -> dict:
        return {"ok": True}

    @app.post("/new")
    def new_game(req: NewGameRequest) -> GameResponse:
        with state.lock:
            if state.env is not None:
                try:
                    state.env.close()
                except Exception:
                    pass
            state.env = jericho.FrotzEnv(state.rom_path)
            obs, _info = state.env.reset()
            state.step_count = 0
            state.max_score = int(state.env.get_max_score() or 0)
            state.peak_score = 0
            state.current_score = 0
            state.done = False
        return GameResponse(
            observation=obs,
            score=0,
            peak_score=0,
            max_score=state.max_score,
            done=False,
            moves=0,
        )

    @app.post("/step")
    def step(req: StepRequest) -> GameResponse:
        with state.lock:
            if state.env is None:
                raise HTTPException(400, "No active game — call /new first")
            if state.done:
                raise HTTPException(400, "Game is already over")

            obs, reward, done, _info = state.env.step(req.action)
            state.step_count += 1
            state.current_score = state.env.get_score()
            state.peak_score = max(state.peak_score, state.current_score)

            if done:
                state.done = True

        return GameResponse(
            observation=obs,
            score=state.current_score,
            peak_score=state.peak_score,
            max_score=state.max_score,
            done=state.done,
            moves=state.step_count,
        )

    @app.get("/status")
    def status() -> GameResponse:
        with state.lock:
            return GameResponse(
                observation="",
                score=state.current_score,
                peak_score=state.peak_score,
                max_score=state.max_score,
                done=state.done,
                moves=state.step_count,
            )

    @app.post("/close")
    def close() -> CloseResponse:
        with state.lock:
            final = state.current_score
            peak = state.peak_score
            cap = state.max_score
            moves = state.step_count
            if state.env is not None:
                try:
                    state.env.close()
                except Exception:
                    pass
                state.env = None
            state.done = True
        return CloseResponse(final_score=final, peak_score=peak, max_score=cap, moves=moves)

    return app


def main() -> None:
    parser = argparse.ArgumentParser(description="Container-side game server")
    parser.add_argument("--rom", required=True, help="Path to Z-machine ROM file")
    parser.add_argument("--port", type=int, default=8000)
    parser.add_argument("--host", default="0.0.0.0")
    args = parser.parse_args()

    app = create_app(args.rom)
    uvicorn.run(app, host=args.host, port=args.port, log_level="warning")


if __name__ == "__main__":
    main()
