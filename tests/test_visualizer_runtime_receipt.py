"""Stopped adapter runs stay stopped without Docker or a completed result."""

import json
import shutil

import pytest
from fastapi.testclient import TestClient

from sforge.visualizer import scanner
from sforge.visualizer.server import create_app


@pytest.fixture
def trial(tmp_path, monkeypatch):
    task_dir = tmp_path / "run" / "case"
    task_dir.mkdir(parents=True)
    (task_dir / "run_agent.log").write_text("Starting agent: codex\n")
    (task_dir / "started_at").write_text("1700000000")
    monkeypatch.setattr(scanner, "_docker_status_map", lambda: {})
    return task_dir


def receipt(trial, **changes):
    data = dict(run_id="run", task="case", status="cancelled",
                controller_elapsed_seconds=7200.25, best_score=99999)
    data.update(changes)
    (trial / "runtime-receipt.json").write_text(json.dumps(data))


@pytest.mark.parametrize("status", ["cancelled", "runner_failed", "launch_failed"])
def test_stopped_receipt_closes_liveness_and_freezes_duration(trial, status):
    receipt(trial, status=status)
    run = scanner._build_run("run", trial)
    assert run.aborted and not run.has_final
    assert run.runtime_seconds == 7200.25
    assert run.best_score is None  # Receipt has no score authority.


@pytest.mark.parametrize("changes", [
    {"run_id": "other"}, {"task": "other"}, {"status": "starting"},
    {"status": "running"}, {"status": "terminal"}, {"status": "unknown"},
    {"controller_elapsed_seconds": None}, {"controller_elapsed_seconds": True},
    {"controller_elapsed_seconds": "7200"}, {"controller_elapsed_seconds": -1},
    {"controller_elapsed_seconds": float("nan")},
    {"controller_elapsed_seconds": float("inf")},
    {"controller_elapsed_seconds": 10 ** 400},
])
def test_unmatched_or_invalid_receipt_preserves_native_liveness(trial, changes):
    receipt(trial, **changes)
    run = scanner._build_run("run", trial)
    assert not run.aborted and not run.has_final


@pytest.mark.parametrize("contents", ["{", "[]", "null"])
def test_partial_or_non_object_receipt_preserves_native_liveness(trial, contents):
    (trial / "runtime-receipt.json").write_text(contents)
    assert not scanner._build_run("run", trial).aborted


def test_completed_native_result_keeps_precedence(trial):
    receipt(trial)
    (trial / "final_result.json").write_text(json.dumps(dict(
        best_score=0, best_pass_rate=1, runtime_seconds=12, timed_out=False)))
    run = scanner._build_run("run", trial)
    assert run.has_final and not run.aborted
    assert run.best_score == 0 and run.runtime_seconds == 12


def test_absent_receipt_keeps_native_probe_behavior(trial, monkeypatch):
    assert not scanner._build_run("run", trial).aborted
    monkeypatch.setattr(scanner, "_docker_status_map", lambda: {
        "sforge.run.case.run": "exited"})
    assert scanner._build_run("run", trial).aborted


def test_stop_receipt_overrides_stale_running_container_cache(trial, monkeypatch):
    receipt(trial)
    monkeypatch.setattr(scanner, "_docker_status_map", lambda: {
        "sforge.run.case.run": "running"})
    assert scanner._build_run("run", trial).aborted


def test_zero_duration_and_partial_scores_remain_distinct_from_completion(trial):
    receipt(trial, controller_elapsed_seconds=0)
    submission = trial / "submissions" / "agent-1"
    submission.mkdir(parents=True)
    (submission / "report.json").write_text(json.dumps(dict(
        submission_id="agent-1", valid=True, score=7.5, passed=1, total=1)))
    run = scanner._build_run("run", trial)
    assert run.aborted and not run.has_final and run.runtime_seconds == 0
    assert run.best_score == 7.5 and run.total_rounds == 1


@pytest.mark.parametrize("route", ["/", "/task/case", "/compare/case?runs=run&runs=other", "/run/run/case"])
def test_all_native_pages_display_stopped_state(trial, route):
    receipt(trial)
    other = trial.parent.parent / "other" / "case"
    shutil.copytree(trial, other)
    receipt(other, run_id="other")
    response = TestClient(create_app(trial.parent.parent)).get(route)
    assert response.status_code == 200
    assert '>aborted</span>' in response.text
    assert '>running</span>' not in response.text
