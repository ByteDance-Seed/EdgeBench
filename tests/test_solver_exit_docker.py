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

"""Native Docker exit evidence; use an existing local test image only."""

import threading

import pytest

from sforge.harness.backend.docker_backend import DockerBackend, DockerContainerHandle
from sforge.harness.run_agent import _solver_segment_result
from test_docker_exec_lifecycle import container  # noqa: F401 -- pytest fixture


@pytest.mark.parametrize("body,code", [
    ("raise SystemExit(0)", 0),
    ("raise SystemExit(7)", 7),
    ("raise SystemExit(143)", 143),
    ("import os,signal; os.kill(os.getpid(),signal.SIGTERM)", 143),
])
def test_docker_exit_observation_never_infers_a_signal(container, body, code):
    result = DockerBackend(container.client).exec_run_with_timeout(
        DockerContainerHandle(container), ["python3", "-c", body], timeout=5)
    assert result.exit_code == code and result.timed_out is False
    assert result.terminal_observed is True and result.native_exit_code == code
    assert result.termination_signal is None
    observed = _solver_segment_result(result, False)
    assert observed["status"] == ("normal_exit" if code == 0 else "nonzero_exit")
    assert observed["termination_signal"] is None


def test_docker_timeout_preserves_native_code_beside_legacy_sentinel(container):
    result = DockerBackend(container.client).exec_run_with_timeout(
        DockerContainerHandle(container), ["sleep", "60"], timeout=1)
    assert result.timed_out and result.exit_code == -1
    assert result.terminal_observed is True
    assert type(result.native_exit_code) is int and result.native_exit_code >= 0
    assert _solver_segment_result(result, False)["status"] == "timed_out"


def test_cancel_before_dispatch_has_no_native_exit_status(container):
    stop = threading.Event()
    stop.set()
    result = DockerBackend(container.client).exec_run_with_timeout(
        DockerContainerHandle(container), ["touch", "/tmp/should-not-exist"],
        timeout=5, shutdown_event=stop)
    assert result.timed_out and result.exit_code == -1
    assert result.terminal_observed is False and result.native_exit_code is None
    assert result.termination_signal is None
    assert container.exec_run(["test", "!", "-e", "/tmp/should-not-exist"]).exit_code == 0
