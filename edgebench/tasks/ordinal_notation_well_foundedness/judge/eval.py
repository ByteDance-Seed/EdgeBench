#!/usr/bin/env python3
from __future__ import annotations

import json
import shutil
import subprocess
from pathlib import Path


ROOT = Path('/home/workspace/ordinal_notation_wf')
TASK_ID = 'ordinal_notation_wf'
COQC_FLAGS = []
TASKS = [{'name': 'task1', 'task_file': 'task1.v', 'eval_file': 'eval_task1.v', 'weight': 1}, {'name': 'task2', 'task_file': 'task2.v', 'eval_file': 'eval_task2.v', 'weight': 2}, {'name': 'task3', 'task_file': 'task3.v', 'eval_file': 'eval_task3.v', 'weight': 2}, {'name': 'task4', 'task_file': 'task4.v', 'eval_file': 'eval_task4.v', 'weight': 4}, {'name': 'task5', 'task_file': 'task5.v', 'eval_file': 'eval_task5.v', 'weight': 4}, {'name': 'task6', 'task_file': 'task6.v', 'eval_file': 'eval_task6.v', 'weight': 8}, {'name': 'task7', 'task_file': 'task7.v', 'eval_file': 'eval_task7.v', 'weight': 16}, {'name': 'task8', 'task_file': 'task8.v', 'eval_file': 'eval_task8.v', 'weight': 16}, {'name': 'task9', 'task_file': 'task9.v', 'eval_file': 'eval_task9.v', 'weight': 32}]
CASE_TIMEOUT_SECONDS = 300


def clean_artifacts() -> None:
    patterns = [
        "*.vo", "*.vos", "*.vok", "*.vio", "*.glob", "*.aux", ".*.aux",
        "*.d", "*.vio", "*.vio.d", "*.vo.d", "Makefile.coq", "Makefile.coq.conf",
    ]
    for pattern in patterns:
        for path in ROOT.glob(pattern):
            if path.is_file() or path.is_symlink():
                path.unlink()
    shutil.rmtree(ROOT / ".coq-native", ignore_errors=True)


def run_cmd(cmd: list[str], timeout: int | None = None) -> tuple[int, str]:
    try:
        proc = subprocess.run(
            cmd,
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=timeout,
        )
        return proc.returncode, proc.stdout
    except subprocess.TimeoutExpired as exc:
        output = exc.stdout or ""
        if isinstance(output, bytes):
            output = output.decode(errors="replace")
        return 124, output + "\n[TIMEOUT]\n"


def tail(text: str, max_lines: int = 18) -> str:
    lines = [line.rstrip() for line in text.splitlines() if line.strip()]
    if not lines:
        return ""
    return "\n".join(lines[-max_lines:])


def write_coq_project() -> None:
    files = sorted(p.name for p in ROOT.glob("*.v"))
    lines = []
    if COQC_FLAGS:
        lines.append(" ".join(COQC_FLAGS))
    lines.extend(files)
    (ROOT / "_CoqProject").write_text("\n".join(lines) + "\n")


def build_makefile() -> tuple[bool, str]:
    if not COQC_FLAGS:
        return build_support_files()
    write_coq_project()
    rc, output = run_cmd(["coq_makefile", "-f", "_CoqProject", "-o", "Makefile.coq"], timeout=120)
    return rc == 0, output


def is_case_file(name: str) -> bool:
    stem = name.removesuffix(".v")
    if stem.startswith("eval_task"):
        return stem[len("eval_task"):].isdigit()
    if stem.startswith("task"):
        return stem[len("task"):].isdigit()
    return False


def support_files() -> list[str]:
    return sorted(p.name for p in ROOT.glob("*.v") if not is_case_file(p.name))


def build_support_files() -> tuple[bool, str]:
    remaining = support_files()
    outputs: list[str] = []
    last_errors: dict[str, str] = {}

    while remaining:
        progressed = False
        for name in remaining[:]:
            rc, output = run_cmd(["coqc", *COQC_FLAGS, name], timeout=CASE_TIMEOUT_SECONDS)
            if rc == 0:
                outputs.append(output)
                remaining.remove(name)
                progressed = True
            else:
                last_errors[name] = output
        if not progressed:
            messages = [
                f"Failed to compile support file {name}:\n{tail(last_errors.get(name, ''))}"
                for name in remaining
            ]
            return False, "\n\n".join(messages)

    return True, "\n".join(outputs)


def build_task(task_file: str) -> tuple[bool, str]:
    if not COQC_FLAGS:
        rc, output = run_cmd(
            ["coqc", *COQC_FLAGS, task_file],
            timeout=CASE_TIMEOUT_SECONDS,
        )
        return rc == 0, output
    rc, output = run_cmd(
        ["make", "-f", "Makefile.coq", "-j2", task_file.replace(".v", ".vo")],
        timeout=CASE_TIMEOUT_SECONDS,
    )
    return rc == 0, output


def check_eval(eval_file: str) -> tuple[bool, str]:
    rc, output = run_cmd(
        ["coqc", *COQC_FLAGS, eval_file],
        timeout=CASE_TIMEOUT_SECONDS,
    )
    if rc != 0:
        return False, output
    return "Closed under the global context" in output, output


def main() -> None:
    clean_artifacts()
    details = []
    score = 0
    max_score = sum(item["weight"] for item in TASKS)

    ok_makefile, makefile_output = build_makefile()
    if not ok_makefile:
        msg = "Failed to generate Coq Makefile.\n" + tail(makefile_output)
        details = [
            {
                "name": item["name"],
                "status": "ERROR",
                "score": 0,
                "weight": item["weight"],
                "message": msg,
            }
            for item in TASKS
        ]
    else:
        for item in TASKS:
            name = item["name"]
            weight = item["weight"]
            task_file = item["task_file"]
            eval_file = item["eval_file"]

            built, build_output = build_task(task_file)
            if not built:
                details.append(
                    {
                        "name": name,
                        "status": "FAILED",
                        "score": 0,
                        "weight": weight,
                        "message": "Task or dependency failed to compile.\n" + tail(build_output),
                    }
                )
                print(f"CASE {name} FAILED score=0", flush=True)
                continue

            closed, eval_output = check_eval(eval_file)
            if closed:
                score += weight
                details.append(
                    {
                        "name": name,
                        "status": "PASSED",
                        "score": weight,
                        "weight": weight,
                        "message": "Closed under the global context.",
                    }
                )
                print(f"CASE {name} PASSED score={weight}", flush=True)
            else:
                details.append(
                    {
                        "name": name,
                        "status": "FAILED",
                        "score": 0,
                        "weight": weight,
                        "message": "Compiled, but assumptions were not closed.\n" + tail(eval_output),
                    }
                )
                print(f"CASE {name} FAILED score=0", flush=True)

    passed = sum(1 for item in details if item["status"] == "PASSED")
    failed = sum(1 for item in details if item["status"] == "FAILED")
    errors = sum(1 for item in details if item["status"] == "ERROR")
    total = len(details)
    summary = f"{passed}/{total} proof targets closed; weighted score {score}/{max_score}."

    report = {
        "valid": True,
        "score": score,
        "pass_rate": passed / total if total else 0.0,
        "passed": passed,
        "failed": failed,
        "errors": errors,
        "total_tests": total,
        "summary": summary,
        "details": details,
        "metrics": {
            "weighted_score": score,
            "max_score": max_score,
            "passed_count": passed,
            "failed_count": failed,
            "error_count": errors,
            "total_count": total,
        },
    }

    print(">>>>> Start Structured Result")
    print(json.dumps(report, ensure_ascii=False, indent=2))
    print(">>>>> End Structured Result")


if __name__ == "__main__":
    main()
