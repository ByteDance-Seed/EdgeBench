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

"""A judge infrastructure failure must not become a completed valid result."""

from __future__ import annotations

import json
import time
from types import SimpleNamespace

import pytest

from sforge.harness import judge_server
from sforge.harness.backend.base import StreamingExecResult
from sforge.harness.config import SForgeConfig
from sforge.harness.judge_server import JudgeState
from sforge.harness.run_evaluation import EvaluationError, judge_submission
from sforge.harness.task_spec import JudgeSpec, TaskSpec, WorkSpec


class SyntheticBackend:
    backend_name = "synthetic"

    def __init__(self, failure: str | None, *, score: float = 7.0,
                 valid: bool = True, timed_out: bool = False):
        self.failure = failure
        self.score = score
        self.valid = valid
        self.timed_out = timed_out
        self.cleaned = []
        self.created = 0

    def _step(self, name):
        if self.failure == name:
            raise RuntimeError("private-backend-detail")

    def create_container(self, *_args, **_kwargs):
        self._step("create")
        self.created += 1
        return SimpleNamespace(id=f"judge-{self.created}")

    def start_container(self, _handle):
        self._step("start")

    def copy_to_container(self, *_args):
        self._step("copy")

    def exec_run_with_timeout(self, *_args, **_kwargs):
        self._step("execute")
        return StreamingExecResult(
            output=json.dumps({"score": self.score, "valid": self.valid}),
            elapsed_seconds=0.01, timed_out=self.timed_out,
        )

    def cleanup_container(self, handle, _logger=None):
        self.cleaned.append(handle)


@pytest.fixture
def task():
    return TaskSpec(
        task_id="synthetic", name="Synthetic", base_image="python",
        platform="linux/amd64", cwd="/workspace", submit_paths=["."],
        submit_exclude=[], work=WorkSpec("specs", "solve", image_tag="test"),
        judge=JudgeSpec("true", 1, "structured_json", image_tag="test",
                        selection="valid_then_score"),
    )


@pytest.mark.parametrize("failure", ["create", "start", "copy", "execute"])
def test_direct_judge_does_not_return_default_report_on_failure(tmp_path, task, failure):
    backend = SyntheticBackend(failure)
    with pytest.raises(EvaluationError) as caught:
        judge_submission(task, b"", SForgeConfig(log_dir=tmp_path), backend,
                         submission_id="request-1", log_dir=tmp_path / "submission")
    assert "private-backend-detail" not in str(caught.value)
    assert "private-backend-detail" in (tmp_path / "submission/run_instance.log").read_text()
    assert len(backend.cleaned) == 1
    assert (backend.cleaned[0] is None) == (failure == "create")
    assert not (tmp_path / "submission/report.json").exists()


def _wait_result(state, identity):
    deadline = time.monotonic() + 3
    while time.monotonic() < deadline:
        result = state.get_result(identity)
        if result["status"] in ("completed", "error"):
            rows = state.get_run_history("run-1", "synthetic")["entries"]
            if any(row["submission_id"] == identity and row["status"] == result["status"] for row in rows):
                return result
        time.sleep(0.01)
    pytest.fail("synthetic judge did not settle")


@pytest.mark.parametrize("failure", ["create", "start", "copy", "execute"])
def test_failed_submission_remains_identifiable_and_next_submission_runs(tmp_path, task, failure, monkeypatch):
    backend = SyntheticBackend(failure)
    monkeypatch.setattr(judge_server, "create_backend_from_config", lambda _config: backend)
    state = JudgeState(SForgeConfig(log_dir=tmp_path))
    state.tasks[task.task_id] = task
    try:
        failed_id = state.submit(task.task_id, b"", run_id="run-1", round="agent-1")
        failed = _wait_result(state, failed_id)
        assert failed["status"] == "error"
        assert failed["report"] is None
        assert "private-backend-detail" not in failed["error"]
        backend.failure = None
        good_id = state.submit(task.task_id, b"", run_id="run-1", round="agent-2")
        good = _wait_result(state, good_id)
        assert good["status"] == "completed"
        assert good["report"]["submission_id"] == good_id
        history = state.get_run_history("run-1", task.task_id)
        entries = {row["submission_id"]: row for row in history["entries"]}
        assert set(entries) == {failed_id, good_id}
        assert entries[failed_id]["status"] == "error"
        assert "score" not in entries[failed_id]
        assert "valid" not in entries[failed_id]
        assert entries[good_id]["score"] == 7.0
        assert history["best_score"] == 7.0
        assert history["best_round"] == "agent-2"
        assert len(backend.cleaned) == 2
    finally:
        state._reaper_stop.set()
        state._reaper_thread.join(timeout=1)


@pytest.mark.parametrize("score,valid,timed_out", [(0.0, True, False), (0.0, False, False), (0.0, False, True)])
def test_real_evaluation_outcomes_are_still_reports(tmp_path, task, score, valid, timed_out):
    backend = SyntheticBackend(None, score=score, valid=valid, timed_out=timed_out)
    report = judge_submission(task, b"", SForgeConfig(log_dir=tmp_path), backend,
                              submission_id="request-1", log_dir=tmp_path / "submission")
    assert report.score == score
    assert report.valid is valid
    assert report.timed_out is timed_out
    assert len(backend.cleaned) == 1
    assert json.loads((tmp_path / "submission/report.json").read_text())["submission_id"] == "request-1"
