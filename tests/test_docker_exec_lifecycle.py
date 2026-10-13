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

"""Opt-in real Docker regressions; only use an already available test image."""

import os
import threading

import docker
import pytest

from sforge.harness import docker_utils
from sforge.harness.backend.docker_backend import DockerBackend, DockerContainerHandle


@pytest.fixture
def container():
    image = os.environ.get("SFORGE_DOCKER_TEST_IMAGE")
    if not image:
        pytest.skip("set SFORGE_DOCKER_TEST_IMAGE to a cached bash/python3 image")
    client = docker.from_env()
    client.images.get(image)  # Never pull an image from this test.
    owned = client.containers.run(
        image,
        ["sleep", "120"],
        detach=True,
        network_disabled=True,
        labels={"test": "sforge-exec-lifecycle"},
    )
    try:
        yield owned
    finally:
        owned.remove(force=True)
        assert not client.containers.list(all=True, filters={"id": owned.id})
        client.close()


@pytest.fixture(params=["legacy", "backend"])
def execute(request, container):
    def run(command, **kwargs):
        if request.param == "legacy":
            return docker_utils._exec_run(container, command, **kwargs)
        result = DockerBackend(container.client).exec_run_with_timeout(
            DockerContainerHandle(container), command, **kwargs
        )
        return result.output, result.exit_code, result.timed_out, result.elapsed_seconds

    return run


def test_timeout_stops_before_return_and_drains_final_output(
    container, execute, tmp_path
):
    body = """import signal,time,sys,os
open('/tmp/solver.pid','w').write(str(os.getpid()))
def stop(*_):
    time.sleep(.2)
    open('/tmp/submission','w').write('final')
    print('FINAL_RECEIPT',flush=True)
    sys.exit(0)
signal.signal(signal.SIGTERM,stop)
print('READY',flush=True)
time.sleep(60)
"""
    log = tmp_path / "agent.log"
    output, code, timed_out, elapsed = execute(
        ["python3", "-u", "-c", body], timeout=1, log_file=log
    )
    assert timed_out and code == -1
    assert "FINAL_RECEIPT" in output
    assert log.read_bytes() == output.encode()
    probe = container.exec_run(
        [
            "python3",
            "-c",
            "from pathlib import Path; p=Path('/tmp/solver.pid').read_text(); assert not Path('/proc/'+p).exists(); assert Path('/tmp/submission').read_text()=='final'",
        ]
    )
    assert probe.exit_code == 0, probe.output
    assert elapsed >= 1


def test_cancel_during_create_does_not_dispatch(container, execute, monkeypatch):
    stop = threading.Event()
    create = container.client.api.exec_create
    started = []
    start = container.client.api.exec_start

    def after_create(*args, **kwargs):
        result = create(*args, **kwargs)
        if "sforge-exec-supervisor" in str(args):
            stop.set()
        return result

    def record_start(exec_id, **kwargs):
        started.append(exec_id)
        return start(exec_id, **kwargs)

    monkeypatch.setattr(container.client.api, "exec_create", after_create)
    monkeypatch.setattr(container.client.api, "exec_start", record_start)
    output, code, timed_out, _ = execute(
        ["touch", "/tmp/dispatched"], timeout=5, shutdown_event=stop
    )
    # Only provisioning/cleanup control execs may start. No solver invocation.
    solver_starts = [
        x
        for x in started
        if container.client.api.exec_inspect(x)["ProcessConfig"]["arguments"][1:2]
        == [docker_utils._EXEC_SUPERVISOR]
    ]
    assert not solver_starts
    assert output == "" and code == -1 and timed_out
    assert container.exec_run(["test", "!", "-e", "/tmp/dispatched"]).exit_code == 0


@pytest.mark.parametrize("exit_code", [0, 17])
def test_normal_exit_preserves_bytes_arguments_and_unrelated_process(
    container, execute, tmp_path, exit_code
):
    neighbor = container.exec_run(["sleep", "90"], detach=True)
    assert neighbor.exit_code is None
    script = r"""import os,sys
assert os.getcwd()=='/tmp'
assert os.environ['EXAMPLE_VALUE']==sys.argv[1]
sys.stdout.buffer.write(b'hello\xff\xe4\xb8\xad\n')
sys.stderr.write('stderr\n')
sys.exit(int(sys.argv[2]))
"""
    value = "literal $HOME `cmd` ' quote \n"
    chunks = []
    log = tmp_path / "output"
    log.write_bytes(b"prior\n")
    result = execute(
        ["python3", "-c", script, value, str(exit_code)],
        timeout=5,
        workdir="/tmp",
        environment={"EXAMPLE_VALUE": value},
        log_file=log,
        log_append=True,
        on_chunk=chunks.append,
    )
    assert result[1:3] == (exit_code, False)
    assert b"hello\xff\xe4\xb8\xad\n" in b"".join(chunks)
    assert result[0] == b"".join(chunks).decode(errors="replace")
    assert log.read_bytes() == b"prior\n" + b"".join(chunks)
    probe = container.exec_run(
        [
            "python3",
            "-c",
            "from pathlib import Path; assert sum(p.read_bytes()==b'sleep\\x0090\\x00' for p in Path('/proc').glob('[0-9]*/cmdline'))==1",
        ]
    )
    assert probe.exit_code == 0, probe.output
    assert (
        container.exec_run(["bash", "-c", 'compgen -G "/tmp/sforge-exec-*"']).exit_code
        == 1
    )


def test_explicit_cancellation_drains_shutdown(container, execute, tmp_path):
    stop = threading.Event()
    chunks = []

    def on_chunk(chunk):
        chunks.append(chunk)
        if b"READY" in chunk:
            stop.set()

    body = """import signal,time,sys
def stop(*_):
    time.sleep(.1)
    print('STOPPED',flush=True)
    sys.exit(0)
signal.signal(signal.SIGTERM,stop)
print('READY',flush=True)
time.sleep(60)
"""
    result = execute(
        ["python3", "-u", "-c", body],
        timeout=None,
        shutdown_event=stop,
        on_chunk=on_chunk,
        log_file=tmp_path / "out",
    )
    assert result[1:3] == (-1, True)
    assert result[0] == "READY\nSTOPPED\n"
    assert (tmp_path / "out").read_text() == result[0]
    assert b"".join(chunks).decode() == result[0]


def test_force_stop_closed_output_and_child_process(container, execute, monkeypatch):
    monkeypatch.setattr(docker_utils, "_EXEC_SHUTDOWN_GRACE", 1)
    body = """import os,signal,time,subprocess
from pathlib import Path
signal.signal(signal.SIGTERM,signal.SIG_IGN)
p=subprocess.Popen(['sleep','60'])
Path('/tmp/owned').write_text(str(os.getpid())+' '+str(p.pid))
os.close(1);os.close(2)
time.sleep(60)
"""
    result = execute(["python3", "-c", body], timeout=1)
    assert result[1:3] == (-1, True)
    assert result[3] < 5
    probe = container.exec_run(
        [
            "python3",
            "-c",
            "from pathlib import Path; ids=Path('/tmp/owned').read_text().split(); assert all(not Path('/proc/'+p+'/stat').exists() or Path('/proc/'+p+'/stat').read_text().split(') ')[1].split()[0]=='Z' for p in ids)",
        ]
    )
    assert probe.exit_code == 0, probe.output


def test_normal_parent_exit_cleans_background_pipe_holder(
    container, execute, monkeypatch
):
    monkeypatch.setattr(docker_utils, "_EXEC_SHUTDOWN_GRACE", 1)
    body = """import subprocess
from pathlib import Path
p=subprocess.Popen(['sleep','60'])
Path('/tmp/child').write_text(str(p.pid))
print('DONE',flush=True)
"""
    result = execute(["python3", "-c", body], timeout=5)
    assert result[0] == "DONE\n" and result[1:3] == (0, False)
    assert result[3] < 3
    probe = container.exec_run(
        [
            "python3",
            "-c",
            "from pathlib import Path; p=Path('/tmp/child').read_text(); s=Path('/proc/'+p+'/stat'); assert not s.exists() or s.read_text().split(') ')[1].split()[0]=='Z'",
        ]
    )
    assert probe.exit_code == 0, probe.output


def test_nonroot_and_string_command(container, execute):
    result = execute('printf "literal space"', user="65534", timeout=5)
    assert result[0] == "literal space" and result[1:3] == (0, False)


def test_preset_cancellation_creates_nothing(container, execute, monkeypatch):
    stop = threading.Event()
    stop.set()

    def unexpected(*args, **kwargs):
        raise AssertionError("must not create or dispatch an exec")

    monkeypatch.setattr(container.client.api, "exec_create", unexpected)
    result = execute(["touch", "/tmp/unexpected"], shutdown_event=stop)
    assert result[:3] == ("", -1, True)


def test_start_failure_keeps_original_error(container, execute, monkeypatch):
    class StartFailure(Exception):
        pass

    original = container.client.api.exec_start
    monkeypatch.setattr(docker_utils, "_EXEC_SHUTDOWN_GRACE", 1)
    monkeypatch.setattr(docker_utils, "_EXEC_DRAIN_GRACE", 1)

    def fail_start(exec_id, **kwargs):
        if kwargs.get("stream"):
            raise StartFailure("synthetic start rejection")
        return original(exec_id, **kwargs)

    monkeypatch.setattr(container.client.api, "exec_start", fail_start)
    with pytest.raises(StartFailure, match="synthetic start rejection"):
        execute(["touch", "/tmp/dispatched"], timeout=3)
    assert container.exec_run(["test", "!", "-e", "/tmp/dispatched"]).exit_code == 0


def test_stream_failure_stops_command_and_preserves_error(
    container, execute, monkeypatch, tmp_path
):
    class StreamFailure(Exception):
        pass

    original = container.client.api.exec_start

    def fail_stream(exec_id, **kwargs):
        stream = original(exec_id, **kwargs)
        if not kwargs.get("stream"):
            return stream

        def chunks():
            try:
                yield next(stream)
                raise StreamFailure("synthetic read failure")
            finally:
                stream.close()

        return chunks()

    monkeypatch.setattr(container.client.api, "exec_start", fail_stream)
    with pytest.raises(StreamFailure, match="synthetic read failure"):
        execute(
            ["bash", "-c", "echo $$ > /tmp/solver.pid; echo READY; sleep 60"],
            timeout=5,
            log_file=tmp_path / "log",
        )
    assert (tmp_path / "log").read_text() == "READY\n"
    probe = container.exec_run(
        [
            "python3",
            "-c",
            "from pathlib import Path; p=Path('/tmp/solver.pid').read_text().strip(); assert not Path('/proc/'+p).exists()",
        ]
    )
    assert probe.exit_code == 0, probe.output


def test_missing_shutdown_receipt_is_not_success(container, execute, monkeypatch):
    monkeypatch.setattr(docker_utils, "_EXEC_SUPERVISOR", "exit 0")
    with pytest.raises(RuntimeError, match="shutdown"):
        execute(["touch", "/tmp/dispatched"], timeout=2)
    assert container.exec_run(["test", "!", "-e", "/tmp/dispatched"]).exit_code == 0


def test_cancel_before_remote_start_preserves_no_dispatch(
    container, execute, monkeypatch
):
    released = threading.Event()
    start = container.client.api.exec_start
    control = container.exec_run

    def delayed_start(exec_id, **kwargs):
        if kwargs.get("stream"):
            assert released.wait(3), "stop request was not sent"
        return start(exec_id, **kwargs)

    def release_on_stop(command, **kwargs):
        result = control(command, **kwargs)
        if ': > "$1/stop"' in command:
            released.set()
        return result

    monkeypatch.setattr(container.client.api, "exec_start", delayed_start)
    monkeypatch.setattr(container, "exec_run", release_on_stop)
    result = execute(["touch", "/tmp/dispatched"], timeout=0.2)
    assert result[:3] == ("", -1, True)
    assert container.exec_run(["test", "!", "-e", "/tmp/dispatched"]).exit_code == 0


def test_keyboard_interrupt_stops_before_propagating(
    container, execute, monkeypatch, tmp_path
):
    join = threading.Thread.join
    interrupted = False

    def interrupt_once(thread, *args, **kwargs):
        nonlocal interrupted
        if thread.name == "sforge-docker-exec" and not interrupted:
            interrupted = True
            # Observe startup before injecting the host interruption.
            assert ready.wait(3)
            raise KeyboardInterrupt("synthetic host cancel")
        return join(thread, *args, **kwargs)

    ready = threading.Event()
    monkeypatch.setattr(threading.Thread, "join", interrupt_once)
    with pytest.raises(KeyboardInterrupt, match="synthetic host cancel"):
        execute(
            ["bash", "-c", "echo $$ > /tmp/solver.pid; echo READY; sleep 60"],
            timeout=5,
            log_file=tmp_path / "out",
            on_chunk=lambda _: ready.set(),
        )
    probe = container.exec_run(
        [
            "python3",
            "-c",
            "from pathlib import Path; p=Path('/tmp/solver.pid').read_text().strip(); assert not Path('/proc/'+p).exists()",
        ]
    )
    assert probe.exit_code == 0, probe.output
    assert (tmp_path / "out").read_text() == "READY\n"


def test_public_exit_code_api(container):
    result = docker_utils.exec_run_with_exit_code(
        container, ["bash", "-c", "printf original; exit 7"]
    )
    assert result[:3] == ("original", 7, False)
    result = DockerBackend(container.client).exec_run_with_exit_code(
        DockerContainerHandle(container), ["bash", "-c", "printf original; exit 7"]
    )
    assert (result.output, result.exit_code, result.timed_out) == ("original", 7, False)
    result = docker_utils.exec_run_with_timeout(container, ["printf", "original"])
    assert result[0:2] == ("original", False) and len(result) == 3
