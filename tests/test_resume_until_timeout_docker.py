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

"""Explicit opt-in real Docker/process/TCP qualification without model calls."""
from __future__ import annotations

import importlib
import inspect
import io
import json
import os
import shlex
import socket
import threading
import time
import uuid
from contextlib import contextmanager
from pathlib import Path, PurePosixPath
from types import SimpleNamespace

import docker
import pytest
import uvicorn

from sforge import cli
from sforge.harness import judge_server
from sforge.harness.agent.base import Agent
from sforge.harness.backend.docker_backend import DockerBackend
from sforge.harness.config import SForgeConfig
from sforge.harness.task_spec import load_task

runner = importlib.import_module("sforge.harness.run_agent")
pytestmark = pytest.mark.skipif(os.environ.get("SFORGE_RESUME_DOCKER_TEST") != "1",
    reason="Requires explicit isolated Docker/TCP resume qualification and a cached Python image")

PROBE = r'''
import io,json,os,sys,tarfile,time,uuid
from pathlib import Path
from urllib.request import Request,urlopen
from urllib.error import HTTPError
root=Path('/work/research');root.mkdir(exist_ok=True)
p=root/'session.json';phase=sys.argv[1]
if phase=='initial':
    assert not p.exists(), 'cold restart over retained session'
    state={'session':uuid.uuid4().hex,'visits':0,'cooldown_http':None}
else:
    assert p.exists(), 'resume lost original session'
    state=json.loads(p.read_text())
state['visits']+=1
p.write_text(json.dumps(state))
Path('/work/answer.txt').write_text('1\n')
def submit():
    archive=io.BytesIO()
    with tarfile.open(fileobj=archive,mode='w:gz') as tar:
        info=tarfile.TarInfo('answer.txt');info.size=2;tar.addfile(info,io.BytesIO(b'1\n'))
    boundary='fixture-'+uuid.uuid4().hex
    body=b''
    for key,value in [('token',os.environ['SFORGE_TOKEN']),('kind','agent')]:
        body+=f'--{boundary}\r\nContent-Disposition: form-data; name="{key}"\r\n\r\n{value}\r\n'.encode()
    body+=f'--{boundary}\r\nContent-Disposition: form-data; name="archive"; filename="answer.tar.gz"\r\nContent-Type: application/gzip\r\n\r\n'.encode()+archive.getvalue()+f'\r\n--{boundary}--\r\n'.encode()
    req=Request(os.environ['SFORGE_JUDGE_URL']+'/api/v1/submit',data=body,headers={'Content-Type':'multipart/form-data; boundary='+boundary})
    try:
        with urlopen(req,timeout=10) as r:return r.status,json.load(r)
    except HTTPError as e:return e.code,None
if state['visits']==1:
    status,response=submit();assert status==200,status
    state['accepted_submission']=response['submission_id']
elif state['visits']==2:
    state['cooldown_http'],_=submit();assert state['cooldown_http']==429
p.write_text(json.dumps(state))
print(json.dumps({'session':state['session'],'visits':state['visits'],'phase':phase,'cooldown_http':state['cooldown_http']}),flush=True)
time.sleep(float(os.environ.get('SYNTHETIC_SLEEP','1.05')))
if os.environ.get('SYNTHETIC_QUOTA_FAILURE')=='1':
    print(json.dumps({'type':'turn.failed','error':{'code':'insufficient_quota'}}),flush=True)
    sys.exit(1)
'''


@contextmanager
def serving(app):
    sock = socket.socket()
    sock.bind(("0.0.0.0", 0))
    server = uvicorn.Server(uvicorn.Config(app, log_level="error", lifespan="off"))
    thread = threading.Thread(target=server.run, kwargs={"sockets": [sock]}, daemon=True)
    thread.start()
    try:
        until = time.monotonic() + 10
        while not server.started and time.monotonic() < until:
            time.sleep(.01)
        assert server.started
        yield sock.getsockname()[1]
    finally:
        server.should_exit = True
        thread.join(10)
        sock.close()
        assert not thread.is_alive()


class ObservedBackend(DockerBackend):
    def __init__(self, client):
        super().__init__(client)
        self.created = []
        self.processes = []
        self.on_solver_start = None

    def create_container(self, *args, **kwargs):
        handle = super().create_container(*args, **kwargs)
        self.created.append(handle)
        return handle

    def exec_run_with_timeout(self, handle, cmd, **kwargs):
        is_solver = getattr(kwargs.get("log_file"), "name", None) == "agent_output.txt"
        if is_solver and self.on_solver_start is not None:
            callback, self.on_solver_start = self.on_solver_start, None
            callback()
        result = super().exec_run_with_timeout(handle, cmd, **kwargs)
        if is_solver:
            self.processes.append({"container_id": handle.id, "command": cmd[-1],
                "timeout": kwargs["timeout"], "exit_code": result.exit_code,
                "timed_out": result.timed_out, "elapsed_seconds": result.elapsed_seconds,
                "output": result.output})
        return result


class ProcessAgent(Agent):
    name = "process-probe"
    npm_package = "synthetic-local-probe"
    default_version = "fixture"
    api_key_env = "SYNTHETIC_UNUSED_KEY"
    run_cmd = "python /opt/sforge/probe.py initial"
    resume_cmd = "python /opt/sforge/probe.py resume"

    def install(self, backend, handle, logger):
        path = self._config.log_dir/"process-probe.py"
        path.write_text(PROBE)
        backend.exec_run(handle, ["mkdir", "-p", "/opt/sforge", "/work"])
        backend.copy_to_container(handle, path, PurePosixPath("/opt/sforge/probe.py"))


@pytest.fixture
def live(tmp_path, monkeypatch):
    client = docker.from_env()
    base = os.environ.get("SFORGE_TEST_DOCKER_BASE", "python:3.12-slim")
    image = client.images.get(base)  # Cached only; never pull or install a model.
    root = tmp_path/"benchmark"
    task_dir = root/"tasks/toy"
    (task_dir/"environment").mkdir(parents=True)
    (task_dir/"judge").mkdir()
    dockerfile = (f"FROM {base}\nRUN mkdir -p /work /opt/sforge\nWORKDIR /work\n"
        'ENTRYPOINT ["sh","-c","trap \'exit 0\' TERM; while :; do sleep 1; done"]\n')
    (task_dir/"environment/Dockerfile").write_text(dockerfile)
    (task_dir/"judge/Dockerfile").write_text(dockerfile)
    (task_dir/"instruction.md").write_text("Write answer.txt containing one.\n")
    name = "resume-" + uuid.uuid4().hex[:12]
    (root/"benchmark.toml").write_text(f'name = "{name}"\n')
    grade_cmd = "python -c " + shlex.quote(
        'import json,pathlib; pathlib.Path("/opt/sforge/result.json").write_text('
        'json.dumps(dict(score=1,valid=True,summary="synthetic")))')
    (task_dir/"task.toml").write_text(
        'id = "toy"\nversion = "1.0.0"\n[environment]\ncwd = "/work"\n'
        f'platform = "{image.attrs["Os"]}/{image.attrs["Architecture"]}"\ncpus = 1\nmemory = "128m"\n'
        '[submission]\npaths = ["answer.txt"]\n[judge]\n'
        f'cmd = {json.dumps(grade_cmd)}\n'
        'timeout_sec = 10\ncpus = 1\nmemory = "128m"\n[score]\ndirection = "maximize"\n')
    task = load_task(task_dir)
    tags = [task.work_image_key, task.judge_image_key]
    built, _ = client.images.build(fileobj=io.BytesIO(dockerfile.encode()),
        tag=tags[0], rm=True, pull=False, network_mode="none")
    built.tag(tags[1])
    config = SForgeConfig(benchmark_dir=root, log_dir=tmp_path/"logs", judge_cpu_limit=1,
        judge_mem_limit="128m", work_cpu_limit=1, work_mem_limit="128m")
    backend = ObservedBackend(client)
    states = []
    real_state = judge_server.JudgeState

    def observe_state(*args, **kwargs):
        state = real_state(*args, **kwargs)
        states.append(state)
        return state

    monkeypatch.setattr(judge_server, "JudgeState", observe_state)
    # This test qualifies resume/process/HTTP, not global iptables sweeping.
    # Never let a fixture touch network rules belonging to active experiments.
    import sforge.harness.network_isolation
    monkeypatch.setattr(sforge.harness.network_isolation, "cleanup_stale_chains", lambda *a, **k: None)
    try:
        app = judge_server.create_app(config)
        with serving(app) as port:
            host = os.environ.get("SFORGE_TEST_JUDGE_HOST", "host.docker.internal")
            yield SimpleNamespace(config=config, task=task, backend=backend, states=states,
                host_url=f"http://127.0.0.1:{port}", worker_url=f"http://{host}:{port}", name=name)
    finally:
        for handle in backend.created:
            try:
                client.containers.get(handle.id).remove(force=True)
            except docker.errors.NotFound:
                pass
        for tag in tags:
            client.images.remove(tag)
        client.close()


def execute(live, monkeypatch, *, timeout, shutdown_event=None, agent=None, expected_submissions=1):
    import sforge.harness.agent
    agent = agent or ProcessAgent(live.config)
    monkeypatch.setattr(sforge.harness.agent, "create_agent", lambda *a: agent)
    args = SimpleNamespace(agent=agent.name, model=None, timeout=timeout, eval_interval=0,
        judge_url=live.worker_url, host_judge_url=live.host_url,
        disable_auto_eval=True, disable_stop_hook=True, resume_until_timeout=True,
        max_submissions=3, submission_cooldown=3600, enable_internet=True)
    run = "probe-" + live.name
    value = cli._run_single_task(live.task, args, live.config, live.backend, run,
        shutdown_event=shutdown_event)
    assert len(live.backend.created) == 1
    assert len(live.states[0].tokens) == 1
    info = next(iter(live.states[0].tokens.values()))
    assert info["next_agent"] == expected_submissions + 1
    assert info["submission_cooldown"] == 3600
    assert info["max_agent_submissions"] == 3
    trial = live.config.log_dir/"runs"/run/"toy"
    history = json.loads((trial/"run_history.json").read_text())
    assert history["agent_submissions"] == expected_submissions and history["auto_submissions"] == 0
    assert all(e["valid"] is True for e in history["entries"])
    assert len({p["container_id"] for p in live.backend.processes}) == bool(live.backend.processes)
    assert all(p["command"] == agent.resume_cmd for p in live.backend.processes[1:])
    events = []
    for p in live.backend.processes:
        for line in p["output"].splitlines():
            try:
                event = json.loads(line)
            except ValueError:
                continue
            if "session" in event:
                events.append(event)
    assert len({e["session"] for e in events}) == bool(live.backend.processes)
    assert value["usage"]["requests"] == 0
    cooldown_statuses = sorted({e["cooldown_http"] for e in events if e.get("cooldown_http") is not None})
    if len(live.backend.processes) > 1:
        assert cooldown_statuses == [429]
    summary = {"source": runner.__file__, "supports_policy": "resume_until_timeout" in inspect.signature(runner.run_agent).parameters,
        "result": value, "actual_processes": len(live.backend.processes),
        "session_ids": sorted({e["session"] for e in events}),
        "one_container_and_registration": True, "next_agent": info["next_agent"],
        "submission_cooldown": info["submission_cooldown"], "cooldown_http_statuses": cooldown_statuses,
        "model_calls": value["usage"]["requests"]}
    evidence = os.environ.get("SFORGE_RESUME_TEST_EVIDENCE")
    if evidence:
        destination = Path(evidence)
        destination.mkdir(parents=True, exist_ok=True)
        (destination/(run+".json")).write_text(json.dumps(summary, indent=2)+"\n")
    return value, summary, trial


def test_same_session_crosses_100_until_one_deadline(live, monkeypatch):
    value, summary, trial = execute(live, monkeypatch, timeout=180)
    if os.environ.get("SFORGE_RESUME_BASE_CONTROL") != "1":
        assert summary["supports_policy"]
        assert summary["actual_processes"] > 101
        policy = value["resume_policy"]
        assert policy["stop_reason"] in ("budget_exhausted", "segment_timeout")
        assert policy["remaining_seconds"] < 1.1
        assert policy["deadline_unix"] - policy["started_at_unix"] == 180
        assert policy["total_elapsed_seconds"] >= policy["phase_elapsed_seconds"] >= value["runtime_seconds"]
        assert value["resume_count"] == summary["actual_processes"] - 1
        assert json.loads((trial/"resume-policy.json").read_text()) == policy
    else:
        # Counterfactual on the exact base: the CLI ignores the new argument.
        assert not summary["supports_policy"]
        assert summary["actual_processes"] == 101 and value["resume_count"] == 100
        assert not value["timed_out"] and value["runtime_seconds"] < 175
        assert "resume_policy" not in value


@pytest.mark.parametrize("failure", [False, True])
def test_stop_or_quota_failure_does_not_restart(live, monkeypatch, failure):
    if os.environ.get("SFORGE_RESUME_BASE_CONTROL") == "1":
        pytest.skip("Opt-in stop/failure qualification applies to the new head")
    stop = threading.Event()
    if failure:
        live.config.agent_extra_env["SYNTHETIC_QUOTA_FAILURE"] = "1"
        timer = None
    else:
        live.config.agent_extra_env["SYNTHETIC_SLEEP"] = "30"
        timer = threading.Timer(3, stop.set)
        live.backend.on_solver_start = timer.start
    try:
        value, summary, _ = execute(live, monkeypatch, timeout=30, shutdown_event=stop)
    finally:
        if timer:
            timer.cancel()
    assert summary["actual_processes"] == 1 and value["resume_count"] == 0
    assert value["resume_policy"]["stop_reason"] == ("process_failed" if failure else "shutdown_requested")
    assert value["resume_policy"]["remaining_seconds"] > 0


def test_slow_resume_format_cannot_dispatch_with_stale_time(live, monkeypatch):
    class SlowResume(ProcessAgent):
        def format_run_cmd(self, *args, resume=False, **kwargs):
            if resume:
                time.sleep(3)
            return super().format_run_cmd(*args, resume=resume, **kwargs)

    value, summary, _ = execute(live, monkeypatch, timeout=3, agent=SlowResume(live.config))
    assert summary["actual_processes"] == 1
    assert value["resume_policy"]["stop_reason"] == "budget_exhausted"
    assert value["resume_policy"]["phase_elapsed_seconds"] > 3


def test_initial_format_is_setup_before_solver_deadline(live, monkeypatch):
    class SlowInitial(ProcessAgent):
        def format_run_cmd(self, *args, resume=False, **kwargs):
            if not resume:
                time.sleep(2)
            return super().format_run_cmd(*args, resume=resume, **kwargs)

    value, summary, _ = execute(live, monkeypatch, timeout=3, agent=SlowInitial(live.config))
    assert summary["actual_processes"] >= 2
    policy = value["resume_policy"]
    assert policy["total_elapsed_seconds"] - policy["phase_elapsed_seconds"] >= 2


def test_stop_during_format_dispatches_no_process(live, monkeypatch):
    stop = threading.Event()

    class StopInFormat(ProcessAgent):
        def format_run_cmd(self, *args, **kwargs):
            time.sleep(.2)
            stop.set()
            return super().format_run_cmd(*args, **kwargs)

    value, summary, _ = execute(live, monkeypatch, timeout=3, shutdown_event=stop,
        agent=StopInFormat(live.config), expected_submissions=0)
    assert summary["actual_processes"] == 0
    assert value["resume_policy"]["stop_reason"] == "shutdown_requested"
    assert value["resume_policy"]["phase_elapsed_seconds"] == 0


@pytest.mark.parametrize("error", [OSError, KeyboardInterrupt])
def test_failed_resume_excludes_real_history_collection(live, monkeypatch, error):
    times = {}

    class FailedResume(ProcessAgent):
        def format_run_cmd(self, *args, resume=False, **kwargs):
            if resume:
                time.sleep(.2)
                times["failure"] = time.monotonic()
                raise error("Synthetic resume preparation failure")
            return super().format_run_cmd(*args, resume=resume, **kwargs)

    original_exec = live.backend.exec_run_with_timeout
    original_get = runner.requests.get

    def dispatch(*args, **kwargs):
        if getattr(kwargs.get("log_file"), "name", None) == "agent_output.txt":
            times.setdefault("dispatch", time.monotonic())
        return original_exec(*args, **kwargs)

    def history(url, *args, **kwargs):
        if "/api/v1/history" not in str(url):
            return original_get(url, *args, **kwargs)
        times["history_start"] = time.monotonic()
        time.sleep(2)
        response = original_get(url, *args, **kwargs)
        times["history_end"] = time.monotonic()
        return response

    monkeypatch.setattr(live.backend, "exec_run_with_timeout", dispatch)
    monkeypatch.setattr(runner.requests, "get", history)
    result = runner.run_agent(live.task, FailedResume(live.config), live.config, live.backend,
        "failed-" + live.name, timeout=30, resume_until_timeout=True,
        judge_url=live.worker_url, host_judge_url=live.host_url,
        disable_auto_eval=True, disable_stop_hook=True,
        max_submissions=3, submission_cooldown=3600)
    policy = result.resume_policy
    assert len(live.backend.processes) == len(live.backend.created) == 1
    assert len(live.states[0].tokens) == 1
    token, info = next(iter(live.states[0].tokens.items()))
    assert info["next_agent"] == 2 and info["submission_cooldown"] == 3600
    history = original_get(live.host_url + "/api/v1/history", params={"token": token}, timeout=10).json()
    assert history["agent_submissions"] == 1 and history["entries"][0]["valid"] is True
    assert policy["stop_reason"] == ("interrupted" if error is KeyboardInterrupt else "runner_error")
    assert times["history_start"] > times["failure"]
    # The production dispatch receipt precedes the actual process. Retain room
    # for its IO without admitting this two-second post-failure HTTP delay.
    assert policy["phase_elapsed_seconds"] <= times["failure"] - times["dispatch"] + .5
    collection = times["history_end"] - times["history_start"]
    assert policy["total_elapsed_seconds"] - policy["phase_elapsed_seconds"] >= collection - .5
    assert policy["phase_elapsed_seconds"] + policy["remaining_seconds"] == pytest.approx(30)
