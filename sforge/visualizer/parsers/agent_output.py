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

"""Parse Claude-Code stream-json agent output into a viewable trajectory.

Event types (one JSON per line):
    {"type":"system","subtype":"init", model, tools, session_id, ...}
    {"type":"assistant","message":{content:[text|thinking|tool_use...], usage, ...}, uuid, ...}
    {"type":"user","message":{content:[tool_result...] | [text...]}, timestamp, ...}
    {"type":"result", ...}                         # final summary, not always present

Transforms into Exchanges (chat units), with tool_results folded into the
preceding assistant exchange via tool_use_id matching. Stop-hook synthetic
user messages become SubmissionMarker nodes (inserted between exchanges).
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Optional

_STOP_HOOK_PREFIX = "Stop hook feedback"
# "Submitting <label> for evaluation" — label may be "round 1" or "agent-3"
_RE_ROUND = re.compile(r"Submitting\s+(\S+(?:\s+\d+)?)\s+for evaluation")
_RE_PASS_RATE = re.compile(r"Pass rate:\s+([\d.]+)%")
_RE_PASSED = re.compile(r"Passed:\s+(\d+)/(\d+)")
_RE_BEST = re.compile(r"Best score:\s+([\d.]+)%")
_RE_BEST_WITH_SCORE = re.compile(r"Best score:\s+([\d.]+)\s+\(round")
_RE_SCORE = re.compile(r"Score:\s+([\d.]+)")


@dataclass
class ToolCall:
    id: str
    name: str
    input: dict[str, Any] = field(default_factory=dict)
    result_content: str = ""
    result_is_error: bool = False
    has_result: bool = False
    # Subagent (Task/Agent) nested exchanges. Populated when subsequent events
    # carry parent_tool_use_id == this.id.
    sub_exchanges: list["Exchange"] = field(default_factory=list)

    @property
    def summary(self) -> str:
        """One-line description used as the collapsed header."""
        inp = self.input or {}
        if self.name == "Bash":
            cmd = str(inp.get("command", ""))
            return cmd.splitlines()[0][:160] if cmd else ""
        if self.name in ("Read", "NotebookEdit"):
            return str(
                inp.get("file_path")
                or inp.get("filePath")  # opencode uses camelCase
                or inp.get("notebook_path", "")
            )
        if self.name == "Edit":
            fp = inp.get("file_path") or inp.get("filePath", "")
            old = len(str(inp.get("old_string") or inp.get("oldString", "")))
            new = len(str(inp.get("new_string") or inp.get("newString", "")))
            return f"{fp}  ({old}→{new} chars)"
        if self.name == "Write":
            fp = inp.get("file_path") or inp.get("filePath", "")
            return f"{fp}  ({len(str(inp.get('content', '')))} chars)"
        if self.name == "Glob":
            return str(inp.get("pattern", ""))
        if self.name == "Grep":
            return str(inp.get("pattern", ""))
        if self.name == "Task":
            return str(inp.get("description", "") or inp.get("subagent_type", ""))
        if self.name == "TodoWrite":
            todos = inp.get("todos", [])
            return f"{len(todos)} todo(s)"
        # Fallback: serialize first few keys
        s = json.dumps(inp, ensure_ascii=False)
        return s[:160]

    @property
    def input_json(self) -> str:
        return json.dumps(self.input, indent=2, ensure_ascii=False)


@dataclass
class Exchange:
    idx: int
    role: str  # "assistant" | "user"
    text: str = ""
    thinking: str = ""
    tool_calls: list[ToolCall] = field(default_factory=list)
    model: str = ""
    ts: Optional[str] = None
    stop_reason: str = ""


@dataclass
class SubmissionMarker:
    after_idx: int            # inserted after this exchange index
    round_label: str = ""     # e.g. "round 1" or "agent-3"
    pass_rate: Optional[float] = None  # 0-1
    score: Optional[float] = None     # raw score (for scored tasks)
    passed: Optional[int] = None
    total: Optional[int] = None
    best_so_far: Optional[float] = None  # 0-1 (pass_rate) or raw score
    feedback: str = ""        # full stop-hook text
    anchor_idx: int = 0       # global marker index, filled post-sort


@dataclass
class Trajectory:
    meta: dict[str, Any] = field(default_factory=dict)
    exchanges: list[Exchange] = field(default_factory=list)
    markers: list[SubmissionMarker] = field(default_factory=list)
    total_events: int = 0
    tool_use_count: int = 0


# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #

def _text_of(block_content: Any) -> str:
    """tool_result.content may be a str or a list of {type:text,text:...}."""
    if isinstance(block_content, str):
        return block_content
    if isinstance(block_content, list):
        parts: list[str] = []
        for item in block_content:
            if isinstance(item, dict):
                parts.append(str(item.get("text", "")))
            else:
                parts.append(str(item))
        return "".join(parts)
    return str(block_content or "")


def _extract_stop_hook_marker(text: str, after_idx: int) -> SubmissionMarker:
    mk = SubmissionMarker(after_idx=after_idx, feedback=text)
    if m := _RE_ROUND.search(text):
        mk.round_label = m.group(1)
    if m := _RE_PASS_RATE.search(text):
        try:
            mk.pass_rate = float(m.group(1)) / 100.0
        except ValueError:
            pass
    if m := _RE_PASSED.search(text):
        try:
            mk.passed = int(m.group(1))
            mk.total = int(m.group(2))
        except ValueError:
            pass
    if m := _RE_BEST.search(text):
        try:
            mk.best_so_far = float(m.group(1)) / 100.0
        except ValueError:
            pass
    elif m := _RE_BEST_WITH_SCORE.search(text):
        try:
            mk.best_so_far = float(m.group(1))
        except ValueError:
            pass
    if m := _RE_SCORE.search(text):
        try:
            mk.score = float(m.group(1))
        except ValueError:
            pass
    return mk


# --------------------------------------------------------------------------- #
# Parse
# --------------------------------------------------------------------------- #

def parse(path: Path) -> Trajectory:
    traj = Trajectory()
    if not path.is_file():
        return traj

    # Global tool_use_id → ToolCall. tool_results arrive out-of-order relative
    # to the assistant events that emitted the calls (results can span
    # multiple subsequent user events, in any order), so we can't rely on
    # "most recent assistant" for pairing.
    all_calls: dict[str, ToolCall] = {}
    # A single global counter for Exchange.idx so anchors don't collide across
    # main timeline and nested subagent timelines.
    next_idx = [0]

    def new_idx() -> int:
        v = next_idx[0]
        next_idx[0] = v + 1
        return v

    last_assistant_idx: Optional[int] = None  # top-level only; for marker anchor

    with path.open("r", errors="replace") as fh:
        for raw in fh:
            raw = raw.strip()
            if not raw:
                continue
            try:
                event = json.loads(raw)
            except json.JSONDecodeError:
                continue
            traj.total_events += 1
            etype = event.get("type")

            if etype == "system":
                if event.get("subtype") == "init" and not traj.meta:
                    traj.meta = {
                        "model": event.get("model"),
                        "session_id": event.get("session_id"),
                        "cwd": event.get("cwd"),
                        "tools": event.get("tools"),
                        "permissionMode": event.get("permissionMode"),
                        "claude_code_version": event.get("claude_code_version"),
                    }
                    # Emit a synthetic system exchange so it shows at the top
                    # of the trajectory. Summary is human-readable; full init
                    # dict is stashed on the exchange for template rendering.
                    summary_lines = [
                        f"model: {event.get('model', '?')}",
                        f"claude_code: {event.get('claude_code_version', '?')}",
                        f"permission: {event.get('permissionMode', '?')}",
                        f"cwd: {event.get('cwd', '?')}",
                    ]
                    tools = event.get("tools") or []
                    if tools:
                        summary_lines.append(f"tools ({len(tools)}): {', '.join(tools)}")
                    sid = event.get("session_id")
                    if sid:
                        summary_lines.append(f"session: {sid}")
                    ex = Exchange(
                        idx=new_idx(),
                        role="system",
                        text="\n".join(summary_lines),
                    )
                    traj.exchanges.append(ex)
                continue

            # Route this event into the main timeline or a subagent's
            # sub_exchanges based on parent_tool_use_id.
            parent_id = event.get("parent_tool_use_id")
            parent_call = all_calls.get(parent_id) if parent_id else None
            target_list = parent_call.sub_exchanges if parent_call is not None else traj.exchanges
            # last_assistant_idx is only used for stop-hook marker anchoring,
            # which only makes sense at the main timeline level.
            is_top_level = parent_call is None

            if etype == "assistant":
                msg = event.get("message") or {}
                content = msg.get("content") or []
                ex = Exchange(
                    idx=new_idx(),
                    role="assistant",
                    model=msg.get("model", "") or "",
                    ts=event.get("timestamp"),
                    stop_reason=msg.get("stop_reason", "") or "",
                )
                for block in content:
                    if not isinstance(block, dict):
                        continue
                    btype = block.get("type")
                    if btype == "text":
                        ex.text += block.get("text", "")
                    elif btype in ("thinking", "redacted_thinking"):
                        ex.thinking += block.get("thinking", "") or "[redacted]"
                    elif btype == "tool_use":
                        tc = ToolCall(
                            id=block.get("id", ""),
                            name=block.get("name", ""),
                            input=block.get("input", {}) or {},
                        )
                        ex.tool_calls.append(tc)
                        if tc.id:
                            all_calls[tc.id] = tc
                        traj.tool_use_count += 1
                target_list.append(ex)
                if is_top_level and (ex.tool_calls or ex.text):
                    last_assistant_idx = ex.idx
                continue

            if etype == "user":
                msg = event.get("message") or {}
                content = msg.get("content") or []
                if not isinstance(content, list):
                    content = [content] if content else []

                tool_results = [
                    b for b in content
                    if isinstance(b, dict) and b.get("type") == "tool_result"
                ]
                text_blocks = [
                    b for b in content
                    if isinstance(b, dict) and b.get("type") == "text"
                ]

                if tool_results:
                    for tr in tool_results:
                        tc = all_calls.get(tr.get("tool_use_id", ""))
                        if tc is None:
                            continue
                        tc.result_content = _text_of(tr.get("content"))
                        tc.result_is_error = bool(tr.get("is_error"))
                        tc.has_result = True
                    continue

                if text_blocks:
                    joined = "".join(b.get("text", "") for b in text_blocks)
                    if is_top_level and _STOP_HOOK_PREFIX in joined and last_assistant_idx is not None:
                        traj.markers.append(
                            _extract_stop_hook_marker(joined, last_assistant_idx)
                        )
                    else:
                        target_list.append(Exchange(
                            idx=new_idx(),
                            role="user",
                            text=joined,
                            ts=event.get("timestamp"),
                        ))
                continue

            # "result" or unknown type: skip silently.

    traj.markers.sort(key=lambda m: m.after_idx)
    for i, m in enumerate(traj.markers):
        m.anchor_idx = i
    return traj


# --------------------------------------------------------------------------- #
# Cache
# --------------------------------------------------------------------------- #

_CACHE: dict[tuple[str, float, int], Trajectory] = {}
_CACHE_LIMIT = 16


def get_trajectory(path: Path) -> Optional[Trajectory]:
    """Parse with in-process caching keyed by (path, mtime, size).

    Dispatches to the appropriate parser based on the file's first bytes:
    - Claude Code: stream-json (first line is JSON starting with `{`)
    - opencode: JSONL whose events carry a top-level camelCase "sessionID"
    - OpenAI Codex: plain text starting with "OpenAI Codex" or
      "Reading additional input from stdin..."
    """
    if not path.is_file():
        return None
    try:
        st = path.stat()
    except OSError:
        return None
    key = (str(path.resolve()), st.st_mtime, st.st_size)
    cached = _CACHE.get(key)
    if cached is not None:
        return cached

    # Format detection: peek at the first ~512 bytes.
    try:
        with path.open("r", errors="replace") as fh:
            head = fh.read(512)
    except OSError:
        head = ""

    if "OpenAI Codex" in head or head.lstrip().startswith("Reading additional input"):
        from sforge.visualizer.parsers.codex_output import parse as _codex_parse
        traj = _codex_parse(path)
    elif head.lstrip().startswith("{") and '"sessionID"' in head:
        # opencode events use camelCase sessionID; Claude Code uses session_id.
        from sforge.visualizer.parsers.opencode_output import parse as _opencode_parse
        traj = _opencode_parse(path)
    else:
        traj = parse(path)

    if len(_CACHE) >= _CACHE_LIMIT:
        _CACHE.pop(next(iter(_CACHE)))
    _CACHE[key] = traj
    return traj
