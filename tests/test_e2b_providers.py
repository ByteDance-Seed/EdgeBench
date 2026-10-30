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

"""Provider-profile behaviour of the e2b backend (official e2b vs veFaaS)."""

from __future__ import annotations

import base64
import logging
from types import SimpleNamespace

import pytest

pytest.importorskip("e2b")

from sforge.harness.backend.e2b_backend import (  # noqa: E402
    E2BBackend,
    E2BNetworkIsolation,
    _metadata_name,
    _SidecarSignalIsolation,
)

IMAGE_ENV = {
    "CARGO_HOME": "/usr/local/cargo",
    "RUSTUP_HOME": "/usr/local/rustup",
    "LANG": "C.UTF-8",
    "_BYTEFAAS_FUNC": "noise",
    "PATH": "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
}


class FakeCommands:
    def __init__(self):
        self.calls: list[dict] = []

    def run(self, cmd, background=None, envs=None, user=None, cwd=None,
            on_stdout=None, on_stderr=None, timeout=60, **_):
        self.calls.append({"cmd": cmd, "background": background, "envs": envs,
                           "user": user, "cwd": cwd})
        if "/proc/[0-9]*" in cmd:
            blob = b"\0".join(f"{k}={v}".encode() for k, v in IMAGE_ENV.items())
            return SimpleNamespace(
                stdout=f"__ENV_B64__{base64.b64encode(blob).decode()}__END__",
                stderr="", exit_code=0)
        if cmd.startswith("[ -d "):
            return SimpleNamespace(stdout="/usr/local/cargo/bin\n", stderr="", exit_code=0)
        if background:
            return SimpleNamespace(pid=7)
        if on_stdout:
            on_stdout("ok\n")
        return SimpleNamespace(stdout="ok\n", stderr="", exit_code=0)


class FakeFiles:
    def __init__(self):
        self.store: dict[str, str] = {}

    def write(self, path, data, user=None, **_):
        self.store[path] = data


class FakeSandbox:
    created: list[dict] = []
    queries: list[dict] = []

    def __init__(self, kwargs):
        self.kwargs = kwargs
        self.sandbox_id = f"sbx-{len(FakeSandbox.created)}"
        self.metadata = kwargs.get("metadata")
        self.commands = FakeCommands()
        self.files = FakeFiles()
        self.traffic_access_token = None

    @classmethod
    def create(cls, **kwargs):
        cls.created.append(kwargs)
        return cls(kwargs)

    @classmethod
    def list(cls, query=None):
        cls.queries.append(dict(query.metadata))
        return SimpleNamespace(has_next=False, next_items=lambda: [])

    def get_host(self, port):
        return f"{port}-{self.sandbox_id}.example"

    def set_timeout(self, *_, **__):
        pass


@pytest.fixture(autouse=True)
def _reset(monkeypatch):
    FakeSandbox.created = []
    FakeSandbox.queries = []
    for var in ("SFORGE_E2B_PROVIDER", "SFORGE_E2B_TEMPLATE_MAP"):
        monkeypatch.delenv(var, raising=False)


def make(provider):
    return E2BBackend(
        template_map={"edgebench.work.t:abc": "fn123"},
        provider=provider, sandbox_cls=FakeSandbox, template_cls=None,
    )


def test_unknown_provider_rejected():
    with pytest.raises(ValueError):
        make("nope")


def test_official_create_kwargs_are_secure():
    make("e2b").create_container("edgebench.work.t:abc", "sforge.run.t.r1")
    kw = FakeSandbox.created[0]
    assert kw["secure"] is True
    assert kw["lifecycle"] == {"on_timeout": "kill"}


def test_vefaas_create_kwargs_and_metadata_cap():
    name = "sforge.run." + "x" * 80 + ".deadbeef"
    make("vefaas").create_container("edgebench.work.t:abc", name)
    kw = FakeSandbox.created[0]
    assert "secure" not in kw and "lifecycle" not in kw and "network" not in kw
    meta = kw["metadata"]["sforge_name"]
    assert len(meta) < 64 and meta.endswith("deadbeef") and meta == _metadata_name(name)


def test_vefaas_harvests_image_env_and_reinjects_per_exec():
    b = make("vefaas")
    h = b.create_container("edgebench.work.t:abc", "sforge.run.t.r1",
                           environment={"SFORGE_TOKEN": "tok", "LANG": "en_US.UTF-8"})
    assert "_BYTEFAAS_FUNC" not in h.base_envs
    assert h.base_envs["CARGO_HOME"] == "/usr/local/cargo"
    assert h.base_envs["LANG"] == "en_US.UTF-8"  # create-time env wins
    assert h.base_envs["PATH"].startswith("/usr/local/cargo/bin:")
    assert "/etc/profile.d/zz-sforge-image-env.sh" in h.raw.files.store
    b.exec_run(h, "true", environment={"X": "1"})
    envs = h.raw.commands.calls[-1]["envs"]
    assert envs["SFORGE_TOKEN"] == "tok" and envs["X"] == "1"


def test_official_skips_harvest():
    h = make("e2b").create_container("edgebench.work.t:abc", "sforge.run.t.r1")
    assert not any("/proc/[0-9]*" in c["cmd"] for c in h.raw.commands.calls)


def test_vefaas_lists_by_function_id():
    make("vefaas").remove_container_by_name("sforge.run.t.r1", "edgebench.work.t:abc")
    assert {"vefaas_function_id": "fn123", "sforge_name": "sforge.run.t.r1"} in FakeSandbox.queries
    FakeSandbox.queries = []
    make("e2b").remove_container_by_name("sforge.run.t.r1", "edgebench.work.t:abc")
    assert FakeSandbox.queries == [{"sforge_name": "sforge.run.t.r1"}]


def test_isolation_follows_provider():
    log = logging.getLogger("t")
    hv = make("vefaas").create_container("edgebench.work.t:abc", "n1")
    assert isinstance(make("vefaas").create_network_isolation(hv, [], log), _SidecarSignalIsolation)
    he = make("e2b").create_container("edgebench.work.t:abc", "n2")
    assert isinstance(make("e2b").create_network_isolation(he, [], log), E2BNetworkIsolation)


def test_service_endpoint_without_traffic_token():
    b = make("vefaas")
    h = b.create_container("edgebench.work.t:abc", "n1")
    ep = b.get_service_endpoint(h, 8000)
    assert ep.url == f"https://8000-{h.raw.sandbox_id}.example" and ep.headers == {}
    b2 = make("e2b")
    h2 = b2.create_container("edgebench.work.t:abc", "n2")
    with pytest.raises(RuntimeError):
        b2.get_service_endpoint(h2, 8000)


def test_vefaas_image_exists_without_template_api():
    assert make("vefaas").image_exists("edgebench.work.t:abc") is True
