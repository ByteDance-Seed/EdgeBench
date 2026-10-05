# Test Output Parsers

Parsers convert raw judge-container output into structured evaluation results that SForge uses for pass rate, scoring, and feedback summaries.

Select a parser with `judge.parser` in the task JSON:

```json
{
  "judge": {
    "parser": "structured_json"
  }
}
```

SForge currently ships with 3 parsers. Prefer `structured_json` for new tasks:

| Parser | Output Format | Recommended Use |
|--------|---------------|-----------------|
| [`structured_json`](#structured-json) | Custom JSON result | New tasks, complex evaluators, tasks that need pass rate / score / summary / metrics |
| [`pytest_v`](#pytest-v) | `pytest -v` text output | Simple Python unit-test tasks |
| [`score_sum`](#score-sum) | `CASE ... score=...` + `TOTAL_SCORE ...` | Competitive programming and optimization tasks |

## Recommended: `structured_json` {#structured-json}

`structured_json` is the most flexible parser. The evaluation script prints JSON, and SForge reads pass rate, score, summary, per-item details, and metrics from it.

**Recommended output schema** (all fields are optional, but output at least one of `summary`, `score`, or `details`):

```json
{
  "valid": true,
  "score": 15.0,
  "pass_rate": 0.75,
  "summary": "15/20 targets completed",
  "details": [
    {
      "name": "target_1",
      "status": "PASSED",
      "message": "check passed",
      "score": 1.0,
      "weight": 1.0
    }
  ],
  "metrics": {
    "compile_time_seconds": 342
  }
}
```

**Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `valid` | `bool` | Whether the submission is valid. Invalid submissions can be filtered by `valid_then_score`. Defaults to `true`. |
| `score` | `number` | Continuous score used with `score_direction` and `selection` for ranking. |
| `pass_rate` | `number` | Explicit pass rate, usually from `0.0` to `1.0`. If omitted, it can be computed from `details`. |
| `summary` | `string` | Human-readable summary shown to the agent. |
| `details` | `list` | Per-item results. Each item can contain `name`, `status`, `message`, `score`, and `weight`. |
| `metrics` | `dict` | Arbitrary metrics for logging and analysis. |

Use `PASSED`, `FAILED`, or `ERROR` for `details[].status`.

**Prefer wrapping the JSON with explicit markers:**

```text
>>>>> Start Structured Result
{
  "valid": true,
  "score": 15.0,
  "pass_rate": 0.75,
  "summary": "15/20 targets completed"
}
>>>>> End Structured Result
```

The parser can also detect a standalone JSON object in the output, but markers are more robust because they avoid accidentally parsing unrelated JSON logs.

Missing, empty, or malformed result output with no `TOTAL_SCORE` now produces an invalid report (`valid=false`, `score=null`) with a diagnostic summary. It is not a zero score. Existing numeric `TOTAL_SCORE` fallback, including zero, is preserved. A result object without a numeric score (for example, pass-rate-only results) remains supported.

**Task config example:**

```json
{
  "judge": {
    "eval_cmd": "python /home/judge/eval.py /home/workspace",
    "parser": "structured_json",
    "score_direction": "maximize",
    "selection": "valid_then_score"
  }
}
```

## `pytest_v` {#pytest-v}

`pytest_v` parses standard `pytest -v` output and is suitable for simple Python unit-test tasks.

**Recognized statuses:**

- `PASSED` -> passed
- `FAILED` -> failed
- `ERROR` -> error
- `XFAIL` / `XPASS` -> counted as passed
- `SKIPPED` -> ignored

**Example input:**

```text
tests/test_ops.py::test_add PASSED
tests/test_ops.py::test_mul FAILED
tests/test_ops.py::test_neg ERROR
========================= 1 passed, 1 failed, 1 error in 3.45s ==========================
```

**Parsed output:**

```json
[
  {"name": "tests/test_ops.py::test_add", "status": "PASSED"},
  {"name": "tests/test_ops.py::test_mul", "status": "FAILED"},
  {"name": "tests/test_ops.py::test_neg", "status": "ERROR"}
]
```

**Eval command examples:**

```bash
python -m pytest tests/ -v
python -m pytest tests/ -v --forked
```

**Task config example:**

```json
{
  "judge": {
    "eval_cmd": "python -m pytest tests/ -v",
    "parser": "pytest_v"
  }
}
```

## `score_sum` {#score-sum}

`score_sum` parses per-case scoring output for competitive programming and optimization tasks.

**Expected format:**

```text
CASE 0000 OK score=12461
CASE 0001 OK score=13335.5
CASE 0002 TLE score=0
CASE 0003 RE score=0
CASE 0004 WA score=0
CASE 0005 CE score=0
TOTAL_SCORE 826577
CASES_OK 48
CASES_TOTAL 50
```

**Status codes:**

| Code | Meaning | Mapped Status |
|------|---------|---------------|
| `OK` | Ran successfully | `PASSED` |
| `TLE` | Time limit exceeded | `FAILED` |
| `RE` | Runtime error | `FAILED` |
| `WA` | Wrong answer | `FAILED` |
| `CE` | Compile error | `FAILED` |

**Parsed output:**

```json
[
  {"name": "case_0000", "status": "PASSED"},
  {"name": "case_0001", "status": "PASSED"},
  {"name": "case_0002_TLE", "status": "FAILED"},
  {"name": "case_0003_RE", "status": "FAILED"},
  {"name": "case_0004_WA", "status": "FAILED"},
  {"name": "case_0005_CE", "status": "FAILED"}
]
```

::: tip
`TOTAL_SCORE` is not used by the `score_sum` parser itself. The grading module extracts it separately and stores it in `EvalReport.score`. Combined with `score_direction` and `selection`, this enables continuous scoring for optimization tasks.
:::

**Task config example:**

```json
{
  "judge": {
    "eval_cmd": "./run_eval.sh",
    "parser": "score_sum",
    "score_direction": "maximize",
    "selection": "score_first"
  }
}
```
