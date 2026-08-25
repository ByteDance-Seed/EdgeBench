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

"""Evaluation orchestration: extract archive in judge container, run tests, grade."""

from __future__ import annotations

import fnmatch
import json
import logging
import time
import traceback
import uuid
from pathlib import Path, PurePosixPath

from sforge.harness.backend import ContainerBackend
from sforge.harness.config import (
    SForgeConfig,
    get_container_env,
    sanitize_e2b_proxy_env,
)
from sforge.harness.constants import DOCKER_USER
from sforge.harness.docker_build import (
    BuildImageError,
    build_judge_image,
    close_logger,
    setup_logger,
)
from sforge.harness.grading import EvalReport, grade_output
from sforge.harness.score_rescale import rescale_score
from sforge.harness.task_spec import TaskSpec


class EvaluationError(Exception):
    def __init__(self, task_id: str, message: str, logger: logging.Logger):
        super().__init__(message)
        self.task_id = task_id
        self.log_file = getattr(logger, "log_file", None)


def _filter_archive_files(
    file_list: list[str],
    submit_paths: list[str],
    submit_exclude: list[str],
) -> list[str]:
    """Filter archive entries against submit_paths (whitelist) and submit_exclude (blacklist).

    A file is allowed if:
      1. It falls under at least one submit_paths entry (prefix match, or "." allows all)
      2. It does NOT match any submit_exclude pattern (prefix or fnmatch glob)
      3. It is not a directory entry (trailing /)
    """
    allowed: list[str] = []
    for f in file_list:
        f = f.strip()
        if not f or f.endswith("/"):
            continue

        # Whitelist: must be under at least one submit_paths entry
        in_whitelist = False
        for sp in submit_paths:
            sp = sp.rstrip("/")
            if sp == ".":
                in_whitelist = True
                break
            if f == sp or f.startswith(sp + "/"):
                in_whitelist = True
                break
        if not in_whitelist:
            continue

        # Blacklist: reject if any exclude pattern matches
        excluded = False
        for exc in submit_exclude:
            exc = exc.rstrip("/")
            if f == exc or f.startswith(exc + "/"):
                excluded = True
                break
            basename = f.rsplit("/", 1)[-1]
            if fnmatch.fnmatch(basename, exc):
                excluded = True
                break
            if fnmatch.fnmatch(f, exc):
                excluded = True
                break
        if excluded:
            continue

        allowed.append(f)
    return allowed


def judge_submission(
    task_spec: TaskSpec,
    archive: bytes,
    config: SForgeConfig,
    backend: ContainerBackend,
    submission_id: str | None = None,
    timeout: int | None = None,
    log_dir: Path | None = None,
    verbose: bool = False,
) -> EvalReport:
    """
    Grade an archive submission in an ephemeral judge container.

    1. Ensure judge image exists
    2. Create ephemeral container from judge image
    3. Extract archive (tar.gz) into patch_dir
    4. Inject eval.sh into container
    5. Run eval script
    6. Parse output, compute score
    7. Cleanup container

    Args:
        archive: Raw bytes of a tar.gz containing submitted files.
        log_dir: Override log output directory. If None, defaults to
                 logs/runs/<submission_id>/<task_id>/submissions/001/
    """
    if submission_id is None:
        submission_id = uuid.uuid4().hex[:12]

    submitted_at = time.time()
    timeout = timeout or task_spec.judge.eval_timeout

    # Set up logging
    if log_dir is None:
        log_dir = (
            config.log_dir / "runs" / submission_id
            / task_spec.task_id / "submissions" / "1"
        )
    log_dir.mkdir(parents=True, exist_ok=True)
    logger = setup_logger(
        f"judge.{task_spec.task_id}.{submission_id}",
        log_dir / "run_instance.log",
        verbose=verbose,
    )

    handle = None
    try:
        # 1. Ensure judge image exists (Docker builds locally; K8s requires pre-built images in CR)
        if backend.backend_name == "docker":
            from sforge.harness.backend.docker_backend import DockerBackend
            assert isinstance(backend, DockerBackend)
            build_judge_image(task_spec, config, backend.client, force_rebuild=False)

        # 2. Create + start ephemeral container
        container_name = f"{task_spec.benchmark_name}.judge.{task_spec.task_id}.{submission_id}"
        env = get_container_env(config, include_judge_extra=True)
        if backend.backend_name == "e2b":
            sanitize_e2b_proxy_env(env)
        env.setdefault("SFORGE_JUDGE_URL", "http://host.docker.internal:8080")
        # Resolve resource limits: config > task defaults
        cpu = config.judge_cpu_limit if config.judge_cpu_limit is not None else task_spec.judge.cpu_limit
        mem = config.judge_mem_limit if config.judge_mem_limit is not None else task_spec.judge.mem_limit
        handle = backend.create_container(
            task_spec.judge_image_key,
            container_name,
            environment=env,
            extra_hosts={"host.docker.internal": "host-gateway"},
            cpu_limit=cpu,
            mem_limit=mem,
            user=DOCKER_USER,
        )
        backend.start_container(handle)
        logger.info(f"Judge container started: {handle.id}")

        # 3. Extract archive into patch_dir (filtered by submit_paths/submit_exclude)
        if archive:
            local_tar = log_dir / "submission.tar.gz"
            local_tar.write_bytes(archive)
            logger.info(f"Archive saved ({len(archive)} bytes)")

            tar_path = PurePosixPath("/tmp/submission.tar.gz")
            backend.copy_to_container(handle, local_tar, tar_path)

            # List archive contents
            list_result = backend.exec_run(
                handle,
                f"tar tzf {tar_path}",
                workdir=task_spec.cwd,
                user=DOCKER_USER,
            )
            if list_result.exit_code != 0:
                err_msg = list_result.output
                logger.error(f"Archive listing failed: {err_msg}")
                raise EvaluationError(
                    task_spec.task_id,
                    f"Archive listing failed: {err_msg}",
                    logger,
                )

            all_files = list_result.output.splitlines()
            allowed_files = _filter_archive_files(
                all_files, task_spec.submit_paths, task_spec.submit_exclude,
            )

            rejected = set(f.strip() for f in all_files if f.strip() and not f.strip().endswith("/")) - set(allowed_files)
            if rejected:
                logger.warning(f"Archive path filter rejected {len(rejected)} file(s): {sorted(rejected)[:20]}")

            if allowed_files:
                # Write filtered file list and extract only those
                file_list_content = "\n".join(allowed_files) + "\n"
                local_file_list = log_dir / "allowed_files.txt"
                local_file_list.write_text(file_list_content)
                backend.copy_to_container(handle, local_file_list, PurePosixPath("/tmp/allowed_files.txt"))

                val = backend.exec_run(
                    handle,
                    f"tar xzf {tar_path} -T /tmp/allowed_files.txt",
                    workdir=task_spec.cwd,
                    user=DOCKER_USER,
                )
                if val.exit_code != 0:
                    err_msg = val.output
                    logger.error(f"Archive extraction failed: {err_msg}")
                    raise EvaluationError(
                        task_spec.task_id,
                        f"Archive extraction failed: {err_msg}",
                        logger,
                    )
                logger.info(f"Archive extracted: {len(allowed_files)} file(s) allowed, {len(rejected)} rejected")
            else:
                logger.warning("All archive entries were filtered out — running eval on unmodified skeleton")
        else:
            logger.info("Empty archive — running eval on unmodified skeleton")

        # 4. Inject eval.sh dynamically (not baked into the image)
        eval_script_local = log_dir / "eval.sh"
        eval_script_local.write_text(task_spec.eval_script)
        backend.copy_to_container(handle, eval_script_local, PurePosixPath("/tmp/eval.sh"))

        # 5. Run eval script. workdir matters for eval_cmds that use relative
        # paths: docker defaults to the image WORKDIR but envd execs land in
        # the user's home, so pin the task cwd explicitly.
        logger.info("Running eval script...")
        result = backend.exec_run_with_timeout(
            handle, "/bin/bash /tmp/eval.sh", timeout, workdir=task_spec.cwd
        )
        test_output, timed_out, runtime = result.output, result.timed_out, result.elapsed_seconds

        # Save test output
        (log_dir / "test_output.txt").write_text(test_output)
        logger.info(f"Test runtime: {runtime:.2f}s, timed_out: {timed_out}")

        # 6. Grade
        report = grade_output(
            task_spec, test_output, submission_id, timed_out, runtime
        )
        report.submitted_at = submitted_at
        report.score_0_100 = rescale_score(task_spec.judge.rescale, report.score)
        (log_dir / "report.json").write_text(
            json.dumps(report.to_dict(), indent=2, ensure_ascii=False)
        )
        logger.info(
            f"Result: {report.passed}/{report.total_tests} passed "
            f"(pass_rate={report.pass_rate:.2%})"
        )
        return report

    except (EvaluationError, BuildImageError) as e:
        logger.error(traceback.format_exc())
        return EvalReport(
            task_id=task_spec.task_id,
            submission_id=submission_id,
            submitted_at=submitted_at,
            raw_output=str(e),
        )
    except Exception as e:
        logger.error(f"Unexpected error: {e}\n{traceback.format_exc()}")
        return EvalReport(
            task_id=task_spec.task_id,
            submission_id=submission_id,
            submitted_at=submitted_at,
            raw_output=str(e),
        )
    finally:
        try:
            backend.cleanup_container(handle, logger)
        finally:
            close_logger(logger)
