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

"""Docker lifecycle contracts.

Real-daemon cases require SFORGE_DOCKER_TEST_IMAGE naming an already-cached
image containing python3 and /bin/sh. They never pull or build an image.
"""

import json
import os
import threading
import time
import uuid
from unittest.mock import MagicMock

import pytest

from sforge.harness.backend.docker_backend import DockerBackend


def test_container_init_defaults_on():
    client = MagicMock()
    backend = DockerBackend(client)
    handle = backend.create_container("fixture-image", "fixture-container")
    client.containers.create.assert_called_once_with(
        "fixture-image", name="fixture-container", detach=True,
        command="tail -f /dev/null", environment={}, init=True,
    )
    assert handle.raw is client.containers.create.return_value


def test_custom_pid_one_opt_out_preserves_creation_options():
    client = MagicMock()
    backend = DockerBackend(client)
    backend.create_container(
        "fixture-image", "fixture-container", command="custom-init",
        environment={"EXAMPLE": "value"}, extra_hosts={"example": "127.0.0.1"},
        cap_drop=["NET_RAW"], cpu_limit=2, mem_limit="512m", user="1000",
        init=False,
    )
    client.containers.create.assert_called_once_with(
        "fixture-image", name="fixture-container", detach=True,
        command="custom-init", environment={"EXAMPLE": "value"}, init=False,
        extra_hosts={"example": "127.0.0.1"}, cap_drop=["NET_RAW"],
        nano_cpus=2_000_000_000, mem_limit="512m", user="1000",
    )


@pytest.fixture
def real_container():
    image = os.environ.get("SFORGE_DOCKER_TEST_IMAGE")
    if not image:
        pytest.skip("Set SFORGE_DOCKER_TEST_IMAGE for real Docker lifecycle tests")
    backend = DockerBackend()
    # An explicit image with a missing daemon/cache is a failed qualification,
    # not a reason to silently skip a requested integration test.
    backend.client.images.get(image)
    handles = []

    def create(**kwargs):
        handle = backend.create_container(
            image, f"sforge-lifecycle-test-{uuid.uuid4().hex}",
            cpu_limit=1, mem_limit="128m", **kwargs,
        )
        handles.append(handle)
        backend.start_container(handle)
        return backend, handle

    yield create
    try:
        for handle in handles:
            if backend.container_exists(handle.name):
                backend.cleanup_container(handle)
            assert not backend.container_exists(handle.name)
    finally:
        backend.client.close()


_ORPHAN_CHILDREN = """
import json, os
pids = []
for _ in range(4):
    read_fd, write_fd = os.pipe()
    pid = os.fork()
    if pid == 0:
        os.close(read_fd)
        child = os.fork()
        if child == 0:
            os._exit(0)
        os.write(write_fd, str(child).encode())
        os._exit(0)
    os.close(write_fd)
    pids.append(int(os.read(read_fd, 32)))
    os.close(read_fd)
    os.waitpid(pid, 0)
print(json.dumps(pids))
"""

_COUNT_ZOMBIES = """
from pathlib import Path
count = 0
for path in Path('/proc').glob('[0-9]*/stat'):
    try:
        fields = path.read_text().rsplit(')', 1)[1].split()
        count += fields[0] == 'Z'
    except FileNotFoundError:
        pass
print(count)
"""


def _zombies(backend, handle):
    result = backend.exec_run(handle, ["python3", "-c", _COUNT_ZOMBIES])
    assert result.exit_code == 0, result.output
    return int(result.output.strip())


def _child_states(backend, handle, pids):
    script = """
import json, sys
from pathlib import Path
states = []
for pid in json.loads(sys.argv[1]):
    try:
        states.append(Path(f'/proc/{pid}/stat').read_text().rsplit(')', 1)[1].split()[0])
    except FileNotFoundError:
        states.append(None)
print(json.dumps(states))
"""
    result = backend.exec_run(handle, ["python3", "-c", script, json.dumps(pids)])
    assert result.exit_code == 0, result.output
    return json.loads(result.output)


@pytest.mark.parametrize("init", [True, False])
def test_orphan_reaping_and_negative_control(real_container, init):
    backend, handle = real_container(**({} if init else {"init": False}))
    handle.raw.reload()
    assert handle.raw.attrs["HostConfig"]["Init"] is init
    assert _zombies(backend, handle) == 0
    for batch in range(1, 4):
        result = backend.exec_run(handle, ["python3", "-c", _ORPHAN_CHILDREN])
        assert result.exit_code == 0, result.output
        pids = json.loads(result.output)
        expected = 0 if init else 4 * batch
        expected_states = [None if init else "Z"] * 4
        deadline = time.monotonic() + 5
        states = _child_states(backend, handle, pids)
        while states != expected_states and time.monotonic() < deadline:
            time.sleep(0.05)
            states = _child_states(backend, handle, pids)
        assert states == expected_states
        assert _zombies(backend, handle) == expected


@pytest.mark.parametrize("cancel", [False, True])
def test_interrupted_exec_then_cleanup_releases_stream(real_container, tmp_path, cancel):
    backend, handle = real_container()
    shutdown = threading.Event()
    ready = threading.Event()
    existing_threads = set(threading.enumerate())

    def on_chunk(chunk):
        if b"ready" in chunk:
            ready.set()
            if cancel:
                shutdown.set()

    log_file = tmp_path / "command.log"
    result = backend.exec_run_with_timeout(
        handle, ["/bin/sh", "-c", "echo ready; exec sleep 60"],
        timeout=5, shutdown_event=shutdown, log_file=log_file, on_chunk=on_chunk,
    )
    assert ready.is_set()
    assert result.timed_out and result.exit_code == -1
    assert "ready" in result.output
    assert b"ready" in log_file.read_bytes()
    backend.cleanup_container(handle)
    assert not backend.container_exists(handle.name)
    # Removing the interrupted container must also close its active exec stream.
    for thread in set(threading.enumerate()) - existing_threads:
        thread.join(timeout=5)
        assert not thread.is_alive()


def test_init_forwards_stop_to_custom_command(real_container):
    command = (
        'python3 -u -c "import signal,time,sys; '
        "signal.signal(signal.SIGTERM, lambda *args: (print('stopped'), sys.exit(0))); "
        "print('ready'); time.sleep(60)\""
    )
    backend, handle = real_container(command=command)
    deadline = time.monotonic() + 5
    while b"ready" not in handle.raw.logs():
        assert time.monotonic() < deadline
        time.sleep(0.05)
    handle.raw.stop(timeout=5)
    assert handle.raw.wait(timeout=5)["StatusCode"] == 0
    assert b"stopped" in handle.raw.logs()
    backend.cleanup_container(handle)
    assert not backend.container_exists(handle.name)
