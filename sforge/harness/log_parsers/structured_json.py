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

"""Parser for structured JSON evaluation output.

The eval runner / summarizer outputs a JSON object with standard fields.
This parser extracts it from the test output.

Expected JSON schema (all fields optional):
    {
        "valid": bool,
        "score": float,
        "pass_rate": float,
        "summary": str,
        "details": [{"name": str, "status": str, "message": str, ...}],
        "metrics": {str: Any}
    }
"""

from __future__ import annotations

import json
import re


def parse_structured_json(output: str) -> dict:
    """Extract a structured JSON result from eval output.

    Tries three strategies in order:
    1. Content between STRUCTURED_RESULT markers
    2. First JSON object that looks like a result (has score/valid/summary/details)
    3. Empty dict if nothing found
    """
    # Strategy 1: explicit markers
    marker_start = ">>>>> Start Structured Result"
    marker_end = ">>>>> End Structured Result"
    si = output.find(marker_start)
    ei = output.find(marker_end)
    if si != -1 and ei != -1:
        block = output[si + len(marker_start) : ei].strip()
        try:
            obj = json.loads(block)
            if isinstance(obj, dict):
                return obj
        except json.JSONDecodeError:
            pass

    # Strategy 2: find a JSON object in the output
    # Look for lines that start with '{' and try to parse them
    for m in re.finditer(r"^\s*\{", output, re.MULTILINE):
        try:
            candidate = output[m.start():]
            obj = json.loads(candidate[:_find_json_end(candidate)])
            if isinstance(obj, dict) and _looks_like_result(obj):
                return obj
        except (json.JSONDecodeError, ValueError):
            continue

    # Strategy 3: try the entire output as JSON
    try:
        obj = json.loads(output.strip())
        if isinstance(obj, dict):
            return obj
    except json.JSONDecodeError:
        pass

    return {}


def _find_json_end(text: str) -> int:
    """Find the end of a JSON object by brace matching."""
    depth = 0
    in_string = False
    escape = False
    for i, ch in enumerate(text):
        if escape:
            escape = False
            continue
        if ch == '\\' and in_string:
            escape = True
            continue
        if ch == '"' and not escape:
            in_string = not in_string
            continue
        if in_string:
            continue
        if ch == '{':
            depth += 1
        elif ch == '}':
            depth -= 1
            if depth == 0:
                return i + 1
    return len(text)


_RESULT_KEYS = {"valid", "score", "summary", "details", "metrics", "pass_rate"}


def _looks_like_result(obj: dict) -> bool:
    """Check if a JSON object looks like a structured result."""
    return bool(set(obj.keys()) & _RESULT_KEYS)
