from __future__ import annotations

import json
from pathlib import Path
from types import SimpleNamespace
import threading
import time
from unittest.mock import patch

from sforge.harness.judge_server import GameSessionState, JudgeState


class FakeBackend:
    backend_name = "docker"

    def cleanup_container(self, container, logger):
        return None


class FakeResponse:
    def __init__(self, value):
        self.value = value

    def raise_for_status(self):
        return None

    def json(self):
        return self.value


def bare_state(tmp_path: Path) -> JudgeState:
    state = object.__new__(JudgeState)
    state.config = SimpleNamespace(log_dir=tmp_path)
    state.game_sessions = {}
    state.game_counters = {}
    state.run_history = {}
    state._game_lock = threading.Lock()
    state._history_lock = threading.Lock()
    state._get_backend = lambda run_id, task_id: FakeBackend()
    return state


def session(session_id: str, game_num: int = 1) -> GameSessionState:
    return GameSessionState(
        session_id=session_id,
        run_id="run-1",
        task_id="task-1",
        game_num=game_num,
        container=object(),
        container_url="http://game",
    )


def test_close_all_waits_for_inflight_step_before_archiving(tmp_path):
    state = bare_state(tmp_path)
    current = session("session-1")
    state.game_sessions[current.session_id] = current
    request_started = threading.Event()
    allow_response = threading.Event()

    def post(*args, **kwargs):
        request_started.set()
        assert allow_response.wait(5)
        return FakeResponse({
            "score": 13, "peak_score": 13, "max_score": 100,
            "moves": 98, "done": False, "observation": "after step",
        })

    with patch("sforge.harness.judge_server.requests.post", side_effect=post):
        step = threading.Thread(target=state.game_step, args=(current.session_id, "north"))
        step.start()
        assert request_started.wait(5)
        close = threading.Thread(
            target=state.close_all_game_sessions, args=("run-1", "task-1"),
        )
        close.start()
        time.sleep(0.05)
        assert close.is_alive()
        allow_response.set()
        step.join(5)
        close.join(5)

    assert not step.is_alive()
    assert not close.is_alive()
    archived = state.run_history["run-1/task-1"]
    assert len(archived) == 1
    assert archived[0]["moves"] == 98
    assert archived[0]["steps"][-1]["action"] == "north"
    stored = json.loads((
        tmp_path / "runs/run-1/task-1/submissions/game-1/game_result.json"
    ).read_text())
    assert stored == archived[0]


def test_game_number_commit_is_atomic(tmp_path):
    state = bare_state(tmp_path)
    barrier = threading.Barrier(24)

    def commit(index: int):
        current = session(f"session-{index}", game_num=0)
        barrier.wait()
        state._commit_game_session(current)

    workers = [threading.Thread(target=commit, args=(index,)) for index in range(24)]
    for worker in workers:
        worker.start()
    for worker in workers:
        worker.join(5)

    assert sorted(item.game_num for item in state.game_sessions.values()) == list(range(1, 25))
