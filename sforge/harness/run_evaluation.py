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

"""Evaluation: extract the submission in a fresh judge container, run the grader, read result.json."""

from __future__ import annotations

import fnmatch
import json
import logging
import time
import traceback
import uuid
from pathlib import Path

from sforge.harness.backend import ContainerBackend
from sforge.harness.config import (
    SForgeConfig,
    resource_env,
)
from sforge.harness.docker_build import (
    BuildImageError,
    build_judge_image,
    close_logger,
    setup_logger,
)
from sforge.harness.grading import EvalReport, parse_result
from sforge.harness.score_rescale import rescale_score
from sforge.harness.constants import CONTAINER_DIR
from sforge.harness.task_spec import RESULT_PATH, TaskSpec


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
    3. Extract archive (tar.gz) into the task cwd
    4. Run the grader (task.toml judge.cmd)
    5. Read result.json, rescale the score
    6. Cleanup container

    Args:
        archive: Raw bytes of a tar.gz containing submitted files.
        log_dir: Override log output directory. If None, defaults to
                 logs/runs/<submission_id>/<task_id>/submissions/001/
    """
    if submission_id is None:
        submission_id = uuid.uuid4().hex[:12]

    submitted_at = time.time()
    timeout = timeout or task_spec.judge.timeout

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
    isolation = None
    try:
        # 1. Ensure judge image exists (Docker builds locally; K8s requires pre-built images in CR)
        if backend.backend_name == "docker":
            build_judge_image(task_spec, config)

        # 2. Create + start ephemeral container
        container_name = f"sforge.judge.{task_spec.task_id}.{submission_id}"
        # Graders run untrusted code: no model key, no proxies, nothing but
        # what the operator explicitly passes via SFORGE_JUDGE_EXTRA_ENV.
        env = dict(config.judge_extra_env)
        # Resolve resource limits: config > task defaults
        cpu = config.judge_cpu_limit if config.judge_cpu_limit is not None else task_spec.judge.cpu_limit
        mem = config.judge_mem_limit if config.judge_mem_limit is not None else task_spec.judge.mem_limit
        env.update(resource_env(cpu, mem))
        offline = not task_spec.judge.internet
        handle = backend.create_container(
            task_spec.judge_image_key,
            container_name,
            environment=env,
            cpu_limit=cpu,
            mem_limit=mem,
            network=not offline,
        )
        backend.start_container(handle)
        if offline and backend.backend_name != "docker":
            isolation = backend.create_network_isolation(handle, [], logger)
            isolation.apply()
        logger.info(f"Judge container started: {handle.id} (network: {'off' if offline else 'on'})")

        # 3. Extract archive into patch_dir (filtered by submit_paths/submit_exclude)
        if archive:
            local_tar = log_dir / "submission.tar.gz"
            local_tar.write_bytes(archive)
            logger.info(f"Archive saved ({len(archive)} bytes)")

            tar_path = CONTAINER_DIR / "submission.tar.gz"
            backend.copy_to_container(handle, local_tar, tar_path)

            # List archive contents
            list_result = backend.exec_run(
                handle,
                # --quoting-style=literal: GNU tar octal-escapes non-ASCII
                # names in listings under some locales, which breaks the
                # submit_paths match for CJK filenames
                f"tar --quoting-style=literal -tzf {tar_path}",
                workdir=task_spec.cwd,
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
                list_path = CONTAINER_DIR / "allowed_files.txt"
                backend.copy_to_container(handle, local_file_list, list_path)

                val = backend.exec_run(
                    handle,
                    f"tar xzf {tar_path} -T {list_path}",
                    workdir=task_spec.cwd,
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

        # 4. Run the grader. workdir matters for relative paths: docker
        # defaults to the image WORKDIR but envd execs land in $HOME.
        logger.info("Running grader...")
        result = backend.exec_run_with_timeout(
            handle,
            ["/bin/bash", "-c", f"mkdir -p {CONTAINER_DIR} && {task_spec.judge.cmd}"],
            timeout,
            workdir=task_spec.cwd,
        )
        (log_dir / "judge_output.txt").write_text(result.output)
        logger.info(f"Grader runtime: {result.elapsed_seconds:.2f}s, timed_out: {result.timed_out}")

        # 5. Read the grader's result
        raw = backend.exec_run(handle, ["cat", RESULT_PATH])
        score, valid, data = parse_result(raw.output) if raw.exit_code == 0 else (None, False, {})
        if raw.exit_code == 0:
            (log_dir / "result.json").write_text(raw.output)
        report = EvalReport(
            task_id=task_spec.task_id,
            submission_id=submission_id,
            score=score,
            score_0_100=rescale_score(task_spec.judge.rescale, score) if valid else None,
            valid=valid and not result.timed_out,
            summary=data.get("summary"),
            details=data.get("details") or [],
            metrics=data.get("metrics") or {},
            timed_out=result.timed_out,
            runtime_seconds=result.elapsed_seconds,
            submitted_at=submitted_at,
            error=None if raw.exit_code == 0 else f"grader wrote no {RESULT_PATH}",
        )
        (log_dir / "report.json").write_text(
            json.dumps(report.to_dict(), indent=2, ensure_ascii=False)
        )
        logger.info(f"Result: score={report.score} valid={report.valid}")
        return report

    except (EvaluationError, BuildImageError) as e:
        logger.error(traceback.format_exc())
        return EvalReport(
            task_id=task_spec.task_id,
            submission_id=submission_id,
            submitted_at=submitted_at,
            error=str(e),
        )
    except Exception as e:
        logger.error(f"Unexpected error: {e}\n{traceback.format_exc()}")
        return EvalReport(
            task_id=task_spec.task_id,
            submission_id=submission_id,
            submitted_at=submitted_at,
            error=str(e),
        )
    finally:
        try:
            if isolation is not None:
                isolation.cleanup()
            backend.cleanup_container(handle, logger)
        finally:
            close_logger(logger)
