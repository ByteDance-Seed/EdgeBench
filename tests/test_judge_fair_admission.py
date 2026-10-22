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

"""FIFO admission must survive contention, cancellation and owner exits."""

from __future__ import annotations

import json
import multiprocessing as mp
import os
import threading
import time
from types import SimpleNamespace

import pytest

from sforge.harness import judge_server as js
from sforge.harness.config import SForgeConfig


def test_later_poll_cannot_barge_ahead_of_older_waiter(tmp_path):
    path = str(tmp_path / "slots.json")
    first = js.HostJudgeCapacity(1, path)
    assert first.try_acquire("holder")
    assert not first.try_acquire("older")
    first.release("holder")
    # Recreate the pool: the queue cannot be process-local or depend on poll order.
    second = js.HostJudgeCapacity(1, path)
    assert not second.try_acquire("later"), "later poll stole the free slot"
    assert second.try_acquire("older")
    second.release("older")
    assert second.try_acquire("later")
    second.release("later")


def test_memory_and_slot_admission_share_order_without_partial_reservation(tmp_path):
    slots = js.HostJudgeCapacity(2, str(tmp_path / "slots.json"))
    memory = js.HostJudgeCapacity(4, str(tmp_path / "memory.json"))

    def admit(token, units):
        return slots.try_acquire(
            token, "engine", memory_capacity=memory, memory_units=units
        )

    assert admit("holder", 4)
    assert not admit("older", 4)
    assert set(slots._read()["holders"]) == {"holder"}
    assert set(memory._read()["holders"]) == {"holder"}
    memory.release("holder")
    slots.release("holder")
    for _ in range(25):
        assert not admit("later", 1)
    assert admit("older", 4)
    assert not admit("later", 1)
    memory.release("older")
    slots.release("older")
    assert admit("later", 1)
    # Idempotent admission must not reset ownership or consume a second slot.
    before = (slots._read()["holders"], memory._read()["holders"])
    assert admit("later", 1)
    assert before == (slots._read()["holders"], memory._read()["holders"])
    memory.release("later")
    slots.release("later")


def test_waiter_cancellation_does_not_release_a_holder(tmp_path):
    slots = js.HostJudgeCapacity(1, str(tmp_path / "slots.json"))
    assert slots.try_acquire("holder")
    assert not slots.try_acquire("cancelled")
    assert not slots.try_acquire("next")
    slots.cancel_waiter("holder")
    assert "holder" in slots._read()["holders"]
    slots.cancel_waiter("cancelled")
    slots.release("holder")
    assert slots.try_acquire("next")


def _queue_waiter(path, ready):
    slots = js.HostJudgeCapacity(1, path)
    token = f"{os.getpid()}:waiting"
    assert not slots.try_acquire(token)
    ready.put(token)


def test_exited_waiter_is_removed_but_dead_holder_stays_reserved(tmp_path):
    path = str(tmp_path / "slots.json")
    slots = js.HostJudgeCapacity(1, path)
    assert slots.try_acquire("999999999:holder", "engine")
    ctx = mp.get_context("spawn")
    ready = ctx.Queue()
    child = ctx.Process(target=_queue_waiter, args=(path, ready))
    child.start()
    token = ready.get(timeout=10)
    child.join(10)
    assert child.exitcode == 0
    assert not slots.try_acquire("next")
    assert token not in [w["token"] for w in slots._read()["waiters"]]
    assert "999999999:holder" in slots._read()["holders"]
    assert slots.reconcile_stale_holders(lambda *_: False) == []
    assert not slots.try_acquire("next")
    assert slots.reconcile_stale_holders(lambda *_: True) == ["999999999:holder"]
    assert slots.try_acquire("next")


def test_reused_pid_cannot_keep_waiter_queue_position(tmp_path, monkeypatch):
    slots = js.HostJudgeCapacity(1, str(tmp_path / "slots.json"))
    assert slots.try_acquire("holder")
    monkeypatch.setattr(slots, "_process_start", lambda _: "old-process")
    assert not slots.try_acquire("reused")
    slots.release("holder")
    monkeypatch.setattr(slots, "_process_start", lambda _: "new-process")
    assert slots.try_acquire("next")


def test_waiter_request_change_requires_explicit_cancellation(tmp_path):
    slots = js.HostJudgeCapacity(4, str(tmp_path / "slots.json"))
    assert slots.try_acquire("holder", units=4)
    assert not slots.try_acquire("waiter", "engine", units=3)
    with pytest.raises(RuntimeError, match="waiter identity mismatch"):
        slots.try_acquire("waiter", "engine", units=2)
    slots.cancel_waiter("waiter")
    assert not slots.try_acquire("waiter", "engine", units=2)
    slots.release("holder")
    assert slots.try_acquire("waiter", "engine", units=2)
    with pytest.raises(RuntimeError, match="holder identity mismatch"):
        slots.try_acquire("waiter", "other-engine", units=2)


@pytest.mark.parametrize("malformed", [None, {}, [None], [{"token": "bad"}]])
def test_invalid_queue_fails_closed(tmp_path, malformed):
    slots = js.HostJudgeCapacity(1, str(tmp_path / "slots.json"))
    slots.path.write_text(
        json.dumps({"version": 1, "capacity": 1, "holders": {}, "waiters": malformed})
    )
    with pytest.raises(RuntimeError, match="waiter state"):
        slots.try_acquire("next")
    assert slots._read()["holders"] == {}


def test_impossible_request_cannot_block_later_work(tmp_path):
    slots = js.HostJudgeCapacity(1, str(tmp_path / "slots.json"))
    with pytest.raises(ValueError, match="exceeds"):
        slots.try_acquire("impossible", units=2)
    assert slots.try_acquire("valid")


def test_cancelled_native_worker_removes_waiter_and_keeps_pool_usable(
    tmp_path, monkeypatch
):
    monkeypatch.setenv("SFORGE_JUDGE_HOST_SLOT_FILE", str(tmp_path / "slots.json"))
    monkeypatch.setenv("SFORGE_JUDGE_HOST_OWNER_FILE", str(tmp_path / "owners.json"))
    monkeypatch.setenv("SFORGE_JUDGE_HOST_MEMORY_FILE", str(tmp_path / "memory.json"))
    state = js.JudgeState(
        SForgeConfig(
            log_dir=tmp_path,
            judge_host_capacity=1,
            judge_host_memory_capacity="4g",
            judge_max_concurrency=1,
        ),
        backend_factory=lambda _: SimpleNamespace(backend_name="synthetic"),
    )
    state.tasks = {"t": SimpleNamespace(judge=SimpleNamespace(mem_limit="1g"))}
    entered = threading.Event()
    monkeypatch.setattr(
        js,
        "judge_submission",
        lambda **_: (
            entered.set(),
            SimpleNamespace(to_dict=lambda: {"valid": True, "score": 1}),
        )[1],
    )
    assert state.host_capacity.try_acquire("holder")

    def wait(predicate):
        deadline = time.monotonic() + 5
        while not predicate() and time.monotonic() < deadline:
            time.sleep(0.01)
        assert predicate()

    try:
        sid = state.submit("t", b"archive", "run", "auto-1")
        wait(lambda: bool(state.host_capacity._read().get("waiters")))
        state._judge_queue_drained.set()
        wait(lambda: state._judge_queue.unfinished_tasks == 0)
        assert state.get_result(sid)["status"] == "error"
        assert not entered.is_set()
        assert state.host_capacity._read()["waiters"] == []
        assert state.host_memory_capacity._read()["holders"] == {}
        state.host_capacity.release("holder")
        state._judge_queue_drained.clear()
        sid = state.submit("t", b"archive", "run", "auto-2")
        wait(lambda: state._judge_queue.unfinished_tasks == 0)
        assert entered.is_set()
        assert state.get_result(sid)["status"] == "completed"
        assert state.host_capacity._read()["holders"] == {}
        assert state.host_memory_capacity._read()["holders"] == {}
    finally:
        state._judge_queue_drained.set()
        state._judge_queue.put(None)
        for worker in state._judge_workers:
            worker.join(5)
        state._reaper_stop.set()
        state._reaper_thread.join(5)


def _contend_for_slot(path, index, ready, release):
    slots = js.HostJudgeCapacity(1, path)
    token = f"{os.getpid()}:contender-{index}"
    assert not slots.try_acquire(token)
    ready.put(("queued", index))
    deadline = time.monotonic() + 15
    while not slots.try_acquire(token):
        assert time.monotonic() < deadline
        time.sleep(0.01)
    ready.put(("admitted", index))
    assert release.wait(10)
    slots.release(token)


def test_fifo_across_independent_processes(tmp_path):
    path = str(tmp_path / "slots.json")
    slots = js.HostJudgeCapacity(1, path)
    assert slots.try_acquire("holder")
    ctx = mp.get_context("spawn")
    ready = ctx.Queue()
    processes, releases = [], []
    try:
        for index in range(3):
            release = ctx.Event()
            child = ctx.Process(
                target=_contend_for_slot, args=(path, index, ready, release)
            )
            processes.append(child)
            releases.append(release)
            child.start()
            assert ready.get(timeout=10) == ("queued", index)
        slots.release("holder")
        for index, release in enumerate(releases):
            assert ready.get(timeout=10) == ("admitted", index)
            assert len(slots._read()["holders"]) == 1
            release.set()
        for child in processes:
            child.join(10)
            assert child.exitcode == 0
        assert slots._read()["holders"] == {}
        assert slots._read()["waiters"] == []
    finally:
        for release in releases:
            release.set()
        for child in processes:
            if child.is_alive():
                child.terminate()
            child.join(5)


def test_temporary_process_identity_read_failure_retains_waiter(tmp_path, monkeypatch):
    slots = js.HostJudgeCapacity(1, str(tmp_path / "slots.json"))
    assert slots.try_acquire("holder")
    monkeypatch.setattr(slots, "_process_start", lambda _: "original")
    assert not slots.try_acquire("waiter")
    monkeypatch.setattr(slots, "_process_start", lambda _: None)
    assert not slots.try_acquire("waiter")
    slots.release("holder")
    assert slots.try_acquire("waiter")


@pytest.mark.parametrize(
    "pool_name,method",
    [
        ("slots", "_write"),
        ("slots", "_write_owners"),
        ("memory", "_write"),
        ("memory", "_write_owners"),
    ],
)
def test_partial_admission_write_failure_rolls_back(
    tmp_path, monkeypatch, pool_name, method
):
    slots = js.HostJudgeCapacity(1, str(tmp_path / "slots.json"))
    memory = js.HostJudgeCapacity(4, str(tmp_path / "memory.json"))
    pool = slots if pool_name == "slots" else memory
    original = getattr(pool, method)
    failed = False

    def fail_once(state):
        nonlocal failed
        original(state)  # A write can succeed before its acknowledgement fails.
        if not failed:
            failed = True
            raise OSError("synthetic write failure")

    monkeypatch.setattr(pool, method, fail_once)
    with pytest.raises(OSError, match="synthetic write failure"):
        slots.try_acquire("failed", "engine", memory_capacity=memory, memory_units=4)
    assert slots._read()["holders"] == {}
    assert memory._read()["holders"] == {}
    slots.cancel_waiter("failed")
    assert slots.try_acquire("next", "engine", memory_capacity=memory, memory_units=4)
