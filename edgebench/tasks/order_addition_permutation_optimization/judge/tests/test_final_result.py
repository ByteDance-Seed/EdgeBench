from __future__ import annotations

import hashlib
import importlib.util
import math
import sys
from pathlib import Path


TESTS_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = Path(__file__).resolve().parents[1]
BASELINE_PATH = PROJECT_ROOT / "vcpom_m1000_final_result.txt"
RESULT_PATH = PROJECT_ROOT / "final_result.txt"
PRIVATE_COST_MODULE_PATH = TESTS_DIR / "cost_complex_cy.cpython-311-x86_64-linux-gnu.so"
PRIVATE_SCORE_HELPER_PATH = TESTS_DIR / "score_vcpom_result.py"
EXPECTED_BASELINE_SHA256 = "0abc5e7e03064a065bc1ecc84fa888656e092979f058bb7b7f63cbaab29a743b"
EXPECTED_COST_MODULE_SHA256 = "5329caa78aaa65fa572ca949eaf2a3c5cc66f2362296ba054d72cba12945b552"
EXPECTED_SCORE_HELPER_SHA256 = "3023b9a449119e862d4ca86d3ab45599e2496e182be82959a642522f915dbbac"
M = 1000
SCAN_SUFFIXES = {".py", ".pyw", ".ipynb", ".sh"}
SCAN_EXCLUDED_DIRS = {".git", "__pycache__", ".pytest_cache", "tests"}
FORBIDDEN_PRIVATE_ACCESS_PATTERNS = {
    "_build_ctx": "Do not call cost_complex_cy._build_ctx or any equivalent private data builder.",
    "cost_complex_cy._build": "Do not call private cost module data builders.",
    "cost_complex_cy._ctx": "Do not access private cost module context objects.",
    "cost_complex_cy._data": "Do not access private cost module data objects.",
    "cost_complex_cy._cache": "Do not access private cost module caches.",
    "getattr(cost_complex_cy": "Do not inspect or dynamically access private cost_complex_cy attributes.",
    "dir(cost_complex_cy": "Do not inspect the cost_complex_cy module to discover private APIs.",
    "cost_complex_cy.__dict__": "Do not inspect the cost_complex_cy module dictionary.",
}


def _load_module_from_path(module_name: str, path: Path):
    spec = importlib.util.spec_from_file_location(module_name, path)
    assert spec is not None and spec.loader is not None, f"cannot load module from {path}"
    module = importlib.util.module_from_spec(spec)
    sys.modules[module_name] = module
    spec.loader.exec_module(module)
    return module


sys.modules.pop("cost_complex_cy", None)
_cost_module = _load_module_from_path("cost_complex_cy", PRIVATE_COST_MODULE_PATH)
_score_helper = _load_module_from_path("_judge_score_vcpom_result", PRIVATE_SCORE_HELPER_PATH)
cost_complex_with_builtin_data = _cost_module.cost_complex_with_builtin_data
parse_result_file = _score_helper.parse_result_file
score_cost_num = _score_helper.score_cost_num


def _read_key_value_file(path: Path) -> dict[str, str]:
    data: dict[str, str] = {}
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or "=" not in line:
            continue
        key, value = line.split("=", 1)
        data[key.strip()] = value.strip()
    return data


def _iter_submitted_source_files() -> list[Path]:
    files: list[Path] = []
    for path in PROJECT_ROOT.rglob("*"):
        if not path.is_file():
            continue
        if any(part in SCAN_EXCLUDED_DIRS for part in path.relative_to(PROJECT_ROOT).parts):
            continue
        if path.suffix in SCAN_SUFFIXES:
            files.append(path)
    return files


def test_no_private_cost_module_access() -> None:
    violations: list[str] = []
    for path in _iter_submitted_source_files():
        text = path.read_text(encoding="utf-8", errors="ignore")
        rel = path.relative_to(PROJECT_ROOT)
        for pattern, hint in FORBIDDEN_PRIVATE_ACCESS_PATTERNS.items():
            if pattern in text:
                violations.append(f"{rel}: forbidden pattern {pattern!r}. {hint}")

    if violations:
        print("TOTAL_SCORE 0")
        print("FORBIDDEN_PRIVATE_COST_MODULE_ACCESS")
        for violation in violations[:20]:
            print(violation)
        raise AssertionError(
            "Submission used private cost module internals. "
            "Only call cost_complex_with_builtin_data(...) as the black-box evaluator."
        )


def test_private_judge_files_are_available() -> None:
    assert PRIVATE_COST_MODULE_PATH.exists(), "judge cost module is missing"
    assert PRIVATE_SCORE_HELPER_PATH.exists(), "judge score helper is missing"
    assert hashlib.sha256(PRIVATE_COST_MODULE_PATH.read_bytes()).hexdigest() == EXPECTED_COST_MODULE_SHA256
    assert hashlib.sha256(PRIVATE_SCORE_HELPER_PATH.read_bytes()).hexdigest() == EXPECTED_SCORE_HELPER_SHA256


def test_baseline_file_was_not_modified() -> None:
    assert BASELINE_PATH.exists(), "baseline file vcpom_m1000_final_result.txt is missing"
    actual_hash = hashlib.sha256(BASELINE_PATH.read_bytes()).hexdigest()
    assert actual_hash == EXPECTED_BASELINE_SHA256, (
        "Do not modify vcpom_m1000_final_result.txt. "
        "Write your answer to final_result.txt instead."
    )
    assert "final_pai" not in _read_key_value_file(BASELINE_PATH), (
        "baseline file must not expose final_pai"
    )


def test_final_result_exists_and_has_required_fields() -> None:
    assert RESULT_PATH.exists(), "missing final_result.txt"
    data = _read_key_value_file(RESULT_PATH)

    assert "final_pai" in data and data["final_pai"], "final_result.txt must contain final_pai"
    assert {"final_cost", "my_cost"} & data.keys(), (
        "final_result.txt must contain final_cost or my_cost"
    )
    assert {"num", "final_num", "my_num"} & data.keys(), (
        "final_result.txt must contain num, final_num, or my_num"
    )


def test_final_result_is_valid_permutation_and_cost() -> None:
    parsed = parse_result_file(RESULT_PATH)
    final_pai = parsed["final_pai"]
    final_cost = float(parsed["final_cost"])
    num = int(parsed["num"])

    assert len(final_pai) == M, f"final_pai must contain exactly {M} integers"
    assert sorted(final_pai) == list(range(1, M + 1)), (
        "final_pai must be a permutation of 1..1000 with no duplicates or missing values"
    )
    assert num > 0, "num/final_num/my_num must be a positive integer"

    recomputed_cost = cost_complex_with_builtin_data(final_pai, m=M, seed=1)
    assert math.isclose(final_cost, recomputed_cost, rel_tol=1e-10, abs_tol=1e-3), (
        f"reported cost {final_cost} does not match recomputed cost {recomputed_cost}"
    )

    score = score_cost_num(cost=recomputed_cost, num=num)
    print(f"TOTAL_SCORE {score:.10f}")
