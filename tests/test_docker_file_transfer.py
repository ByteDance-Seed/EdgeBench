"""File-transfer fidelity and spool lifetime without requiring a Docker daemon."""
import errno
import hashlib
import io
import os
from pathlib import PurePosixPath
import tarfile

import docker.errors
import pytest

from sforge.harness.backend import docker_backend as transport


class Container:
    def __init__(self, *, fail=False):
        self.fail = fail
        self.upload = None
        self.members = {}

    def exec_run(self, command):
        pass

    def put_archive(self, parent, data):
        self.upload = data
        assert parent == "/destination"
        assert not isinstance(data, (bytes, bytearray, io.BytesIO))
        assert os.fstat(data.fileno()).st_size > 0
        if self.fail:
            raise docker.errors.APIError("synthetic upload failure")
        with tarfile.open(fileobj=data) as archive:
            for member in archive:
                self.members[member.name] = (member.mode, member.type, member.linkname,
                    archive.extractfile(member).read() if member.isfile() else None)


@pytest.mark.parametrize("size", [0, 17, 2 << 20])
def test_upload_preserves_files_modes_nested_paths_and_stream_lifetime(tmp_path, size):
    source = tmp_path / "source"
    (source / "nested").mkdir(parents=True)
    data = b"payload" * (size // 7) + b"x" * (size % 7)
    (source / "nested/data").write_bytes(data)
    (source / "nested/data").chmod(0o640)
    box = Container()
    backend = transport.DockerBackend(client=object())
    backend.copy_to_container(transport.DockerContainerHandle(box), source,
                              PurePosixPath("/destination/renamed"))
    actual = box.members["renamed/nested/data"]
    assert actual[0] == 0o640
    assert hashlib.sha256(actual[3]).digest() == hashlib.sha256(data).digest()
    assert box.upload.closed


def test_upload_preserves_native_link_representation(tmp_path):
    source = tmp_path / "source"
    source.mkdir()
    (source / "data").write_bytes(b"linked content")
    try:
        (source / "symbolic").symlink_to("data")
        os.link(source / "data", source / "hard")
    except OSError:
        pytest.skip("native links unavailable")
    box = Container()
    transport.DockerBackend(client=object()).copy_to_container(
        transport.DockerContainerHandle(box), source, PurePosixPath("/destination/tree"))
    assert box.members["tree/symbolic"][1:3] == (tarfile.SYMTYPE, "data")
    assert box.members["tree/hard"][1:3] == (tarfile.LNKTYPE, "tree/data")


@pytest.mark.parametrize("failure", ["upload", "source", "space"])
def test_upload_failure_closes_spool(tmp_path, monkeypatch, failure):
    source = tmp_path / "data"
    source.write_bytes(b"payload")
    box = Container(fail=failure == "upload")
    real = transport.tempfile.TemporaryFile
    spools = []

    def temporary():
        spool = real(dir=tmp_path)
        spools.append(spool)
        if failure == "space":
            def full(*args):
                raise OSError(errno.ENOSPC, "synthetic spool full")
            monkeypatch.setattr(spool, "write", full)
        return spool

    monkeypatch.setattr(transport.tempfile, "TemporaryFile", temporary)
    if failure == "source":
        source.unlink()
    with pytest.raises((OSError, docker.errors.APIError)):
        transport.DockerBackend(client=object()).copy_to_container(
            transport.DockerContainerHandle(box), source, PurePosixPath("/destination/data"))
    assert len(spools) == 1 and spools[0].closed


def test_empty_destination_is_rejected_before_spooling(tmp_path, monkeypatch):
    monkeypatch.setattr(transport.tempfile, "TemporaryFile", lambda: pytest.fail("spool created"))
    with pytest.raises(ValueError, match="parent directory"):
        transport.DockerBackend(client=object()).copy_to_container(
            transport.DockerContainerHandle(Container()), tmp_path, PurePosixPath("data"))


def test_unrelated_download_api_still_returns_bytes():
    class Download:
        def get_archive(self, path):
            assert path == "/source"
            return iter([b"ar", b"chive"]), {}
    value = transport.DockerBackend(client=object()).copy_from_container(
        transport.DockerContainerHandle(Download()), PurePosixPath("/source"))
    assert type(value) is bytes and value == b"archive"
