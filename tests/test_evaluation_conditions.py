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

"""Protocol vectors use an explicit fake image; Docker execution is qualified separately."""
from __future__ import annotations

import copy
import hashlib
import io
import json
import threading
import time
from dataclasses import replace
from pathlib import Path
from types import SimpleNamespace

from fastapi.testclient import TestClient
import pytest

from sforge.harness import judge_server as server
from sforge.harness.config import SForgeConfig
from sforge.harness.evaluation_conditions import capture_conditions, native_source_sha256
from sforge.harness.grading import EvalReport
from sforge.harness.task_spec import load_benchmark, load_task


def benchmark_files(root: Path, *, direction="maximize", platform="linux/amd64", blob_url=None):
    task = root / "tasks" / "toy"
    (task / "judge").mkdir(parents=True)
    (task / "environment").mkdir()
    (task / "instruction.md").write_text("Produce answer.txt for the synthetic task.\n")
    (task / "environment/Dockerfile").write_text("FROM scratch\n")
    (task / "judge/Dockerfile").write_text("FROM scratch\n")
    payload = b"7\n"
    digest = hashlib.sha256(payload).hexdigest()
    (root / "benchmark.toml").write_text('name = "conditions-test"\n' +
        (f'blob_url = "{blob_url}"\n' if blob_url else ""))
    (task / "task.toml").write_text(
        'id = "toy"\nversion = "1.0.0"\n[environment]\ncwd = "/work"\n' +
        f'platform = "{platform}"\n' +
        '[submission]\npaths = ["answer.txt"]\n[judge]\ncmd = "python /judge/grade.py"\n'
        'timeout_sec = 20\ncpus = 1\nmemory = "128m"\n' +
        f'[score]\ndirection = "{direction}"\n' +
        f'[[blobs]]\npath = "judge/data/offset.txt"\nsha256 = "{digest}"\n')
    return task, payload


class FakeImages:
    def __init__(self):
        self.image = "sha256:" + "a" * 64
        self.calls = 0

    def get(self, key):
        self.calls += 1
        if self.image is None:
            raise LookupError("unprepared fixture image")
        return SimpleNamespace(id=self.image)


class FakeBackend:
    backend_name = "docker"

    def __init__(self):
        self.client = SimpleNamespace(images=FakeImages())


@pytest.fixture
def api(tmp_path, monkeypatch):
    task, _ = benchmark_files(tmp_path / "benchmark")
    config = SForgeConfig(benchmark_dir=task.parent.parent, log_dir=tmp_path / "logs")
    backend = FakeBackend()
    monkeypatch.setattr(server, "create_backend_from_config", lambda config: backend)
    original = server.JudgeState
    states = []

    def construct(config):
        state = original(config)
        states.append(state)
        return state

    monkeypatch.setattr(server, "JudgeState", construct)

    def grade(**kwargs):
        return EvalReport(task_id=kwargs["task_spec"].task_id, submission_id=kwargs["submission_id"],
                          score=float(kwargs["archive"]), score_0_100=99, valid=True)

    monkeypatch.setattr(server, "judge_submission", grade)
    app = server.create_app(config)
    with TestClient(app) as client:
        yield client, states[0], backend, task
    states[0]._reaper_stop.set()
    states[0]._reaper_thread.join(timeout=1)


def register(api, run="run-one", **options):
    client, state, _, _ = api
    return client.post("/api/v1/register", json={"task_id":"toy", "run_id":run,
        "admin_secret":state.admin_secret, **options})


def submit(api, registration, data=b"3", **options):
    return api[0].post("/api/v1/submit", data={"token":registration["token"], **options},
                       files={"archive":("submission.tar.gz", data)})


def wait_result(client, url):
    deadline = time.monotonic() + 5
    while time.monotonic() < deadline:
        response = client.get(url)
        assert response.status_code == 200, response.text
        if response.json()["status"] in ("completed", "error"):
            return response.json()
        time.sleep(.01)
    pytest.fail("fixture result did not settle")


def test_context_and_each_receipt_share_original_registration_without_read_resampling(api, monkeypatch):
    client, state, backend, task = api
    registration = register(api).json()
    context = registration["evaluation_context"]
    conditions = context["evaluation_conditions"]
    assert set(context) == {"schema_version", "task_id", "run_id", "registration_id", "evaluation_conditions"}
    assert set(conditions) == {
        "schema_version", "task_sha256", "benchmark_sha256", "task_spec_sha256",
        "native_source_sha256", "judge_image_id", "execution_config_sha256", "score_direction", "selection",
    }
    assert conditions["task_sha256"] == hashlib.sha256((task / "task.toml").read_bytes()).hexdigest()
    assert conditions["benchmark_sha256"] == hashlib.sha256((task.parent.parent / "benchmark.toml").read_bytes()).hexdigest()
    assert conditions["judge_image_id"] == backend.client.images.image
    assert conditions["score_direction"] == "maximize" and conditions["selection"] == "valid_then_score"
    assert str(task) not in json.dumps(context)
    relay = "/api/v1/feedback/" + registration["feedback_relay_id"]
    accepted = submit(api, registration, include_receipt="true").json()
    assert accepted["receipt"]["evaluation_context"] == context
    result = wait_result(client, relay + "/result/" + accepted["submission_id"] + "?include_receipt=true")
    assert result["receipt"]["evaluation_context"] == context
    assert result["receipt"]["archive_sha256"] == hashlib.sha256(b"3").hexdigest()
    assert "score_0_100" not in result["report"]
    image_calls = backend.client.images.calls
    monkeypatch.setattr(server, "native_source_sha256", lambda: pytest.fail("read rescanned source"))
    backend.client.images.image = "sha256:" + "b" * 64
    (task / "task.toml").write_text('invalid changed file')
    for _ in range(3):
        assert client.get(relay + "/context").json() == context
        assert client.get(relay + "/result/" + accepted["submission_id"] + "?include_receipt=true").json() == result
    assert backend.client.images.calls == image_calls


def test_registration_retry_preserves_budget_gateway_and_rejects_condition_or_policy_drift(api):
    client, state, backend, task = api
    options = dict(max_agent_submissions=1, llm_base_url="https://model.invalid", llm_api_key="fixture-key")
    first = register(api, **options).json()
    submit(api, first)
    repeated = register(api, **options)
    assert repeated.status_code == 200 and repeated.json() == first
    assert submit(api, repeated.json()).status_code == 429
    snapshot = copy.deepcopy(state.resolve_token(first["token"])["evaluation_context"])
    for changed in [{"max_agent_submissions":2}, {"llm_api_key":"different-fixture-key"}]:
        response = register(api, **(options | changed))
        assert response.status_code == 409 and "fresh run_id" in response.text
        assert state.resolve_token(first["token"])["evaluation_context"] == snapshot
    backend.client.images.image = "sha256:" + "c" * 64
    assert register(api, **options).status_code == 409
    second = register(api, "run-two", **options).json()
    assert second["evaluation_context"]["evaluation_conditions"]["judge_image_id"] != snapshot["evaluation_conditions"]["judge_image_id"]
    assert len(state.tokens) == 2


def test_two_runs_auto_work_and_unknown_ids_are_isolated_by_the_read_only_relay(api):
    client, state, _, _ = api
    first, second = register(api).json(), register(api, "run-two").json()
    a = submit(api, first).json()["submission_id"]
    b = submit(api, second).json()["submission_id"]
    auto = submit(api, first, kind="auto", admin_secret=state.admin_secret).json()["submission_id"]
    relay = "/api/v1/feedback/" + first["feedback_relay_id"]
    assert client.get(relay + "/result/" + a).status_code == 200
    for sid in [b, auto, "unknown"]:
        assert client.get(relay + "/result/" + sid).status_code == 404
    assert client.get("/api/v1/feedback/unknown/context").status_code == 404
    assert client.post(relay + "/submit").status_code in (404,405)
    capability = first["feedback_relay_id"]
    assert client.post("/api/v1/submit", data={"token": capability}, files={"archive": ("x.tar.gz", b"3")}).status_code == 401
    assert client.post("/api/v1/llm/" + capability + "/v1/messages", json={}).status_code == 401


def test_legacy_result_and_default_feedback_do_not_acquire_new_conditions(api):
    client, state, _, _ = api
    registration = register(api).json()
    native = {"status":server.SubmissionStatus.COMPLETED,"task_id":"toy","run_id":"run-one",
              "round":"agent-0","report":{"score":0,"valid":True,"score_0_100":99},"error":None}
    state.submissions["legacy"] = native
    plain = client.get("/api/v1/result/legacy").json()
    assert plain == {"submission_id":"legacy","status":"completed","report":{"score":0,"valid":True},"error":None}
    enriched = client.get("/api/v1/feedback/"+registration["feedback_relay_id"]+"/result/legacy?include_receipt=true").json()
    assert enriched["report"] == plain["report"]
    assert enriched["receipt"]["evaluation_context"] is None
    assert enriched["receipt"]["archive_sha256"] is None
    assert "evaluation_context" not in native
    assert "receipt" not in submit(api, registration).json()


def test_queued_work_uses_its_own_task_resources_and_backend_after_reload(api, monkeypatch):
    client, state, backend, task = api
    registration = register(api, judge_cpu_limit=2, judge_mem_limit="160m").json()
    context = registration["evaluation_context"]
    release = threading.Event()
    original = state._grade_worker
    observed = []

    def delayed(*args):
        assert release.wait(5)
        return original(*args)

    def grade(**kwargs):
        observed.append(kwargs)
        return EvalReport(task_id=kwargs["task_spec"].task_id, submission_id=kwargs["submission_id"],score=5,valid=True)

    monkeypatch.setattr(state, "_grade_worker", delayed)
    monkeypatch.setattr(server, "judge_submission", grade)
    accepted = submit(api, registration).json()
    state.tasks["toy"] = replace(state.tasks["toy"], judge=replace(state.tasks["toy"].judge,cmd="changed",direction="minimize"))
    state.config.judge_extra_env["changed"] = "new environment"
    state.run_backends[state._run_key("run-one","toy")] = object()
    release.set()
    result = wait_result(client,"/api/v1/result/"+accepted["submission_id"]+"?include_receipt=true")
    assert observed[0]["task_spec"].judge.cmd == "python /judge/grade.py"
    assert observed[0]["config"].judge_cpu_limit == 2
    assert observed[0]["config"].judge_mem_limit == "160m"
    assert observed[0]["config"].judge_extra_env == {}
    assert observed[0]["backend"] is backend
    assert observed[0]["evaluator_image"] == context["evaluation_conditions"]["judge_image_id"]
    assert result["receipt"]["evaluation_context"] == context
    assert state.get_run_history("run-one","toy")["best_score"] == 5


@pytest.mark.parametrize("changed", ["task-bytes","benchmark-bytes","instruction","blob","direction","cpu","memory","environment","source","image"])
def test_conditions_distinguish_actual_supported_inputs(tmp_path, changed):
    task_dir, _ = benchmark_files(tmp_path)
    task = load_task(task_dir)
    backend, config = FakeBackend(), SForgeConfig(benchmark_dir=tmp_path)
    before = capture_conditions(task,backend,"d"*64,config)
    source = "d"*64
    if changed == "task-bytes":
        (task_dir/"task.toml").write_text((task_dir/"task.toml").read_text()+"\n# different loaded bytes\n")
    elif changed == "benchmark-bytes":
        (tmp_path/"benchmark.toml").write_text((tmp_path/"benchmark.toml").read_text()+"\n# new benchmark bytes\n")
        load_benchmark.cache_clear()
    elif changed == "instruction":
        (task_dir/"instruction.md").write_text("A changed task instruction")
    elif changed in ("blob","direction"):
        text=(task_dir/"task.toml").read_text()
        text=text.replace('direction = "maximize"','direction = "minimize"') if changed=="direction" else text.replace(task.blobs[0].sha256,"e"*64)
        (task_dir/"task.toml").write_text(text)
    elif changed == "cpu": config.judge_cpu_limit=3
    elif changed == "memory": config.judge_mem_limit="192m"
    elif changed == "environment": config.judge_extra_env={"SYNTHETIC_FACTOR":"2"}
    elif changed == "source": source="f"*64
    elif changed == "image": backend.client.images.image="sha256:"+"b"*64
    after=capture_conditions(load_task(task_dir),backend,source,config)
    assert before is not None and after is not None and before != after
    # A later disk edit must not rewrite the original parsed snapshot.
    if changed in ("task-bytes","benchmark-bytes","instruction","blob","direction"):
        assert capture_conditions(task,backend,"d"*64,config) == before


@pytest.mark.parametrize("missing", ["source","image","loader","backend","game","changed-spec"])
def test_unavailable_conditions_stay_unknown(tmp_path, missing):
    task_dir,_=benchmark_files(tmp_path);task=load_task(task_dir)
    backend,config,source=FakeBackend(),SForgeConfig(benchmark_dir=tmp_path),"d"*64
    if missing=="source":source=None
    elif missing=="image":backend.client.images.image=None
    elif missing=="loader":task=replace(task)
    elif missing=="backend":backend.backend_name="k8s"
    elif missing=="game":task=replace(task,judge=replace(task.judge,game_server_cmd="synthetic"))
    elif missing=="changed-spec":task.submit_paths.append("unobserved")
    assert capture_conditions(task,backend,source,config) is None


def test_caller_labels_are_not_service_facts_and_unknown_feedback_remains_usable(api):
    client,state,backend,_=api
    forged={"schema_version":"sforge_run_evaluation_context_v1","evaluation_conditions":{"task_sha256":"f"*64}}
    registration=register(api,evaluation_context=forged).json()
    assert registration["evaluation_context"] != forged
    backend.client.images.image=None
    unknown=register(api,"unknown-run").json()
    assert unknown["evaluation_context"]["evaluation_conditions"] is None
    accepted=submit(api,unknown).json()
    result=wait_result(client,"/api/v1/result/"+accepted["submission_id"]+"?include_receipt=true")
    assert result["status"]=="completed" and result["report"]["score"]==3
    assert result["receipt"]["evaluation_context"]==unknown["evaluation_context"]


def test_source_digest_observes_framework_files_not_a_caller_revision(tmp_path):
    (tmp_path/"a.py").write_text("value=1\n")
    before=native_source_sha256(tmp_path)
    (tmp_path/"a.py").write_text("value=2\n")
    assert native_source_sha256(tmp_path)!=before
