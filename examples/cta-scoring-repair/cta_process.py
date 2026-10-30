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

"""Bound the evaluator process group while preserving a small diagnostic tail."""
from __future__ import annotations

import os
import signal
import subprocess
import tempfile
from typing import BinaryIO


def _tail(stream: BinaryIO, size: int = 8000) -> str:
    stream.seek(0, os.SEEK_END)
    stream.seek(max(0, stream.tell() - size))
    return stream.read().decode('utf-8', errors='replace')


def run_evaluator(command: list[str], *, cwd: str, timeout: float) -> subprocess.CompletedProcess[str]:
    # Files avoid communicate() waiting forever on inherited descendant pipes.
    with tempfile.TemporaryFile() as stdout, tempfile.TemporaryFile() as stderr:
        process = subprocess.Popen(command, cwd=cwd, stdout=stdout, stderr=stderr,
                                   start_new_session=True)
        timed_out = False
        try:
            process.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            timed_out = True
        finally:
            # The session belongs only to this evaluator. Clean descendants even
            # after a successful parent exit, before scoring reads their output.
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            process.wait(timeout=5)
        out, err = _tail(stdout), _tail(stderr)
        if timed_out:
            raise subprocess.TimeoutExpired(command, timeout, output=out, stderr=err)
        return subprocess.CompletedProcess(command, process.returncode, out, err)
