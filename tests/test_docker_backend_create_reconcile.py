"""Zero-model regression for the ambiguous-create reconcile in docker_backend.

No Docker daemon, no model, no network: the docker client is faked.

Run:
    python -m pytest -q tests/test_docker_backend_create_reconcile.py
"""

from __future__ import annotations

import json
import os
import pathlib
import tempfile
import time
import unittest

import docker
import docker.errors
import requests

from sforge.harness.backend import docker_backend as db

LABEL = db.CREATE_OPERATION_LABEL
IMAGE = "example.invalid/sforge-work:latest"
NAME = "sforge.run.synthetic.case"


class FakeContainer:
    def __init__(self, name, image_ref, state="created", labels=None, cid="c0ffee"):
        self.id = cid
        self.name = name
        self.attrs = {
            "Config": {"Image": image_ref, "Labels": labels},
            "State": {"Status": state},
        }


class FakeContainers:
    """Fake docker container collection.

    ``land_created=True`` simulates the daemon having created the container
    before the reply was lost, so ``get`` can surface it afterwards.
    """

    def __init__(
        self,
        create_exc=None,
        existing=None,
        get_exc=None,
        land_created=False,
        appear_after_queries=None,
        get_sleep=0.0,
    ):
        self.create_exc = create_exc
        self.existing = existing
        self.get_exc = get_exc
        self.land_created = land_created
        self.appear_after_queries = appear_after_queries
        self.get_sleep = get_sleep
        self.create_calls = []
        self.get_calls = []
        self.landed = None

    def create(
        self,
        image,
        name=None,
        detach=None,
        command=None,
        environment=None,
        labels=None,
        **kw,
    ):
        self.create_calls.append({"image": image, "name": name, "labels": labels})
        if self.create_exc is not None:
            if self.land_created:
                self.landed = FakeContainer(name, image, state="created", labels=labels)
            raise self.create_exc
        return FakeContainer(name, image, state="created", labels=labels)

    def get(self, name):
        self.get_calls.append(name)
        if self.get_sleep:
            time.sleep(self.get_sleep)
        if self.get_exc is not None:
            raise self.get_exc
        if self.existing is not None:
            return self.existing
        if self.landed is not None:
            if self.appear_after_queries is not None:
                if len(self.get_calls) <= self.appear_after_queries:
                    raise docker.errors.NotFound(f"no such container: {name}")
            return self.landed
        raise docker.errors.NotFound(f"no such container: {name}")


class FakeClient:
    def __init__(self, containers):
        self.containers = containers


def backend(containers):
    return db.DockerBackend(client=FakeClient(containers))


def _timeout():
    return requests.exceptions.ReadTimeout(
        "UnixHTTPConnectionPool: Read timed out. (read timeout=60)"
    )


class CreateReconcileTests(unittest.TestCase):
    def setUp(self):
        # keep the bounded re-query fast; the logic under test is identity, not timing
        self._budget = db._RECONCILE_QUERY_BUDGET_SEC
        self._interval = db._RECONCILE_QUERY_INTERVAL_SEC
        db._RECONCILE_QUERY_BUDGET_SEC = 0.05
        db._RECONCILE_QUERY_INTERVAL_SEC = 0.01
        self._pending_tmp = tempfile.TemporaryDirectory(prefix="pending-creates-")
        self._pending_dir = self._pending_tmp.name
        self._pending_env = os.environ.get(db.PENDING_CREATE_DIR_ENV)
        os.environ[db.PENDING_CREATE_DIR_ENV] = self._pending_dir

    def tearDown(self):
        db._RECONCILE_QUERY_BUDGET_SEC = self._budget
        db._RECONCILE_QUERY_INTERVAL_SEC = self._interval
        if self._pending_env is None:
            os.environ.pop(db.PENDING_CREATE_DIR_ENV, None)
        else:
            os.environ[db.PENDING_CREATE_DIR_ENV] = self._pending_env
        self._pending_tmp.cleanup()

    def pending_records(self):
        paths = sorted(pathlib.Path(self._pending_dir).glob("*.json"))
        return [json.loads(path.read_text()) for path in paths]

    # --- baseline ---------------------------------------------------------
    def test_normal_create_is_unchanged(self):
        c = FakeContainers()
        handle = backend(c).create_container(IMAGE, NAME)
        self.assertEqual(len(c.create_calls), 1)
        self.assertEqual(c.get_calls, [], "reconcile must not run on success")
        self.assertEqual(handle._container.name, NAME)
        self.assertIn(LABEL, c.create_calls[0]["labels"])

    def test_nonce_is_unique_per_create_attempt(self):
        c = FakeContainers()
        b = backend(c)
        b.create_container(IMAGE, NAME)
        b.create_container(IMAGE, NAME)
        n1 = c.create_calls[0]["labels"][LABEL]
        n2 = c.create_calls[1]["labels"][LABEL]
        self.assertNotEqual(n1, n2)

    # --- (a) server-side success, reply lost -> adopt, never create twice --
    def test_read_timeout_with_landed_create_is_adopted(self):
        c = FakeContainers(create_exc=_timeout(), land_created=True)
        handle = backend(c).create_container(IMAGE, NAME)
        self.assertIs(handle._container, c.landed)
        self.assertEqual(len(c.create_calls), 1, "must not create a second container")

    def test_connection_error_with_landed_create_is_adopted(self):
        c = FakeContainers(
            create_exc=requests.exceptions.ConnectionError("connection aborted"),
            land_created=True,
        )
        handle = backend(c).create_container(IMAGE, NAME)
        self.assertIs(handle._container, c.landed)
        self.assertEqual(len(c.create_calls), 1)

    def test_late_visible_container_is_adopted_within_budget(self):
        c = FakeContainers(
            create_exc=_timeout(), land_created=True, appear_after_queries=1
        )
        handle = backend(c).create_container(IMAGE, NAME)
        self.assertIs(handle._container, c.landed)
        self.assertEqual(len(c.create_calls), 1)

    # --- (b) nothing visible -> outcome unknown, original error, no retry --
    def test_read_timeout_without_container_reraises(self):
        c = FakeContainers(create_exc=_timeout())
        with self.assertRaises(requests.exceptions.ReadTimeout):
            backend(c).create_container(IMAGE, NAME)
        self.assertEqual(len(c.create_calls), 1, "must not blindly re-create")
        self.assertTrue(c.get_calls, "must have attempted reconciliation")

    def test_reconcile_query_failure_keeps_outcome_unknown(self):
        c = FakeContainers(create_exc=_timeout(), get_exc=_timeout())
        with self.assertRaises(requests.exceptions.ReadTimeout):
            backend(c).create_container(IMAGE, NAME)
        self.assertEqual(len(c.create_calls), 1)

    # --- (c) identity conflict -> refuse to adopt -------------------------
    def test_stale_previous_attempt_nonce_is_refused(self):
        """A same-name container from an earlier attempt must never be adopted."""
        stale = FakeContainer(
            NAME, IMAGE, state="created", labels={LABEL: "previous-attempt"}
        )
        c = FakeContainers(create_exc=_timeout(), existing=stale)
        with self.assertRaises(db.ContainerCreateReconcileError):
            backend(c).create_container(IMAGE, NAME)
        self.assertEqual(len(c.create_calls), 1)

    def test_missing_nonce_label_is_refused(self):
        unlabelled = FakeContainer(NAME, IMAGE, state="created", labels=None)
        c = FakeContainers(create_exc=_timeout(), existing=unlabelled)
        with self.assertRaises(db.ContainerCreateReconcileError):
            backend(c).create_container(IMAGE, NAME)

    def test_empty_labels_is_refused(self):
        unlabelled = FakeContainer(NAME, IMAGE, state="created", labels={})
        c = FakeContainers(create_exc=_timeout(), existing=unlabelled)
        with self.assertRaises(db.ContainerCreateReconcileError):
            backend(c).create_container(IMAGE, NAME)

    def test_matching_nonce_with_different_image_is_refused(self):
        c = FakeContainers(create_exc=_timeout(), land_created=True)
        original_create = c.create

        def create_with_wrong_image(*args, **kwargs):
            try:
                return original_create(*args, **kwargs)
            finally:
                c.landed.attrs["Config"]["Image"] = "example.invalid/other:latest"

        c.create = create_with_wrong_image
        with self.assertRaises(db.ContainerCreateReconcileError):
            backend(c).create_container(IMAGE, NAME)

    def test_matching_nonce_with_running_container_is_refused(self):
        c = FakeContainers(create_exc=_timeout(), land_created=True)
        original_create = c.create

        def create_running(*args, **kwargs):
            try:
                return original_create(*args, **kwargs)
            finally:
                c.landed.attrs["State"]["Status"] = "running"

        c.create = create_running
        with self.assertRaises(db.ContainerCreateReconcileError):
            backend(c).create_container(IMAGE, NAME)

    # --- definite daemon answers are never reconciled ---------------------
    def test_definite_api_error_propagates_without_reconcile(self):
        c = FakeContainers(create_exc=docker.errors.APIError("400 Client Error"))
        with self.assertRaises(docker.errors.APIError):
            backend(c).create_container(IMAGE, NAME)
        self.assertEqual(c.get_calls, [], "definite errors must not trigger reconcile")
        self.assertEqual(len(c.create_calls), 1)

    def test_conflict_api_error_propagates_without_reconcile(self):
        c = FakeContainers(
            create_exc=docker.errors.APIError(
                "409 Client Error: Conflict ('Conflict. The container name \"/x\" is already in use')"
            )
        )
        with self.assertRaises(docker.errors.APIError):
            backend(c).create_container(IMAGE, NAME)
        self.assertEqual(c.get_calls, [])

    # --- bounded queries: one slow get must not blow the budget -----------
    def test_slow_get_is_capped_by_remaining_budget(self):
        """A single containers.get that would block past the budget is abandoned."""
        db._RECONCILE_QUERY_BUDGET_SEC = 0.30
        c = FakeContainers(create_exc=_timeout(), get_sleep=5.0)
        started = time.monotonic()
        with self.assertRaises(requests.exceptions.ReadTimeout):
            backend(c).create_container(IMAGE, NAME)
        elapsed = time.monotonic() - started
        self.assertLess(elapsed, 1.5, f"reconcile overran its budget: {elapsed:.2f}s")
        self.assertEqual(len(c.create_calls), 1)
        records = self.pending_records()
        self.assertEqual(len(records), 1)
        self.assertEqual(records[0]["outcome"], "unknown")

    def test_total_deadline_bounds_many_fast_queries(self):
        db._RECONCILE_QUERY_BUDGET_SEC = 0.30
        db._RECONCILE_QUERY_INTERVAL_SEC = 0.01
        c = FakeContainers(create_exc=_timeout())
        started = time.monotonic()
        with self.assertRaises(requests.exceptions.ReadTimeout):
            backend(c).create_container(IMAGE, NAME)
        elapsed = time.monotonic() - started
        self.assertLess(elapsed, 1.5, f"reconcile overran its budget: {elapsed:.2f}s")

    # --- pending record: late landing / wrong nonce -----------------------
    def test_late_landing_records_pending(self):
        c = FakeContainers(create_exc=_timeout())  # never becomes visible in budget
        with self.assertRaises(requests.exceptions.ReadTimeout):
            backend(c).create_container(IMAGE, NAME)
        records = self.pending_records()
        self.assertEqual(len(records), 1)
        rec = records[0]
        self.assertEqual(rec["container_name"], NAME)
        self.assertEqual(rec["image"], IMAGE)
        self.assertTrue(rec["nonce"])
        self.assertEqual(rec["outcome"], "unknown")

    def test_wrong_nonce_records_pending_identity_conflict(self):
        stale = FakeContainer(
            NAME, IMAGE, state="created", labels={LABEL: "previous-attempt"}
        )
        c = FakeContainers(create_exc=_timeout(), existing=stale)
        with self.assertRaises(db.ContainerCreateReconcileError):
            backend(c).create_container(IMAGE, NAME)
        records = self.pending_records()
        self.assertEqual(len(records), 1)
        self.assertEqual(records[0]["outcome"], "identity_conflict")
        self.assertIn("previous-attempt", records[0]["detail"])

    def test_adopted_create_records_nothing(self):
        c = FakeContainers(create_exc=_timeout(), land_created=True)
        backend(c).create_container(IMAGE, NAME)
        self.assertEqual(self.pending_records(), [])

    def test_pending_records_are_nonce_unique_and_never_overwritten(self):
        """Two attempts on the same name must leave two records, not one."""
        c = FakeContainers(create_exc=_timeout())
        b = backend(c)
        for _ in range(2):
            with self.assertRaises(requests.exceptions.ReadTimeout):
                b.create_container(IMAGE, NAME)
        records = self.pending_records()
        self.assertEqual(
            len(records), 2, "a later attempt must not overwrite an earlier one"
        )
        self.assertEqual(len({r["nonce"] for r in records}), 2)
        files = sorted(pathlib.Path(self._pending_dir).glob("*.json"))
        self.assertEqual(len(files), 2)
        for path in files:
            rec = json.loads(path.read_text())
            self.assertIn(rec["nonce"], path.name)


if __name__ == "__main__":
    unittest.main(verbosity=2)
