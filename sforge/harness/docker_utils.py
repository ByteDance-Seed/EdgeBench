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

"""Docker container utilities, adapted from SWE-bench."""

from __future__ import annotations

import io
import logging
import os
import signal
import sys
import tarfile
import threading
import time
import traceback
import uuid
from collections.abc import Callable
from pathlib import Path

from docker.models.containers import Container
from docker.utils import split_command

HEREDOC_DELIMITER = "EOF_SFORGE_1399519320"


def copy_to_container(container: Container, src: Path, dst: Path) -> None:
    """Copy a local file into a Docker container."""
    if os.path.dirname(dst) == "":
        raise ValueError(f"Destination path parent directory cannot be empty: {dst}")

    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w") as tar:
        tar.add(src, arcname=dst.name)
    buf.seek(0)

    container.exec_run(f"mkdir -p {dst.parent}")
    container.put_archive(os.path.dirname(dst), buf.read())


def write_to_container(container: Container, data: str, dst: Path) -> None:
    """Write a string to a file inside a Docker container."""
    command = f"cat <<'{HEREDOC_DELIMITER}' > {dst}\n{data}\n{HEREDOC_DELIMITER}"
    container.exec_run(command)


def exec_run_with_timeout(
    container: Container,
    cmd: str | list[str],
    timeout: int | None = 60,
    log_file: Path | None = None,
    user: str | None = None,
    workdir: str | None = None,
    environment: dict[str, str] | None = None,
    stream_to_stdout: bool = False,
    shutdown_event: threading.Event | None = None,
    log_append: bool = False,
    on_chunk: Callable[[bytes], None] | None = None,
) -> tuple[str, bool, float]:
    """
    Run a command in a container with a timeout.

    Returns:
        (output, timed_out, elapsed_seconds)
    """
    output, _exit_code, timed_out, elapsed = _exec_run(
        container,
        cmd,
        timeout,
        log_file,
        user,
        workdir,
        environment,
        stream_to_stdout=stream_to_stdout,
        shutdown_event=shutdown_event,
        log_append=log_append,
        on_chunk=on_chunk,
    )
    return output, timed_out, elapsed


def exec_run_with_exit_code(
    container: Container,
    cmd: str | list[str],
    timeout: int | None = 60,
    user: str | None = None,
    workdir: str | None = None,
    environment: dict[str, str] | None = None,
) -> tuple[str, int, bool, float]:
    """
    Run a command in a container with a timeout, returning the exit code.

    Returns:
        (output, exit_code, timed_out, elapsed_seconds)
        exit_code is -1 if timed out before completion.
    """
    return _exec_run(container, cmd, timeout, None, user, workdir, environment)


# The image contract already requires bash (workspace setup and solver entry).
# Keep a live group leader until its group is empty; a stale numeric PID must
# never be used to signal an unrelated later exec. Control crosses namespaces
# through this invocation's private directory, never through Docker's host PID.
_EXEC_SHUTDOWN_GRACE = 20
_EXEC_DRAIN_GRACE = 5
_EXEC_SUPERVISOR = r"""
control=$1; grace=$2; drain=$3; shift 3
[[ -d "$control" && -p "$control/hold" ]] || exit 125
if [[ -f "$control/stop" ]]; then
    printf "125\n" > "$control/settled"
    exit 125
fi
stop=0
trap 'stop=1' TERM INT HUP
set -m
/bin/bash -c '
    control=$1; shift
    trap "" TERM INT HUP
    exec 3<>"$control/hold" || exit 125
    (trap - TERM INT HUP; exec "$@") 3>&- &
    child=$!
    wait "$child" 2>/dev/null
    code=$?
    # Existence is the supervisor completion signal. Publish only after the
    # complete code is written; opening result directly races the group kill.
    if ! { printf "%s\n" "$code" > "$control/result.tmp" &&
           mv -- "$control/result.tmp" "$control/result"; }; then
        : > "$control/stop"
    fi
    # Stay alive as the process-group anchor until the final group kill.
    read -r -u 3
' sforge-exec-group "$control" "$@" &
group=$!
# Preserve the command stderr, but suppress supervisor job-control notices.
exec 2>/dev/null
set +m
while [[ ! -f "$control/result" && ! -f "$control/stop" && $stop == 0 ]]; do
    kill -0 "$group" 2>/dev/null || break
    sleep .05
done
# The group leader ignores TERM; the command resets its signal dispositions.
kill -s TERM -- "-$group" 2>/dev/null || :
group_has_live() {
    for file in /proc/[0-9]*/stat; do
        IFS= read -r stat 2>/dev/null < "$file" || continue
        pid=${stat%% *}; rest=${stat##*) }
        read -r state parent pgid remaining <<< "$rest"
        if [[ "$pgid" == "$group" && "$pid" != "$1" && "$state" != Z && "$state" != X ]]; then
            return 0
        fi
    done
    return 1
}
end=$((SECONDS + grace))
while group_has_live "$group"; do
    [[ $SECONDS -ge $end ]] && break
    sleep .05
done
# One final group kill while the leader is still owned, then reap it. No later
# numeric signal is sent after the anchor can be reused.
kill -s KILL -- "-$group" 2>/dev/null || :
end=$((SECONDS + drain))
while group_has_live 0; do
    [[ $SECONDS -lt $end ]] || exit 125
    sleep .05
done
wait "$group" 2>/dev/null || :
code=125
[[ ! -f "$control/result" ]] || read -r code < "$control/result"
printf "%s\n" "$code" > "$control/settled"
exit "$code"
"""


def _exec_run(
    container: Container,
    cmd: str | list[str],
    timeout: int | None = 60,
    log_file: Path | None = None,
    user: str | None = None,
    workdir: str | None = None,
    environment: dict[str, str] | None = None,
    stream_to_stdout: bool = False,
    shutdown_event: threading.Event | None = None,
    log_append: bool = False,
    on_chunk: Callable[[bytes], None] | None = None,
    on_terminal: Callable[[int], None] | None = None,
) -> tuple[str, int, bool, float]:
    """Run one owned exec; a result requires terminal process and drained stream.

    On timeout/cancellation, ask the in-container supervisor to terminate its
    group, allow shutdown output, then escalate. An unconfirmed stop or stream
    failure raises instead of exposing a partial output as a completed result.
    """
    start = time.monotonic()
    if shutdown_event is not None and shutdown_event.is_set():
        return "", -1, True, time.monotonic() - start
    argv = split_command(cmd) if isinstance(cmd, str) else list(cmd)
    if not argv:
        raise ValueError("Docker exec command must not be empty")
    control = f"/tmp/sforge-exec-{uuid.uuid4().hex}"
    options = {
        k: v
        for k, v in (("user", user), ("workdir", workdir), ("environment", environment))
        if v
    }
    control_options = {"user": user} if user else {}

    def control_command(script):
        result = container.exec_run(
            ["/bin/bash", "-c", script, "sforge-exec-control", control],
            **control_options,
        )
        if result.exit_code != 0:
            raise RuntimeError("Docker exec control operation failed")
        return result.output

    control_command(
        'umask 077; mkdir -- "$1" || exit; '
        'mkfifo -- "$1/hold" || { rmdir -- "$1"; exit 1; }'
    )
    chunks: list[bytes] = []
    errors: list[BaseException] = []
    thread = None
    log_fh = None
    exec_id = None
    terminal = False
    timed_out = False
    stop_requested = False

    def request_stop():
        nonlocal stop_requested
        if not stop_requested:
            control_command(': > "$1/stop"')
            stop_requested = True

    def inspect():
        return container.client.api.exec_inspect(exec_id)

    def wait_stopped():
        limit = time.monotonic() + _EXEC_SHUTDOWN_GRACE + _EXEC_DRAIN_GRACE
        while True:
            state = inspect()
            if not state["Running"] and state.get("ExitCode") is not None:
                if thread is not None:
                    thread.join(max(0, limit - time.monotonic()))
                if thread is not None and thread.is_alive():
                    raise RuntimeError(
                        "Docker exec stopped but output stream did not drain"
                    )
                return state
            if time.monotonic() >= limit:
                raise RuntimeError("Docker exec stop could not be confirmed")
            time.sleep(0.05)

    try:
        if log_file:
            log_file.parent.mkdir(parents=True, exist_ok=True)
            log_fh = open(log_file, "ab" if log_append else "wb")  # noqa: SIM115 -- ownership transfers to the reader thread
        deadline = start + timeout if timeout else None
        if (shutdown_event is not None and shutdown_event.is_set()) or (
            deadline is not None and time.monotonic() >= deadline
        ):
            terminal = True  # No exec was created or dispatched.
            return "", -1, True, time.monotonic() - start
        exec_id = container.client.api.exec_create(
            container.id,
            [
                "/bin/bash",
                "-c",
                _EXEC_SUPERVISOR,
                "sforge-exec-supervisor",
                control,
                str(_EXEC_SHUTDOWN_GRACE),
                str(_EXEC_DRAIN_GRACE),
                *argv,
            ],
            **options,
        )["Id"]
        if (shutdown_event is not None and shutdown_event.is_set()) or (
            deadline is not None and time.monotonic() >= deadline
        ):
            terminal = True  # exec_create alone never starts the command.
            return "", -1, True, time.monotonic() - start

        def read_stream():
            stream = None
            try:
                stream = container.client.api.exec_start(exec_id, stream=True)
                for chunk in stream:
                    chunks.append(chunk)
                    if log_fh:
                        log_fh.write(chunk)
                        log_fh.flush()
                    if stream_to_stdout:
                        sys.stdout.buffer.write(chunk)
                        sys.stdout.buffer.flush()
                    if on_chunk is not None:
                        try:
                            on_chunk(chunk)
                        except Exception:
                            pass  # Existing callback contract is best-effort.
            except BaseException as exc:  # noqa: BLE001 -- propagate worker failures to the caller
                errors.append(exc)
            finally:
                if stream is not None:
                    try:
                        stream.close()
                    except BaseException as exc:  # noqa: BLE001 -- propagate worker failures to the caller
                        errors.append(exc)
                # Only the writer closes the log. A failed stop must not leave
                # a live stream writing into a caller-closed file.
                if log_fh:
                    try:
                        log_fh.close()
                    except BaseException as exc:  # noqa: BLE001 -- propagate worker failures to the caller
                        errors.append(exc)

        thread = threading.Thread(
            target=read_stream, name="sforge-docker-exec", daemon=True
        )
        thread.start()
        while thread.is_alive():
            if (shutdown_event is not None and shutdown_event.is_set()) or (
                deadline is not None and time.monotonic() >= deadline
            ):
                timed_out = True
                request_stop()
                break
            thread.join(0.05)
        if errors:
            raise errors[0]
        state = wait_stopped()
        try:
            receipt = control_command('cat -- "$1/settled"')
            if int(receipt) != state["ExitCode"]:
                raise ValueError("exit-code mismatch")
        except Exception as exc:
            raise RuntimeError(
                "Docker exec shutdown receipt is missing or invalid"
            ) from exc
        terminal = True
        if errors:
            raise errors[0]
        if on_terminal is not None:
            on_terminal(state["ExitCode"])
        return (
            b"".join(chunks).decode(errors="replace"),
            -1 if timed_out else state["ExitCode"],
            timed_out,
            time.monotonic() - start,
        )
    except BaseException as original:
        if exec_id is not None and thread is not None and thread.ident is not None:
            try:
                request_stop()
                wait_stopped()
                terminal = True
            except Exception as cleanup_error:  # noqa: BLE001 -- preserve the original error
                if hasattr(original, "add_note"):
                    original.add_note(f"Exec cleanup unconfirmed: {cleanup_error}")
        else:
            terminal = True  # No stream thread could dispatch this exec.
        raise
    finally:
        if (thread is None or thread.ident is None) and log_fh:
            log_fh.close()
        if terminal or exec_id is None:
            # Only remove this invocation's known control entries.
            try:
                control_command(
                    'rm -f -- "$1/hold" "$1/result" "$1/result.tmp" "$1/stop" "$1/settled"; rmdir -- "$1"'
                )
            except Exception:  # noqa: BLE001 -- private control cleanup must not mask the exec outcome
                logging.getLogger(__name__).warning(
                    "Docker exec control files could not be removed"
                )


def cleanup_container(client, container, logger=None) -> None:
    """Stop and remove a Docker container. SIGINT is masked during cleanup."""
    if not container:
        return

    # Mask SIGINT so a second Ctrl+C cannot interrupt cleanup.
    # signal.signal() only works in the main thread; silently skip in workers.
    old_handler = None
    try:
        old_handler = signal.signal(signal.SIGINT, signal.SIG_IGN)
    except ValueError:
        pass

    container_id = container.id
    log_info = logger.info if logger else print
    log_error = logger.error if logger else print

    # Stop
    try:
        log_info(f"Stopping container {container.name}...")
        container.stop(timeout=15)
    except Exception as e:
        log_error(f"Failed to stop container {container.name}: {e}")
        try:
            container_info = client.api.inspect_container(container_id)
            pid = container_info["State"].get("Pid", 0)
            if pid > 0:
                log_info(f"Forcefully killing container PID {pid}...")
                os.kill(pid, signal.SIGKILL)
        except Exception as e2:
            log_error(f"Failed to kill container {container.name}: {e2}")

    # Remove
    try:
        log_info(f"Removing container {container.name}...")
        container.remove(force=True)
        log_info(f"Container {container.name} removed.")
    except Exception as e:
        log_error(
            f"Failed to remove container {container.name}: {e}\n"
            f"{traceback.format_exc()}"
        )

    if old_handler is not None:
        try:
            signal.signal(signal.SIGINT, old_handler)
        except ValueError:
            pass


def remove_image(client, image_id: str, logger=None) -> None:
    """Remove a Docker image by ID/tag."""
    log_info = logger.info if logger else print
    log_error = logger.error if logger else print
    try:
        log_info(f"Removing image {image_id}...")
        client.images.remove(image_id, force=True)
        log_info(f"Image {image_id} removed.")
    except Exception as e:
        log_error(f"Failed to remove image {image_id}: {e}")
