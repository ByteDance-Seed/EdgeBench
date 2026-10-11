"""An interrupted startup must retain cancellation and execute cleanup once."""
import json
from types import SimpleNamespace

import pytest

from sforge.harness import run_agent as runner
from sforge.harness.config import SForgeConfig


@pytest.mark.parametrize("phase", ["secret", "images", "install", "tools"])
def test_startup_interrupt_preserves_history_and_cleanup(tmp_path, monkeypatch, phase):
    cleaned = []
    archived = []
    handle = object()

    def at(name, value=None):
        if name == phase:
            raise KeyboardInterrupt
        return value

    config = SForgeConfig(log_dir=tmp_path)
    agent = SimpleNamespace(timeout=30, _config=config, default_model="fixture",
        model_env=None, augment_env=lambda env, model: None, install_cmds=["install"])
    task = SimpleNamespace(task_id="fixture", cwd="/workspace", submit_paths=["answer.txt"],
        submit_exclude=[], game_mode=False, work_image_key="work", judge_image_key="judge",
        work=SimpleNamespace(cpu_limit=1, mem_limit="1g"))
    backend = SimpleNamespace(backend_name="k8s", image_exists=lambda key: at("images", True),
        remove_container_by_name=lambda name: None, create_container=lambda *a, **kw: handle,
        start_container=lambda value: None,
        exec_run_with_exit_code=lambda *a, **kw: at("install"),
        cleanup_container=lambda value, logger: cleaned.append(value))
    monkeypatch.setattr(runner, "get_admin_secret", lambda path: at("secret", "synthetic-secret"))
    monkeypatch.setattr(runner, "_install_tools", lambda *a, **kw: at("tools"))
    if phase == "tools":
        backend.exec_run_with_exit_code = lambda *a, **kw: SimpleNamespace(
            output="installed", timed_out=False, exit_code=0, elapsed_seconds=0)
    monkeypatch.setattr(runner.requests, "post", lambda *a, **kw: SimpleNamespace(
        status_code=200, raise_for_status=lambda: None, json=lambda: {"token": "fixture-token"}))
    history = {"best_score": 7, "best_pass_rate": 1, "best_round": "agent-1",
        "agent_submissions": 1, "auto_submissions": 0, "entries": []}
    monkeypatch.setattr(runner.requests, "get", lambda *a, **kw: SimpleNamespace(
        raise_for_status=lambda: None, json=lambda: history))

    def archive(backend, value, spec):
        archived.append(value)
        return b"synthetic-checkpoint"

    monkeypatch.setattr(runner, "_extract_archive_from_container", archive)
    result = runner.run_agent(task, agent, config, backend, "run", internet=True)
    assert result.agent_output == "Stopped by user (Ctrl+C)"
    assert result.resume_count == 0 and result.timed_out is False
    installed = phase in {"install", "tools"}
    assert cleaned == [handle if installed else None]
    assert archived == ([handle] if installed else [])
    assert result.archive == (b"synthetic-checkpoint" if installed else b"")
    assert result.best_score == (7 if installed else None)
    saved = json.loads((tmp_path / "runs/run/fixture/run_history.json").read_text())
    assert saved["agent_submissions"] == (1 if installed else 0)
