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

"""Opt-in TOML/Blob -> real Docker -> TCP HTTP qualification, with no fake grader."""

from __future__ import annotations

import hashlib
import io
import json
import os
import shlex
import socket
import tarfile
import threading
import time
import uuid
from concurrent.futures import ThreadPoolExecutor
from contextlib import contextmanager
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

import docker
import pytest
import requests
import uvicorn

from sforge.harness import judge_server as native
from sforge.harness.agent.base import Agent
from sforge.harness.backend.docker_backend import DockerBackend
from sforge.harness.config import SForgeConfig
from sforge.harness.docker_build import BuildImageError, build_judge_image, ensure_blobs
from sforge.harness.evaluation_conditions import native_source_sha256
from sforge.harness.run_agent import run_agent
from sforge.harness.task_spec import load_benchmark, load_task

pytestmark = pytest.mark.skipif(
    os.environ.get("SFORGE_CONDITIONS_DOCKER_TEST") != "1",
    reason="Requires explicit isolated Docker/HTTP evaluation-conditions qualification",
)


def candidate(value):
    data = f"{value}\n".encode()
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w:gz") as archive:
        info = tarfile.TarInfo("answer.txt")
        info.size = len(data)
        archive.addfile(info, io.BytesIO(data))
    return buf.getvalue()


@contextmanager
def serving(app):
    sock = socket.socket()
    sock.bind(("0.0.0.0", 0))
    server = uvicorn.Server(uvicorn.Config(app, log_level="error", lifespan="off"))
    thread = threading.Thread(target=server.run, kwargs={"sockets": [sock]}, daemon=True)
    thread.start()
    try:
        deadline = time.monotonic() + 10
        while not server.started and thread.is_alive() and time.monotonic() < deadline:
            time.sleep(.01)
        assert server.started, "isolated HTTP server failed to start"
        yield f"http://127.0.0.1:{sock.getsockname()[1]}"
    finally:
        server.should_exit = True
        thread.join(timeout=10)
        sock.close()
        assert not thread.is_alive()


class ObservedDockerBackend(DockerBackend):
    """Observe actual created container configuration without replacing execution."""

    def __init__(self, client):
        super().__init__(client)
        self.created = []

    def create_container(self, *args, **kwargs):
        handle = super().create_container(*args, **kwargs)
        self.created.append((handle, self.client.api.inspect_container(handle.id)))
        return handle


@pytest.fixture
def evaluator(tmp_path, monkeypatch):
    client = docker.from_env()
    base = os.environ.get("SFORGE_TEST_DOCKER_BASE", "python:3.12-slim")
    base_image = client.images.get(base)  # Require a cached base, never pull one.
    platform = base_image.attrs["Os"] + "/" + base_image.attrs["Architecture"]
    root = tmp_path / "benchmark"
    task_dir = root / "tasks/toy"
    (task_dir / "judge").mkdir(parents=True)
    (task_dir / "environment").mkdir()
    (task_dir / "instruction.md").write_text("Write answer.txt with a number.\n")
    (task_dir / "environment/Dockerfile").write_text(f"FROM {base}\n")
    (task_dir / "judge/Dockerfile").write_text(
        f"FROM {base}\nCOPY judge /judge\nRUN mkdir -p /work /opt/sforge\nWORKDIR /work\n"
    )
    (task_dir / "judge/grade.py").write_text(
        "import json, os\nfrom pathlib import Path\n"
        "score = int(Path('answer.txt').read_text()) + int(Path('/judge/data/offset.txt').read_text())"
        " + int(os.environ.get('SYNTHETIC_OFFSET', '0'))\n"
        "Path('/opt/sforge/result.json').write_text(json.dumps(dict(score=score, valid=True, summary='synthetic')) )\n"
    )
    payload = b"7\n"
    sha = hashlib.sha256(payload).hexdigest()
    blob_dir = tmp_path / "blobs"
    blob_dir.mkdir()
    (blob_dir / sha).write_bytes(payload)
    handler = partial(SimpleHTTPRequestHandler, directory=str(blob_dir))
    blob_server = ThreadingHTTPServer(("127.0.0.1", 0), handler)
    blob_thread = threading.Thread(target=blob_server.serve_forever, daemon=True)
    blob_thread.start()
    name = "conditions-" + uuid.uuid4().hex[:12]
    (root / "benchmark.toml").write_text(
        f'name = "{name}"\nblob_url = "http://127.0.0.1:{blob_server.server_port}"\n'
    )
    task_path = task_dir / "task.toml"
    task_path.write_text(
        f'id = "toy"\nversion = "1.0.0"\n[environment]\ncwd = "/work"\nplatform = "{platform}"\n'
        '[submission]\npaths = ["answer.txt"]\n[judge]\ncmd = "python /judge/grade.py"\n'
        'timeout_sec = 20\ncpus = 1\nmemory = "128m"\n[score]\ndirection = "maximize"\n'
        f'[[blobs]]\npath = "judge/data/offset.txt"\nsha256 = "{sha}"\n'
    )
    config = SForgeConfig(benchmark_dir=root, log_dir=tmp_path / "logs")
    task = load_task(task_dir)
    owned_tags = [task.judge_image_key]
    backend = ObservedDockerBackend(client)
    states = []
    real_state = native.JudgeState

    def construct(config):
        state = real_state(config)
        states.append(state)
        return state

    monkeypatch.setattr(native, "JudgeState", construct)
    monkeypatch.setattr(native, "create_backend_from_config", lambda config: backend)
    try:
        build_judge_image(task, config)
        keep = f"{name}.fixture:keep"
        client.images.get(task.judge_image_key).tag(keep)
        owned_tags.append(keep)
        assert (task_dir / "judge/data/offset.txt").read_bytes() == payload
        yield config, task, client, backend, owned_tags, states
    finally:
        for state in states:
            state._reaper_stop.set()
            state._reaper_thread.join(timeout=2)
        for handle, _ in backend.created:
            try:
                client.containers.get(handle.id).remove(force=True)
            except docker.errors.NotFound:
                pass
        for tag in owned_tags:
            try:
                client.images.remove(tag)
            except docker.errors.ImageNotFound:
                pass
        blob_server.shutdown()
        blob_server.server_close()
        blob_thread.join(timeout=2)
        client.close()


def register(url, state, run="run-a", **options):
    response = requests.post(url + "/api/v1/register", json={
        "task_id": "toy", "run_id": run, "admin_secret": state.admin_secret, **options,
    }, timeout=10)
    response.raise_for_status()
    value = response.json()
    return value, url + "/api/v1/feedback/" + value["feedback_relay_id"]


def get(url):
    response = requests.get(url, timeout=10)
    response.raise_for_status()
    return response.json()


def submit(url, registration, archive, **options):
    response = requests.post(url + "/api/v1/submit", data={
        "token": registration["token"], "include_receipt": "true", **options,
    }, files={"archive": ("submission.tar.gz", archive)}, timeout=15)
    response.raise_for_status()
    return response.json()


def result(relay, sid):
    deadline = time.monotonic() + 60
    while time.monotonic() < deadline:
        value = get(relay + "/result/" + sid + "?include_receipt=true")
        if value["status"] in ("completed", "error"):
            assert value["status"] == "completed", value
            assert value["report"]["valid"] and not value["report"]["timed_out"], value
            return value
        time.sleep(.05)
    pytest.fail("actual Docker result did not settle")


def test_actual_blob_image_resources_concurrent_candidates_and_scoped_reads(evaluator, monkeypatch):
    config, task, client, backend, _, states = evaluator
    source_reads = []

    def observed_source():
        source_reads.append(True)
        return native_source_sha256()

    monkeypatch.setattr(native, "native_source_sha256", observed_source)
    app = native.create_app(config)
    with serving(app) as url:
        state = states[0]
        registration, relay = register(url, state, judge_mem_limit="160m")
        context = get(relay + "/context")
        conditions = context["evaluation_conditions"]
        assert context == registration["evaluation_context"]
        assert conditions["task_sha256"] == hashlib.sha256((task.task_dir / "task.toml").read_bytes()).hexdigest()
        assert conditions["benchmark_sha256"] == hashlib.sha256((config.benchmark_dir / "benchmark.toml").read_bytes()).hexdigest()
        assert conditions["judge_image_id"] == client.images.get(task.judge_image_key).id
        assert conditions["native_source_sha256"] == native_source_sha256()
        with ThreadPoolExecutor(2) as pool:
            repeated = list(pool.map(lambda _: register(url, state, judge_mem_limit="160m")[0], range(2)))
            assert repeated == [registration, registration]
            archives = [candidate(3), candidate(19)]
            accepted = list(pool.map(lambda data: submit(url, registration, data), archives))
        reads = [result(relay, value["submission_id"]) for value in accepted]
        assert [value["report"]["score"] for value in reads] == [10, 26]
        assert {value["receipt"]["round_id"] for value in reads} == {"agent-1", "agent-2"}
        for archive, value in zip(archives, reads):
            receipt = value["receipt"]
            assert receipt["evaluation_context"] == context
            assert receipt["archive_sha256"] == hashlib.sha256(archive).hexdigest()
            assert receipt["archive_bytes"] == len(archive)
            graded = config.log_dir / "runs/run-a/toy/submissions" / receipt["round_id"] / "submission.tar.gz"
            assert graded.read_bytes() == archive
            plain = get(url + "/api/v1/result/" + value["submission_id"])
            assert plain == {key: item for key, item in value.items() if key != "receipt"}
        for _, observed in backend.created:
            assert observed["Image"] == conditions["judge_image_id"]
            assert observed["HostConfig"]["NanoCpus"] == 1_000_000_000
            assert observed["HostConfig"]["Memory"] == 160 * 1024 * 1024
            assert observed["HostConfig"]["NetworkMode"] == "none"
        _, other = register(url, state, "run-b")
        assert requests.get(other + "/result/" + accepted[0]["submission_id"], timeout=5).status_code == 404
        auto = submit(url, registration, candidate(99), kind="auto", admin_secret=state.admin_secret)
        assert requests.get(relay + "/result/" + auto["submission_id"], timeout=5).status_code == 404
        # Wait for the owned auto container before fixture cleanup.
        while get(url + "/api/v1/result/" + auto["submission_id"])["status"] in ("queued", "running"):
            time.sleep(.05)
        for _ in range(3):
            assert get(relay + "/context") == context
            assert get(relay + "/result/" + accepted[0]["submission_id"] + "?include_receipt=true") == reads[0]
        assert len(source_reads) == 1


def test_loaded_task_blob_and_image_are_frozen_while_fresh_run_observes_changes(evaluator):
    config, task, client, backend, owned_tags, states = evaluator
    app = native.create_app(config)
    with serving(app) as url:
        state = states[0]
        original, old_relay = register(url, state)
        before = original["evaluation_context"]
        (task.task_dir / "judge/grade.py").write_text(
            (task.task_dir / "judge/grade.py").read_text().replace("score=score", "score=score + 100")
        )
        task_path = task.task_dir / "task.toml"
        changed_data = b"11\n"
        changed_sha = hashlib.sha256(changed_data).hexdigest()
        (config.benchmark_dir.parent / "blobs" / changed_sha).write_bytes(changed_data)
        task_path.write_text(task_path.read_text()
                             .replace('direction = "maximize"', 'direction = "minimize"')
                             .replace(task.blobs[0].sha256, changed_sha))
        benchmark_path = config.benchmark_dir / "benchmark.toml"
        benchmark_path.write_text(benchmark_path.read_text() + "# another loaded revision\n")
        load_benchmark.cache_clear()
        changed_task = load_task(task.task_dir)
        owned_tags.append(changed_task.judge_image_key)
        build_judge_image(changed_task, config)
        replacement = client.images.get(changed_task.judge_image_key)
        replacement.tag(task.judge_image_key)
        assert get(old_relay + "/context") == before
        state.load_tasks()
        state.config.judge_extra_env["SYNTHETIC_OFFSET"] = "5"
        response = requests.post(url + "/api/v1/register", json={
            "task_id": "toy", "run_id": "run-a", "admin_secret": state.admin_secret,
        }, timeout=10)
        assert response.status_code == 409 and "fresh run_id" in response.text
        new, new_relay = register(url, state, "run-b", judge_cpu_limit=2, judge_mem_limit="192m")
        after = new["evaluation_context"]
        for field in ("task_sha256", "benchmark_sha256", "task_spec_sha256", "judge_image_id", "execution_config_sha256", "score_direction"):
            assert before["evaluation_conditions"][field] != after["evaluation_conditions"][field]
        old_result = result(old_relay, submit(url, original, candidate(3))["submission_id"])
        new_result = result(new_relay, submit(url, new, candidate(3))["submission_id"])
        assert old_result["report"]["score"] == 10
        assert new_result["report"]["score"] == 119  # actual new Blob 11 + grader 100 + environment 5
        assert old_result["receipt"]["evaluation_context"] == before
        assert new_result["receipt"]["evaluation_context"] == after
        result(new_relay, submit(url, new, candidate(19))["submission_id"])
        assert get(url + "/api/v1/history?token=" + new["token"])["best_score"] == 119
        for _, observed in backend.created[1:]:
            assert observed["Image"] == after["evaluation_conditions"]["judge_image_id"]
            assert observed["HostConfig"]["NanoCpus"] == 2_000_000_000
            assert observed["HostConfig"]["Memory"] == 192 * 1024 * 1024


def test_missing_image_is_unknown_and_blob_mismatch_cannot_build_a_false_fact(evaluator):
    config, task, client, _, _, states = evaluator
    image = client.images.get(task.judge_image_key)
    client.images.remove(task.judge_image_key)
    app = native.create_app(config)
    with serving(app) as url:
        state = states[0]
        registration, relay = register(url, state)
        assert registration["evaluation_context"]["evaluation_conditions"] is None
        with pytest.raises(docker.errors.ImageNotFound):
            client.images.get(task.judge_image_key)
        image.tag(task.judge_image_key)
        read = result(relay, submit(url, registration, candidate(3))["submission_id"])
        assert read["report"]["score"] == 10
        assert read["receipt"]["evaluation_context"]["evaluation_conditions"] is None
        state.submissions[read["submission_id"]].pop("evaluation_context")
        legacy = get(relay + "/result/" + read["submission_id"] + "?include_receipt=true")
        assert legacy["report"] == read["report"] and legacy["receipt"]["evaluation_context"] is None
        (task.task_dir / "judge/data/offset.txt").write_bytes(b"changed")
        blob_store = task.task_dir.parent.parent.parent / "blobs" / task.blobs[0].sha256
        blob_store.write_bytes(b"incorrect download")
        with pytest.raises(BuildImageError, match="downloaded sha256"):
            ensure_blobs(task)
        assert (task.task_dir / "judge/data/offset.txt").read_bytes() == b"changed"


def test_actual_run_agent_delivers_relay_and_generated_client_keeps_default_feedback(evaluator, monkeypatch):
    config, task, client, backend, owned_tags, states = evaluator
    tag = task.benchmark.name + ".client:qualification"
    owned_tags.append(tag)
    # The shipped Bash client requires curl, jq and GNU userland. Run it on
    # Linux rather than substituting host tools or changing its generated code.
    base = os.environ.get("SFORGE_TEST_DOCKER_BASE", "python:3.12-slim")
    dockerfile = (
        f"FROM {base}\nRUN apt-get update && apt-get install -y --no-install-recommends curl jq "
        "&& rm -rf /var/lib/apt/lists/*\nRUN mkdir -p /work\nWORKDIR /work\n"
    )
    image, build_log = client.images.build(fileobj=io.BytesIO(dockerfile.encode()), tag=tag, rm=True)
    list(build_log)
    image.tag(task.work_image_key)
    owned_tags.append(task.work_image_key)
    probe_run = "probe-" + task.benchmark.name
    # Exercise the owning run_agent entrypoint without installing or calling a
    # model. Only the probe agent is synthetic; its container, registration,
    # installed submit client, grading and feedback all use the native path.
    class FeedbackProbe(Agent):
        name = "feedback-probe"
        default_version = "fixture"
        api_key_env = "SYNTHETIC_KEY"

        def install(self, backend, handle, logger):
            pass

        def format_run_cmd(self, *args, **kwargs):
            probe = (
                "import json,os,urllib.request; "
                "ctx=json.load(urllib.request.urlopen(os.environ['SFORGE_FEEDBACK_URL']+'/context')); "
                f"assert ctx['run_id']=={probe_run!r}; print('CONTEXT '+json.dumps(ctx))"
            )
            return "python -c " + shlex.quote(probe) + " && printf '3\\n' > answer.txt && sforge-submit --details"

    from sforge.harness import network_isolation
    # Do not inspect or clean machine-wide iptables rules in an isolated test.
    monkeypatch.setattr(network_isolation, "cleanup_stale_chains", lambda logger: None)
    app = native.create_app(config)
    with serving(app) as url:
        state = states[0]
        port = url.rsplit(":", 1)[1]
        host = os.environ.get("SFORGE_TEST_JUDGE_HOST", "host.docker.internal")
        executed = run_agent(
            task, FeedbackProbe(config), config, backend, probe_run, timeout=45,
            judge_url=f"http://{host}:{port}", host_judge_url=url,
            disable_stop_hook=True, disable_auto_eval=True, disable_auto_resume=True,
        )
        assert not executed.timed_out, executed.agent_output
        assert executed.best_score == 10 and executed.agent_submissions == 1
        assert "Score:       10" in executed.agent_output and "synthetic" in executed.agent_output
        token, info = next(iter(state.tokens.items()))
        observed_context = json.loads(next(line[8:] for line in executed.agent_output.splitlines() if line.startswith("CONTEXT ")))
        assert observed_context == info["evaluation_context"]
        assert "token" not in observed_context and "admin_secret" not in observed_context
        relay = url + "/api/v1/feedback/" + info["feedback_relay_id"]
        history = get(url + "/api/v1/history?token=" + token)
        sid = history["entries"][0]["submission_id"]
        enriched = result(relay, sid)
        assert enriched["receipt"]["evaluation_context"] == observed_context
        graded = config.log_dir / "runs" / probe_run / "toy/submissions/agent-1/submission.tar.gz"
        assert hashlib.sha256(graded.read_bytes()).hexdigest() == enriched["receipt"]["archive_sha256"]
        assert "receipt" not in get(url + "/api/v1/result/" + sid)
