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

import hashlib

import pytest

from sforge.harness.docker_build import BuildImageError, ensure_blobs
from sforge.harness.task_spec import load_task

DATA = b"hidden tests"
SHA = hashlib.sha256(DATA).hexdigest()


def _task(tmp_path, sha=SHA, benchmark='name = "bench"\n'):
    d = tmp_path / "tasks" / "t1"
    (d / "environment").mkdir(parents=True)
    (d / "judge").mkdir()
    (d / "environment" / "Dockerfile").write_text("FROM scratch\n")
    (d / "judge" / "Dockerfile").write_text("FROM scratch\n")
    (d / "instruction.md").write_text("do it")
    (d / "task.toml").write_text(
        'id = "t1"\n[environment]\ncwd = "/w"\n[judge]\ncmd = "true"\n'
        f'[[blobs]]\npath = "judge/blobs/hidden.tar.gz"\nsha256 = "{sha}"\n'
    )
    (tmp_path / "benchmark.toml").write_text(benchmark)
    return d


def test_image_keys_use_the_benchmark_name(tmp_path):
    spec = load_task(_task(tmp_path))
    assert spec.work_image_key.startswith("bench.work.t1:")
    assert spec.judge_image_key.startswith("bench.judge.t1:")


def test_image_key_ignores_whether_blob_is_downloaded(tmp_path):
    d = _task(tmp_path)
    before = load_task(d).judge_image_key
    (d / "judge" / "blobs").mkdir()
    (d / "judge" / "blobs" / "hidden.tar.gz").write_bytes(DATA)
    assert load_task(d).judge_image_key == before
    assert load_task(d).work_image_key == load_task(_task(tmp_path / "x", sha="0" * 64)).work_image_key


def test_ensure_blobs_downloads_and_verifies(tmp_path, monkeypatch):
    store = tmp_path / "store"
    store.mkdir()
    (store / SHA).write_bytes(DATA)
    monkeypatch.setenv("SFORGE_BLOB_URL", store.as_uri())
    d = _task(tmp_path)
    ensure_blobs(load_task(d))
    assert (d / "judge" / "blobs" / "hidden.tar.gz").read_bytes() == DATA

    (store / SHA).write_bytes(b"tampered")
    (d / "judge" / "blobs" / "hidden.tar.gz").write_bytes(b"stale")
    with pytest.raises(BuildImageError):
        ensure_blobs(load_task(d))
    assert (d / "judge" / "blobs" / "hidden.tar.gz").read_bytes() == b"stale"


def test_missing_blob_download_failure_is_a_build_error(tmp_path, monkeypatch):
    (tmp_path / "empty").mkdir()
    monkeypatch.setenv("SFORGE_BLOB_URL", (tmp_path / "empty").as_uri())
    d = _task(tmp_path)
    with pytest.raises(BuildImageError, match="cannot download"):
        ensure_blobs(load_task(d))
    assert not (d / "judge" / "blobs" / "hidden.tar.gz.part").exists()


def test_blob_url_defaults_to_the_benchmark(tmp_path, monkeypatch):
    store = tmp_path / "store"
    store.mkdir()
    (store / SHA).write_bytes(DATA)
    monkeypatch.delenv("SFORGE_BLOB_URL", raising=False)
    d = _task(tmp_path, benchmark=f'name = "bench"\nblob_url = "{store.as_uri()}"\n')
    ensure_blobs(load_task(d))
    assert (d / "judge" / "blobs" / "hidden.tar.gz").read_bytes() == DATA
