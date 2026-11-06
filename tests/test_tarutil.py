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

from __future__ import annotations

import io
import tarfile

import pytest

from sforge.harness import tarutil


def _tar(*members: tuple[str, bytes]) -> tarfile.TarFile:
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w") as tar:
        for name, data in members:
            info = tarfile.TarInfo(name)
            info.size = len(data)
            tar.addfile(info, io.BytesIO(data))
    buf.seek(0)
    return tarfile.open(fileobj=buf)


@pytest.fixture(params=["filter", "fallback"])
def mode(request, monkeypatch):
    if request.param == "fallback":
        monkeypatch.delattr(tarfile, "data_filter", raising=False)
    return request.param


def test_extracts_normal_members(tmp_path, mode):
    tarutil.safe_extractall(_tar(("root/.claude/projects/p/s.jsonl", b"{}")), tmp_path)
    assert (tmp_path / "root/.claude/projects/p/s.jsonl").read_bytes() == b"{}"


def test_rejects_escaping_members(tmp_path, mode):
    with pytest.raises(tarfile.TarError):
        tarutil.safe_extractall(_tar(("../escape.txt", b"x")), tmp_path / "d")
    assert not (tmp_path / "escape.txt").exists()
