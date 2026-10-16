"""Current admission limits are independent of retained result timestamps."""

import copy
import os
import shutil
import socket
import subprocess
import threading
import time

import pytest
import uvicorn
from fastapi.testclient import TestClient

from sforge.harness import judge_server as judge
from sforge.harness.config import SForgeConfig
from sforge.harness.evolve_scripts import generate_submit_script


@pytest.fixture
def harness(tmp_path, monkeypatch):
    # No evaluation/container operation is needed for the read-only route.
    monkeypatch.setattr(judge, "create_backend_from_config", lambda config: None)
    (tmp_path / "tasks").mkdir()
    (tmp_path / "tasks/BENCHMARK.yaml").write_text("name: availability-test\n")
    state = judge.JudgeState(SForgeConfig(log_dir=tmp_path, tasks_dir=tmp_path / "tasks"))
    state.tokens["test-token"] = {
        "task_id": "example", "run_id": "sample", "next_agent": 3,
        "next_auto": 2, "max_agent_submissions": 5,
        "submission_cooldown": 3600, "last_agent_submit_at": 9900.0,
        "judge_cpu_limit": None, "judge_mem_limit": None,
    }
    state.run_history["sample/example"] = [
        {"type": "submission", "round": "agent-2", "score": 0.4,
         "pass_rate": 1.0, "status": "completed", "timestamp": 1.0},
        {"type": "submission", "round": "auto-1", "score": 0.9,
         "pass_rate": 1.0, "status": "completed", "timestamp": 2.0},
    ]
    monkeypatch.setattr(judge, "JudgeState", lambda config: state)
    app = judge.create_app(state.config)
    yield state, app
    state._reaper_stop.set()
    state._reaper_thread.join(timeout=2)


@pytest.mark.parametrize("last,cooldown,now,wait", [
    (0.0, 3600, 10000.0, 0),  # first submission
    (9900.0, None, 10000.0, 0),
    (9900.0, 0, 10000.0, 0),
    (9900.0, 3600, 10000.0, 3501),  # unchanged admission rounding
    (9900.0, 3600, 13499.75, 1),
    (9900.0, 3600, 13500.0, 0),  # exact boundary
    (9900.0, 3600, 13501.0, 0),
])
def test_readback_and_admission_share_clock(harness, monkeypatch, last, cooldown, now, wait):
    state, _ = harness
    state.tokens["test-token"].update(last_agent_submit_at=last, submission_cooldown=cooldown)
    monkeypatch.setattr(judge.time, "time", lambda: now)
    before = copy.deepcopy(state.tokens)
    snapshot = state.agent_submission_availability("test-token")
    assert snapshot == {"observed_at": now, "remaining_submissions": 3,
                        "cooldown_remaining_seconds": wait}
    assert state.tokens == before
    if wait:
        with pytest.raises(judge.SubmissionCooldownActive, match=f"wait {wait}s"):
            state.consume_round("test-token")
        assert state.tokens == before
    else:
        assert state.consume_round("test-token")[2] == "agent-3"
        assert state.tokens["test-token"]["next_agent"] == 4
        # An earlier read did not reserve an extra submission.
        if cooldown:
            with pytest.raises(judge.SubmissionCooldownActive):
                state.consume_round("test-token")


def test_history_uses_token_limits_and_preserves_visibility(harness, monkeypatch):
    state, app = harness
    monkeypatch.setattr(judge.time, "time", lambda: 10000.0)
    before = copy.deepcopy(state.tokens)
    with TestClient(app) as client:
        for _ in range(2):
            response = client.get("/api/v1/history", params={"token": "test-token"})
            assert response.status_code == 200
            data = response.json()
            assert data["best_score"] == 0.4
            assert data["best_round"] == "agent-2"
            assert [entry["round"] for entry in data["entries"]] == ["agent-2"]
            assert data["auto_submissions"] == 0
            assert data["agent_submission_availability"]["cooldown_remaining_seconds"] == 3501
        assert state.tokens == before
        rejected = client.post("/api/v1/submit", data={"token": "test-token"},
                               files={"archive": ("candidate.tar.gz", b"")})
        assert rejected.status_code == 429
        assert "wait 3501s" in rejected.json()["detail"]
        assert state.tokens == before
        admin = client.get("/api/v1/history", params={"token": "test-token", "admin_secret": state.admin_secret})
        assert admin.json() == state.get_run_history("sample", "example")
        assert client.get("/api/v1/history", params={"token": "invalid"}).status_code == 401
    assert state.tokens == before


@pytest.mark.parametrize("maximum,remaining", [(None, None), (2, 0), (1, 0), (5, 3)])
def test_budget_snapshot_is_not_history_count(harness, maximum, remaining):
    state, _ = harness
    state.tokens["test-token"].update(max_agent_submissions=maximum, submission_cooldown=None)
    before = copy.deepcopy(state.tokens)
    assert state.agent_submission_availability("test-token")["remaining_submissions"] == remaining
    assert state.tokens == before
    if remaining == 0:
        with pytest.raises(judge.SubmissionBudgetExceeded):
            state.consume_round("test-token")
        assert state.tokens == before


def test_unknown_token_read_has_no_effect(harness):
    state, _ = harness
    before = copy.deepcopy(state.tokens)
    with pytest.raises(KeyError):
        state.agent_submission_availability("invalid")
    assert state.tokens == before


def test_auto_round_does_not_change_agent_limits(harness, monkeypatch):
    state, _ = harness
    monkeypatch.setattr(judge.time, "time", lambda: 10000.0)
    before = state.agent_submission_availability("test-token")
    assert state.consume_round("test-token", "auto")[2] == "auto-2"
    assert state.agent_submission_availability("test-token") == before


def test_generated_list_against_http(harness, tmp_path):
    for tool in ("bash", "curl", "jq"):
        if not shutil.which(tool):
            pytest.skip(f"CLI integration requires {tool}")
    state, app = harness
    @app.get("/legacy/api/v1/history")
    def legacy_history():
        return {"entries": [], "best_score": None, "best_pass_rate": 0.0}
    state.tokens["test-token"]["last_agent_submit_at"] = time.time()
    script = tmp_path / "sforge-submit"
    script.write_text(generate_submit_script())
    sock = socket.socket()
    sock.bind(("127.0.0.1", 0))
    server = uvicorn.Server(uvicorn.Config(app, log_level="error"))
    thread = threading.Thread(target=server.run, kwargs={"sockets": [sock]}, daemon=True)
    thread.start()
    try:
        deadline = time.monotonic() + 5
        while not server.started and time.monotonic() < deadline:
            time.sleep(0.01)
        assert server.started
        env = {**os.environ, "SFORGE_JUDGE_URL": f"http://127.0.0.1:{sock.getsockname()[1]}",
               "SFORGE_TOKEN": "test-token", "NO_PROXY": "127.0.0.1", "no_proxy": "127.0.0.1"}
        before = copy.deepcopy(state.tokens)
        result = subprocess.run(["bash", str(script), "--list"], env=env, capture_output=True, text=True, timeout=10)
        assert result.returncode == 0, result.stderr
        assert "Remaining submissions: 3" in result.stdout
        assert "Cooldown: wait" in result.stdout
        assert "agent-2" in result.stdout and "auto-1" not in result.stdout
        assert "does not reserve" in result.stdout
        assert state.tokens == before
        state.tokens["test-token"].update(max_agent_submissions=2, last_agent_submit_at=0.0)
        exhausted = subprocess.run(["bash", str(script), "--list"], env=env, capture_output=True, text=True, timeout=10)
        assert exhausted.returncode == 0 and "budget exhausted" in exhausted.stdout
        failed = subprocess.run(["bash", str(script), "--list"], env={**env, "SFORGE_TOKEN": "invalid"},
                                capture_output=True, text=True, timeout=10)
        assert failed.returncode != 0 and "Could not read" in failed.stderr
        assert "Submission History" not in failed.stdout
        legacy = subprocess.run(["bash", str(script), "--list"],
                                env={**env, "SFORGE_JUDGE_URL": env["SFORGE_JUDGE_URL"] + "/legacy"},
                                capture_output=True, text=True, timeout=10)
        assert legacy.returncode == 0 and "limits unavailable" in legacy.stdout
        assert "Cooldown: ready" not in legacy.stdout
    finally:
        server.should_exit = True
        thread.join(timeout=5)
        sock.close()
