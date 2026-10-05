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

"""Grading: parse test output and compute pass rate."""

from __future__ import annotations

import re
from dataclasses import dataclass, field, asdict
from typing import Any

from sforge.harness.constants import (
    START_TEST_OUTPUT,
    END_TEST_OUTPUT,
    PASSED,
    FAILED,
    ERROR,
)
from sforge.harness.log_parsers import get_parser
from sforge.harness.task_spec import TaskSpec

SUMMARY_MAX_LEN = 4096


@dataclass
class EvalDetail:
    name: str
    status: str
    message: str | None = None
    score: float | None = None
    weight: float | None = None


@dataclass
class EvalReport:
    task_id: str
    submission_id: str
    total_tests: int = 0
    passed: int = 0
    failed: int = 0
    errors: int = 0
    pass_rate: float = 0.0
    score: float | None = None
    score_0_100: float | None = None
    timed_out: bool = False
    runtime_seconds: float = 0.0
    test_details: list[dict] = field(default_factory=list)
    raw_output: str = ""
    valid: bool = True
    summary: str | None = None
    details: list[EvalDetail] = field(default_factory=list)
    metrics: dict[str, Any] = field(default_factory=dict)
    submitted_at: float = 0.0

    def to_dict(self) -> dict:
        d = asdict(self)
        d.pop("raw_output", None)
        if d.get("summary") and len(d["summary"]) > SUMMARY_MAX_LEN:
            d["summary"] = d["summary"][:SUMMARY_MAX_LEN]
        return d


def extract_score(test_output: str) -> float | None:
    """Extract TOTAL_SCORE from test output (for continuous scoring tasks)."""
    m = re.search(r"TOTAL_SCORE\s+(inf|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)", test_output)
    return float(m.group(1)) if m else None


def extract_test_output(raw_output: str) -> str:
    """Extract content between START/END markers, or return full output.

    Markers are anchored at line start so that `set -x` xtrace lines like
    ``+ echo '>>>>> End Test Output'`` don't match first and accidentally
    truncate the real test output that follows. Uses the FIRST line-start
    START marker and the LAST line-start END marker.
    """
    start_tok = "\n" + START_TEST_OUTPUT
    end_tok = "\n" + END_TEST_OUTPUT
    found_start = False
    start_idx = raw_output.find(start_tok)
    if start_idx != -1:
        start_idx += 1
        found_start = True
    elif raw_output.startswith(START_TEST_OUTPUT):
        start_idx = 0
        found_start = True
    end_idx = raw_output.rfind(end_tok)
    if found_start and end_idx != -1 and end_idx > start_idx:
        return raw_output[start_idx + len(START_TEST_OUTPUT) : end_idx].strip()
    return raw_output


def _grade_legacy(
    task_spec: TaskSpec,
    test_output: str,
    submission_id: str,
    timed_out: bool,
    runtime: float,
    raw_output: str,
) -> EvalReport:
    """Grade using a legacy parser that returns list[dict] of test results."""
    parser = get_parser(task_spec.judge.parser)
    test_results = parser(test_output)

    total = len(test_results)
    passed = sum(1 for r in test_results if r["status"] == PASSED)
    failed = sum(1 for r in test_results if r["status"] == FAILED)
    errors = sum(1 for r in test_results if r["status"] == ERROR)
    pass_rate = passed / total if total > 0 else 0.0

    details = [
        EvalDetail(name=r.get("name", ""), status=r["status"])
        for r in test_results
    ]

    if total > 0:
        summary = f"{passed}/{total} tests passed"
        failed_names = [r.get("name", "") for r in test_results if r["status"] != PASSED]
        if failed_names:
            shown = failed_names[:10]
            summary += f". Failed: {', '.join(shown)}"
            if len(failed_names) > 10:
                summary += f" (+{len(failed_names) - 10} more)"
    else:
        summary = "No tests found"

    return EvalReport(
        task_id=task_spec.task_id,
        submission_id=submission_id,
        total_tests=total,
        passed=passed,
        failed=failed,
        errors=errors,
        pass_rate=pass_rate,
        score=extract_score(test_output),
        timed_out=timed_out,
        runtime_seconds=runtime,
        test_details=test_results,
        raw_output=raw_output,
        valid=True,
        summary=summary,
        details=details,
    )


def _grade_structured(
    task_spec: TaskSpec,
    test_output: str,
    submission_id: str,
    timed_out: bool,
    runtime: float,
    raw_output: str,
) -> EvalReport:
    """Grade using structured JSON output from eval runner."""
    from sforge.harness.log_parsers.structured_json import parse_structured_json

    data = parse_structured_json(test_output)
    fallback_score = extract_score(test_output)
    if not data and fallback_score is None:
        return EvalReport(
            task_id=task_spec.task_id,
            submission_id=submission_id,
            timed_out=timed_out,
            runtime_seconds=runtime,
            raw_output=raw_output,
            valid=False,
            summary=(
                "No structured evaluation result or TOTAL_SCORE was produced; "
                "inspect the evaluator output for build or execution failures."
            ),
        )

    raw_details = data.get("details", [])
    details = [
        EvalDetail(
            name=d.get("name", ""),
            status=d.get("status", ""),
            message=d.get("message"),
            score=d.get("score"),
            weight=d.get("weight"),
        )
        for d in raw_details
    ]

    # Compute pass/fail from details if not explicitly provided
    if raw_details:
        passed = sum(1 for d in raw_details if d.get("status") == PASSED)
        failed = sum(1 for d in raw_details if d.get("status") == FAILED)
        errors = sum(1 for d in raw_details if d.get("status") == ERROR)
        total = len(raw_details)
    else:
        passed = data.get("passed", 0)
        failed = data.get("failed", 0)
        errors = data.get("errors", 0)
        total = data.get("total_tests", 0)

    pass_rate = data.get("pass_rate")
    if pass_rate is None and total > 0:
        pass_rate = passed / total
    elif pass_rate is None:
        pass_rate = 0.0

    score = data.get("score")
    if score is None:
        score = fallback_score

    return EvalReport(
        task_id=task_spec.task_id,
        submission_id=submission_id,
        total_tests=total,
        passed=passed,
        failed=failed,
        errors=errors,
        pass_rate=pass_rate,
        score=score,
        timed_out=timed_out,
        runtime_seconds=runtime,
        test_details=[],
        raw_output=raw_output,
        valid=data.get("valid", True),
        summary=data.get("summary"),
        details=details,
        metrics=data.get("metrics", {}),
    )


def grade_output(
    task_spec: TaskSpec,
    raw_output: str,
    submission_id: str,
    timed_out: bool = False,
    runtime: float = 0.0,
) -> EvalReport:
    """Parse test output and compute pass rate."""
    test_output = extract_test_output(raw_output)

    if task_spec.judge.parser == "structured_json":
        return _grade_structured(
            task_spec, test_output, submission_id, timed_out, runtime, raw_output
        )

    return _grade_legacy(
        task_spec, test_output, submission_id, timed_out, runtime, raw_output
    )
