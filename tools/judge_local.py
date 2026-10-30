#!/usr/bin/env python3
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

"""Reference runner for the judge contract (see tasks/SCHEMA.md).

Usage:
  judge_local.py --task-dir tasks/<id> --image <judge image> --archive sub.tar.gz [--out out.json]
  judge_local.py --task-dir tasks/<id> --image <judge image> --empty

Prints one JSON line: {"raw_score", "score_0_100", "valid", "summary", "exit_code", "runtime_s", ...}.
Run with the SForge venv python so score_rescale is importable.
"""

from __future__ import annotations

import argparse
import json
import shlex
import subprocess
import sys
import time
import tomllib
import uuid
from pathlib import Path

SFORGE_DIR = "/opt/sforge"  # same as SForge's CONTAINER_DIR
RESULT_PATH = f"{SFORGE_DIR}/result.json"


def filter_files(names: list[str], paths: list[str], exclude: list[str]) -> list[str]:
    """SForge's own archive filter, so the semantics cannot drift."""
    from sforge.harness.run_evaluation import _filter_archive_files
    return _filter_archive_files(names, paths, [e.rstrip("/") for e in exclude])


def sh(args: list[str], **kw) -> subprocess.CompletedProcess:
    return subprocess.run(args, capture_output=True, text=True, **kw)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--task-dir", required=True)
    ap.add_argument("--image", required=True)
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--archive")
    g.add_argument("--empty", action="store_true")
    ap.add_argument("--out")
    ap.add_argument("--keep", action="store_true", help="keep container for debugging")
    a = ap.parse_args()

    spec = tomllib.loads((Path(a.task_dir) / "task.toml").read_text())
    env_, sub, judge, score = spec["environment"], spec["submission"], spec["judge"], spec.get("score", {})
    cwd = env_["cwd"]
    name = f"sforge-judge-{spec['id'][:40]}-{uuid.uuid4().hex[:8]}"

    run = ["docker", "run", "-d", "--name", name, "--network", "none", "--entrypoint", "sleep"]
    if judge.get("cpus"):
        run += ["--cpus", str(judge["cpus"])]
    if judge.get("memory"):
        run += ["--memory", str(judge["memory"])]
    r = sh(run + [a.image, "infinity"])
    if r.returncode != 0:
        print(json.dumps({"error": "docker run failed", "stderr": r.stderr[-2000:]}))
        return 2
    try:
        sh(["docker", "exec", name, "mkdir", "-p", SFORGE_DIR], check=True)
        if a.archive:
            sh(["docker", "cp", a.archive, f"{name}:{SFORGE_DIR}/submission.tar.gz"], check=True)
            names = sh(["docker", "exec", "-w", cwd, name, "tar", "--quoting-style=literal", "-tzf",
                        f"{SFORGE_DIR}/submission.tar.gz"], check=True).stdout.splitlines()
            allowed = filter_files(names, sub.get("paths", ["."]), sub.get("exclude", []))
            if allowed:
                lst = "\n".join(allowed) + "\n"
                subprocess.run(["docker", "exec", "-i", name, "sh", "-c", f"cat > {SFORGE_DIR}/allowed_files.txt"],
                               input=lst, text=True, check=True)
                sh(["docker", "exec", "-w", cwd, name, "tar", "xzf", f"{SFORGE_DIR}/submission.tar.gz",
                    "-T", f"{SFORGE_DIR}/allowed_files.txt"], check=True)
        t0 = time.time()
        cmd = judge["cmd"]
        try:
            jr = sh(["docker", "exec", "-w", cwd, name, "bash", "-c", cmd],
                    timeout=judge.get("timeout_sec", 600) + 30)
            exit_code, timed_out, log = jr.returncode, False, jr.stdout + jr.stderr
        except subprocess.TimeoutExpired as e:
            exit_code, timed_out, log = None, True, str(e.stdout or "")
        runtime = time.time() - t0
        res = sh(["docker", "exec", name, "cat", RESULT_PATH])
        try:
            result = json.loads(res.stdout) if res.returncode == 0 else {}
        except json.JSONDecodeError:
            result = {}
    finally:
        if not a.keep:
            sh(["docker", "rm", "-f", name])

    raw = result.get("score")
    valid = bool(result.get("valid", raw is not None))
    s100 = None
    if score.get("rescale") and raw is not None:
        from sforge.harness.score_rescale import parse_rescale_spec, rescale_score
        s100 = rescale_score(parse_rescale_spec(score["rescale"]), float(raw))
    out = {"task": spec["id"], "archive": a.archive or "<empty>", "raw_score": raw, "score_0_100": s100,
           "valid": valid, "summary": result.get("summary"), "exit_code": exit_code,
           "timed_out": timed_out, "runtime_s": round(runtime, 1),
           "result_found": bool(result), "log_tail": log[-3000:]}
    if a.out:
        Path(a.out).write_text(json.dumps(out, indent=1, ensure_ascii=False))
    print(json.dumps({k: v for k, v in out.items() if k != "log_tail"}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
