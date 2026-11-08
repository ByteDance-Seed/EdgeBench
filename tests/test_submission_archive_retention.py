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

"""Exercise the generated client and its actual multipart upload."""

from __future__ import annotations

from email import policy
from email.parser import BytesParser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import os
import subprocess
import tarfile
from threading import Thread

import pytest

from sforge.harness.evolve_scripts import generate_submit_script


@pytest.fixture
def native_client(tmp_path):
    script = tmp_path / "sforge-submit"
    work = tmp_path / "work"
    work.mkdir()
    (work / "answer.py").write_text("answer = 2\n")
    saved = tmp_path / "research files"
    saved.mkdir()
    request_temp = tmp_path / "request-temp"
    request_temp.mkdir()
    uploads = []
    response_lost = []

    class Judge(BaseHTTPRequestHandler):
        def do_POST(self):
            assert self.path == "/api/v1/submit"
            payload = self.rfile.read(int(self.headers["Content-Length"]))
            mime = b"Content-Type: " + self.headers["Content-Type"].encode() + b"\r\n\r\n" + payload
            form = BytesParser(policy=policy.default).parsebytes(mime)
            archive, = [field for field in form.iter_parts() if field.get_param(
                "name", header="Content-Disposition") == "archive"]
            uploads.append(archive.get_payload(decode=True))
            if response_lost:
                self.close_connection = True
                return
            self.send_response(429)
            self.end_headers()
            self.wfile.write(b'{"detail":"fixture cooldown"}')

    server = ThreadingHTTPServer(("127.0.0.1", 0), Judge)
    thread = Thread(target=server.serve_forever, daemon=True)
    thread.start()

    def run(*args, submit_paths=("answer.py",)):
        script.write_text(generate_submit_script(str(work), list(submit_paths), []))
        result = subprocess.run(
            ["bash", str(script), *map(str, args)], cwd=work, check=False,
            env={**os.environ, "TMPDIR": str(request_temp), "COPYFILE_DISABLE": "1",
                 "SFORGE_JUDGE_URL": f"http://127.0.0.1:{server.server_port}",
                 "SFORGE_TOKEN": "fixture-token"},
            capture_output=True, text=True, timeout=10,
        )
        assert not list(request_temp.iterdir())
        return result

    try:
        yield run, uploads, response_lost, work, saved
    finally:
        server.shutdown()
        server.server_close()
        thread.join()


@pytest.mark.parametrize("lost", [False, True])
def test_retained_bytes_are_the_uploaded_archive_even_without_a_receipt(native_client, lost):
    run, uploads, response_lost, _, saved = native_client
    if lost:
        response_lost.append(True)
    result = run("--retain-archive", saved)
    assert result.returncode != 0
    archive, = saved.glob("*/submission.tar.gz")
    assert str(archive) in result.stderr
    assert uploads == [archive.read_bytes()]
    assert archive.parent.stat().st_mode & 0o777 == 0o700
    assert archive.stat().st_mode & 0o777 == 0o600
    with tarfile.open(archive, "r:gz") as package:
        assert package.getnames() == ["answer.py"]
        assert package.extractfile("answer.py").read() == b"answer = 2\n"


def test_unselected_retention_leaves_no_archive(native_client):
    run, uploads, _, _, saved = native_client
    result = run()
    assert result.returncode != 0
    assert len(uploads) == 1
    assert "Saved submission archive" not in result.stderr
    assert not list(saved.iterdir())


def test_rejects_unsafe_or_inapplicable_retention_before_upload(native_client):
    run, uploads, _, work, saved = native_client
    assert "outside the work tree" in run("--retain-archive", work).stderr
    assert "overlaps a submitted path" in run("--retain-archive", saved, submit_paths=("..",)).stderr
    assert "requires a new submission" in run("--list", "--retain-archive", saved).stderr
    assert not uploads
    assert not list(saved.iterdir())
