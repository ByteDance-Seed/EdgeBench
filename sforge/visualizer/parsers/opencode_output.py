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

"""Parse opencode ``run --format json`` output into the shared Trajectory model.

opencode format (one JSON event per line; every event carries a top-level
``sessionID`` and a ``part`` object):

    {"type":"step_start","sessionID":..,"part":{"messageID":..,"snapshot":..}}
    {"type":"text",      "part":{"id":..,"messageID":..,"text":..,"time":..}}
    {"type":"tool_use",  "part":{"tool":"bash","callID":..,
                                 "state":{"status","input","output",..}}}
    {"type":"step_finish","part":{"reason":"stop"|"tool-calls",
                                  "tokens":{..},"cost":..}}
    {"type":"error",     "error":{"name":..,"data":{"message":..}}}

Each assistant step (grouped by ``part.messageID``) becomes one Exchange.
Tool results arrive inline in the ``tool_use`` event's ``state``, so no
cross-event folding is needed.  The trailing ``step_finish`` may be missing
when the process exits early — the parser tolerates truncated files.
"""

from __future__ import annotations

import json
from pathlib import Path

from sforge.visualizer.parsers.agent_output import (
    Exchange,
    ToolCall,
    Trajectory,
)

# opencode tool names are lowercase; map them onto the canonical names the
# shared ToolCall.summary property understands.
_TOOL_NAMES = {
    "bash": "Bash",
    "read": "Read",
    "write": "Write",
    "edit": "Edit",
    "patch": "Patch",
    "glob": "Glob",
    "grep": "Grep",
    "list": "List",
    "task": "Task",
    "todowrite": "TodoWrite",
    "todoread": "TodoRead",
    "webfetch": "WebFetch",
    "websearch": "WebSearch",
}


def parse(path: Path) -> Trajectory:
    traj = Trajectory()
    if not path.is_file():
        return traj

    exchanges: list[Exchange] = []
    current: Exchange | None = None
    current_message_id: str | None = None
    # part.id → position, so re-emitted parts update in place.
    text_parts: dict[str, int] = {}
    tool_parts: dict[str, ToolCall] = {}
    tokens_in = tokens_out = cache_read = cache_write = 0
    cost = 0.0

    def start_exchange(message_id: str | None) -> Exchange:
        nonlocal current, current_message_id
        ex = Exchange(idx=len(exchanges), role="assistant")
        exchanges.append(ex)
        current = ex
        current_message_id = message_id
        text_parts.clear()
        return ex

    def ensure_exchange(message_id: str | None) -> Exchange:
        if current is None or (
            message_id and message_id != current_message_id
        ):
            return start_exchange(message_id)
        return current

    with path.open("r", errors="replace") as fh:
        for line in fh:
            line = line.strip()
            if not line or not line.startswith("{"):
                continue
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                continue
            if not isinstance(event, dict):
                continue
            traj.total_events += 1

            etype = event.get("type", "")
            part = event.get("part") or {}
            message_id = part.get("messageID")

            if not traj.meta.get("session_id") and event.get("sessionID"):
                traj.meta["session_id"] = event["sessionID"]

            if etype == "step_start":
                start_exchange(message_id)

            elif etype == "text":
                ex = ensure_exchange(message_id)
                text = str(part.get("text", ""))
                part_id = part.get("id")
                blocks = ex.text.split("\n\n") if ex.text else []
                if part_id and part_id in text_parts:
                    blocks[text_parts[part_id]] = text
                else:
                    if part_id:
                        text_parts[part_id] = len(blocks)
                    blocks.append(text)
                ex.text = "\n\n".join(blocks)

            elif etype == "tool_use":
                ex = ensure_exchange(message_id)
                state = part.get("state") or {}
                call_id = str(part.get("callID") or part.get("id") or "")
                status = state.get("status", "")
                raw_name = str(part.get("tool", ""))
                tool = tool_parts.get(call_id)
                if tool is None:
                    tool = ToolCall(
                        id=call_id or f"opencode-tool-{traj.total_events}",
                        name=_TOOL_NAMES.get(raw_name, raw_name or "tool"),
                    )
                    tool_parts[call_id] = tool
                    ex.tool_calls.append(tool)
                inp = state.get("input")
                if isinstance(inp, dict):
                    tool.input = inp
                if status == "error":
                    tool.result_content = str(
                        state.get("error") or state.get("output") or ""
                    )
                    tool.result_is_error = True
                    tool.has_result = True
                elif status == "completed":
                    tool.result_content = str(state.get("output", ""))
                    tool.has_result = True

            elif etype == "step_finish":
                ex = ensure_exchange(message_id)
                ex.stop_reason = str(part.get("reason", ""))
                tokens = part.get("tokens") or {}
                tokens_in += int(tokens.get("input", 0) or 0)
                tokens_out += int(tokens.get("output", 0) or 0)
                cache = tokens.get("cache") or {}
                cache_read += int(cache.get("read", 0) or 0)
                cache_write += int(cache.get("write", 0) or 0)
                cost += float(part.get("cost", 0) or 0)

            elif etype == "error":
                err = event.get("error") or {}
                data = err.get("data") or {}
                msg = str(data.get("message") or err.get("name") or "error")
                ex = Exchange(
                    idx=len(exchanges), role="system", text=f"Error: {msg}",
                )
                exchanges.append(ex)
                current = None
                current_message_id = None

    traj.meta.update(
        {
            "agent_cli": "opencode",
            "tokens_input": tokens_in,
            "tokens_output": tokens_out,
            "cache_read": cache_read,
            "cache_write": cache_write,
        }
    )
    if cost:
        traj.meta["cost"] = round(cost, 4)

    # Drop empty exchanges left by step_start events with no content.
    exchanges = [
        ex for ex in exchanges
        if ex.text or ex.thinking or ex.tool_calls or ex.stop_reason
    ]
    for i, ex in enumerate(exchanges):
        ex.idx = i

    traj.exchanges = exchanges
    traj.tool_use_count = sum(len(ex.tool_calls) for ex in exchanges)
    return traj
