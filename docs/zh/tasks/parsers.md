# 测试输出解析器

解析器负责将 Judge 容器的原始测试输出转换为结构化评测结果，供 SForge 计算通过率、分数和反馈摘要。

在任务 JSON 中通过 `judge.parser` 选择解析器：

```json
{
  "judge": {
    "parser": "structured_json"
  }
}
```

SForge 当前内置 3 个解析器，推荐优先使用 `structured_json`：

| 解析器 | 输出格式 | 推荐场景 |
|--------|----------|----------|
| [`structured_json`](#structured-json) | 自定义 JSON 结果 | 新任务、复杂评测、同时需要 pass rate / score / summary / metrics 的任务 |
| [`pytest_v`](#pytest-v) | `pytest -v` 文本输出 | 简单 Python 单元测试任务 |
| [`score_sum`](#score-sum) | `CASE ... score=...` + `TOTAL_SCORE ...` | 竞赛编程、优化任务 |

## 推荐方式：`structured_json` {#structured-json}

`structured_json` 是最灵活的解析器。评测脚本直接输出 JSON，SForge 从中读取通过率、分数、摘要、逐项详情和指标。

**推荐输出格式**（字段均可选，但建议至少输出 `summary`、`score` 或 `details` 之一）：

```json
{
  "valid": true,
  "score": 15.0,
  "pass_rate": 0.75,
  "summary": "15/20 个目标已完成",
  "details": [
    {
      "name": "target_1",
      "status": "PASSED",
      "message": "检查通过",
      "score": 1.0,
      "weight": 1.0
    }
  ],
  "metrics": {
    "compile_time_seconds": 342
  }
}
```

**字段说明：**

| 字段 | 类型 | 说明 |
|------|------|------|
| `valid` | `bool` | 提交是否有效。无效提交可被 `valid_then_score` 选择策略过滤。默认 `true`。 |
| `score` | `number` | 连续分数，配合 `score_direction` 和 `selection` 用于排名。 |
| `pass_rate` | `number` | 显式通过率，范围通常为 `0.0` 到 `1.0`。未提供时可由 `details` 计算。 |
| `summary` | `string` | 人类可读摘要，会展示给 Agent。 |
| `details` | `list` | 逐项结果。每项可包含 `name`、`status`、`message`、`score`、`weight`。 |
| `metrics` | `dict` | 任意指标，用于日志记录和分析。 |

`details[].status` 使用 `PASSED`、`FAILED` 或 `ERROR`。

**推荐使用显式标记包裹 JSON：**

```text
>>>>> Start Structured Result
{
  "valid": true,
  "score": 15.0,
  "pass_rate": 0.75,
  "summary": "15/20 个目标已完成"
}
>>>>> End Structured Result
```

解析器也支持从输出中识别独立 JSON 对象；但使用标记更稳定，避免日志中的其他 JSON 被误识别。

当结果缺失、为空或无法解析，且没有 `TOTAL_SCORE` 时，报告会标记为无效（`valid=false`、`score=null`），并提供诊断摘要；这不代表零分。已有的数字 `TOTAL_SCORE` 回退（包括零）保持可用。没有数字分数的结果对象（例如仅报告通过率）仍然受支持。

**任务配置示例：**

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

`pytest_v` 解析标准 `pytest -v` 输出，适合简单 Python 单元测试任务。

**识别的状态：**

- `PASSED` -> 通过
- `FAILED` -> 失败
- `ERROR` -> 错误
- `XFAIL` / `XPASS` -> 计为通过
- `SKIPPED` -> 忽略

**输入示例：**

```text
tests/test_ops.py::test_add PASSED
tests/test_ops.py::test_mul FAILED
tests/test_ops.py::test_neg ERROR
========================= 1 passed, 1 failed, 1 error in 3.45s ==========================
```

**解析结果：**

```json
[
  {"name": "tests/test_ops.py::test_add", "status": "PASSED"},
  {"name": "tests/test_ops.py::test_mul", "status": "FAILED"},
  {"name": "tests/test_ops.py::test_neg", "status": "ERROR"}
]
```

**评测命令示例：**

```bash
python -m pytest tests/ -v
python -m pytest tests/ -v --forked
```

**任务配置示例：**

```json
{
  "judge": {
    "eval_cmd": "python -m pytest tests/ -v",
    "parser": "pytest_v"
  }
}
```

## `score_sum` {#score-sum}

`score_sum` 解析逐用例评分输出，适合竞赛编程和优化任务。

**预期格式：**

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

**状态码映射：**

| 代码 | 含义 | 映射状态 |
|------|------|----------|
| `OK` | 运行成功 | `PASSED` |
| `TLE` | 超时 | `FAILED` |
| `RE` | 运行时错误 | `FAILED` |
| `WA` | 答案错误 | `FAILED` |
| `CE` | 编译错误 | `FAILED` |

**解析结果：**

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
`TOTAL_SCORE` 不由 `score_sum` 解析器本身使用，而是由评分模块单独提取并写入 `EvalReport.score`。配合 `score_direction` 和 `selection` 可实现优化任务的连续评分。
:::

**任务配置示例：**

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
