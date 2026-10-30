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

"""Open a run's archived agent session in the agent's own UI.

The run directory holds the container's session files under ``sessions/``
(container paths kept). They are copied into a throwaway config home and the
locally installed CLI is started in resume mode, so the transcript renders
exactly as the agent shows it. Nothing is sent to a model unless you type.
"""

from __future__ import annotations

import json
import os
import re
import shutil
import tempfile
from pathlib import Path


def _new_home() -> Path:
    # Not under /tmp: codex refuses to install its helpers in temp dirs.
    root = Path(os.environ.get("SFORGE_CACHE_DIR") or Path.home() / ".cache" / "sforge") / "replay"
    root.mkdir(parents=True, exist_ok=True)
    return Path(tempfile.mkdtemp(dir=root))


def _latest(paths: list[Path]) -> Path:
    if not paths:
        raise SystemExit("No session files found in this run.")
    return max(paths, key=lambda p: p.stat().st_mtime)


def _claude(sessions: Path, session_id: str | None) -> tuple[list[str], dict, Path]:
    src = sessions / "root" / ".claude" / "projects"
    home = _new_home()
    work = home / "workspace"
    work.mkdir()
    # Claude Code keys projects by the cwd with non-alphanumerics replaced by "-".
    proj = home / ".claude" / "projects" / re.sub(r"[^a-zA-Z0-9]", "-", str(work))
    proj.mkdir(parents=True)
    for project in src.iterdir() if src.is_dir() else []:
        shutil.copytree(project, proj, dirs_exist_ok=True)
    sid = session_id or _latest(list(proj.glob("*.jsonl"))).stem
    return ["claude", "--resume", sid], {"CLAUDE_CONFIG_DIR": str(home / ".claude")}, work


def _codex(sessions: Path, session_id: str | None) -> tuple[list[str], dict, Path]:
    src = sessions / "root" / ".codex" / "sessions"
    home = _new_home()
    codex_home = home / ".codex"
    shutil.copytree(src, codex_home / "sessions")
    if session_id is None:
        rollout = _latest(list((codex_home / "sessions").rglob("rollout-*.jsonl")))
        session_id = json.loads(rollout.read_text().splitlines()[0])["payload"]["id"]
    for name in ("auth.json", "config.toml"):  # reuse the viewer's own login
        own = Path.home() / ".codex" / name
        if own.exists():
            shutil.copy(own, codex_home / name)
    return ["codex", "resume", session_id], {"CODEX_HOME": str(codex_home)}, home


def replay(task_dir: Path, session_id: str | None = None) -> None:
    final = json.loads((task_dir / "final_result.json").read_text()) \
        if (task_dir / "final_result.json").exists() else {}
    agent = (final.get("agent") or json.loads((task_dir / "run_config.json").read_text())["agent"])
    agent = agent.partition("@")[0]
    sessions = task_dir / "sessions"
    if not sessions.is_dir():
        raise SystemExit(f"{task_dir} has no archived sessions.")
    if agent == "claude-code":
        argv, env, cwd = _claude(sessions, session_id)
    elif agent == "codex":
        argv, env, cwd = _codex(sessions, session_id)
    else:
        raise SystemExit(f"Replay is not supported for {agent}; session files are in {sessions}")
    if shutil.which(argv[0]) is None:
        raise SystemExit(f"`{argv[0]}` is not installed on this machine.")
    print(f"Replaying {agent} session {argv[-1]} (Ctrl+C to quit; nothing is sent unless you type)")
    os.chdir(cwd)
    os.execvpe(argv[0], argv, {**os.environ, **env})
