#!/usr/bin/env python3
import argparse
import dataclasses
import math
import os
import re
import signal
import subprocess
import sys
import tempfile
import time
from pathlib import Path


WEIGHTS = [5, 5, 10, 15, 25, 40]
CPPFLAGS = ["g++", "-std=c++17", "-Ofast", "-pipe"]


@dataclasses.dataclass
class Limits:
    time_s: float
    memory_mb: int


@dataclasses.dataclass
class RunOutcome:
    status: str
    time_s: float
    peak_mb: float
    returncode: int
    message: str = ""


@dataclasses.dataclass
class CaseResult:
    name: str
    status: str
    time_s: float = 0.0
    peak_mb: float = 0.0
    message: str = ""


@dataclasses.dataclass
class TaskResult:
    task_name: str
    passed: int
    total: int
    score: float
    weight: int
    limits: Limits
    compile_status: str
    cases: list
    message: str = ""


def task_score_fraction(passed: int, total: int) -> float:
    if total <= 0:
        return 0.0
    if passed == total:
        return 1.0
    return 0.5 * passed / total


def natural_key(path):
    parts = re.split(r"(\d+)", Path(path).stem)
    return [int(p) if p.isdigit() else p for p in parts]


def parse_limits(statement_path: Path) -> Limits:
    text = statement_path.read_text(encoding="utf-8", errors="ignore")
    time_match = re.search(r"时间限制：\s*([0-9]+(?:\.[0-9]+)?)\s*s", text, re.I)
    mem_match = re.search(r"空间限制：\s*([0-9]+)\s*MB", text, re.I)
    if not time_match:
        raise ValueError(f"cannot parse time limit from {statement_path}")
    if not mem_match:
        raise ValueError(f"cannot parse memory limit from {statement_path}")
    return Limits(time_s=float(time_match.group(1)), memory_mb=int(mem_match.group(1)))


def discover_tasks(suite_dir: Path):
    def task_index(p: Path):
        m = re.match(r"T([1-6])_", p.name)
        return int(m.group(1)) if m else 99

    tasks = [p for p in suite_dir.iterdir() if p.is_dir() and re.match(r"T[1-6]_", p.name)]
    return sorted(tasks, key=task_index)


def select_tasks(all_tasks, selectors):
    if not selectors:
        return all_tasks
    selected = []
    by_name = {p.name: p for p in all_tasks}
    by_short = {p.name.split("_", 1)[0]: p for p in all_tasks}
    for raw in selectors:
        task = by_name.get(raw) or by_short.get(raw)
        if task is None:
            raise SystemExit(f"unknown task selector: {raw}")
        if task not in selected:
            selected.append(task)
    return selected


def resolve_source(task_dir: Path, args):
    if args.source:
        if len(args.task) != 1:
            raise SystemExit("--source can only be used together with exactly one --task")
        source = Path(args.source).resolve()
        if not source.exists():
            raise SystemExit(f"source file does not exist: {source}")
        return source

    if args.source_root:
        root = Path(args.source_root).resolve()
        short = task_dir.name.split("_", 1)[0]
        candidates = [
            root / task_dir.name / "std.cpp",
            root / task_dir.name / "main.cpp",
            root / task_dir.name / f"{task_dir.name}.cpp",
            root / short / "std.cpp",
            root / short / "main.cpp",
            root / f"{task_dir.name}.cpp",
            root / f"{short}.cpp",
        ]
        for candidate in candidates:
            if candidate.exists():
                return candidate
        raise SystemExit(f"cannot find source for {task_dir.name} under {root}")

    return task_dir / "std.cpp"


def expected_for(input_file: Path):
    out = input_file.with_suffix(".out")
    ans_file = input_file.with_suffix(".ans")
    if out.exists():
        return out
    if ans_file.exists():
        return ans_file
    raise FileNotFoundError(f"missing answer for {input_file}")


def compile_cpp(cmd, timeout=60):
    proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=timeout)
    if proc.returncode == 0:
        return True, ""
    detail = (proc.stderr or proc.stdout or "").strip()
    return False, detail[-4000:]


def write_header_overlay_if_needed(task_dir: Path, task_work: Path):
    if task_dir.name == "T3_TB5":
        header_name = "hpmq.h"
    elif task_dir.name == "T4_P7723":
        header_name = "data.h"
    else:
        return

    header = (task_dir / "data" / header_name).read_text(encoding="utf-8", errors="ignore")
    header = header.replace("unsigned int x[2];", "unsigned int x, sz, T, flag;")
    header = header.replace("unsigned int a[2][2];", "unsigned int a, b, L, R, flag;")
    (task_work / header_name).write_text(header, encoding="utf-8")


def compile_solution(task_dir: Path, source: Path, exe: Path, task_work: Path):
    data_dir = task_dir / "data"
    interactive = data_dir / "interactive_lib.cpp"
    cmd = CPPFLAGS + ["-I", str(task_work), "-I", str(data_dir), str(source)]
    if interactive.exists():
        write_header_overlay_if_needed(task_dir, task_work)
        interactive_copy = task_work / interactive.name
        interactive_copy.write_text(interactive.read_text(encoding="utf-8", errors="ignore"),
                                    encoding="utf-8")
        cmd.append(str(interactive_copy))
    cmd += ["-o", str(exe)]
    return compile_cpp(cmd)


def compile_checker(task_dir: Path, include_dir: Path, exe: Path):
    checker = task_dir / "data" / "checker.cpp"
    if not checker.exists():
        return None, ""
    cmd = CPPFLAGS + ["-I", str(include_dir), "-I", str(task_dir / "data"), str(checker), "-o", str(exe)]
    ok, msg = compile_cpp(cmd)
    return ok, msg


def checker_mode(task_dir: Path):
    checker = task_dir / "data" / "checker.cpp"
    if not checker.exists():
        return None
    text = checker.read_text(encoding="utf-8", errors="ignore")
    return "interaction" if "registerInteraction" in text else "checker"


def process_rss_mb(pid: int):
    status = Path("/proc") / str(pid) / "status"
    try:
        for line in status.read_text(errors="ignore").splitlines():
            if line.startswith("VmRSS:"):
                parts = line.split()
                if len(parts) >= 2:
                    return int(parts[1]) / 1024.0
    except FileNotFoundError:
        return 0.0
    except ProcessLookupError:
        return 0.0
    return 0.0


def kill_process_group(proc):
    try:
        os.killpg(proc.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass
    except PermissionError:
        proc.kill()


def make_preexec(stack_limit_mb):
    def preexec():
        os.setsid()
        if stack_limit_mb is None:
            return
        try:
            import resource
            target = int(stack_limit_mb * 1024 * 1024)
            _soft, hard = resource.getrlimit(resource.RLIMIT_STACK)
            if hard == resource.RLIM_INFINITY or target <= hard:
                resource.setrlimit(resource.RLIMIT_STACK, (target, hard))
            else:
                resource.setrlimit(resource.RLIMIT_STACK, (hard, hard))
        except Exception:
            pass
    return preexec


def run_limited(cmd, stdin_path=None, stdout_path=None, stderr_path=None,
                time_limit=None, memory_limit_mb=None, poll_interval=0.01):
    start = time.monotonic()
    peak_mb = 0.0
    stdin = open(stdin_path, "rb") if stdin_path else subprocess.DEVNULL
    stdout = open(stdout_path, "wb") if stdout_path else subprocess.DEVNULL
    stderr = open(stderr_path, "wb") if stderr_path else subprocess.PIPE
    try:
        proc = subprocess.Popen(
            cmd,
            stdin=stdin,
            stdout=stdout,
            stderr=stderr,
            preexec_fn=make_preexec(memory_limit_mb),
        )
        while True:
            ret = proc.poll()
            peak_mb = max(peak_mb, process_rss_mb(proc.pid))
            elapsed = time.monotonic() - start
            if memory_limit_mb is not None and peak_mb > memory_limit_mb:
                kill_process_group(proc)
                proc.wait()
                return RunOutcome("MLE", elapsed, peak_mb, proc.returncode or -9,
                                  f"peak RSS {peak_mb:.1f} MB > {memory_limit_mb} MB")
            if time_limit is not None and elapsed > time_limit:
                kill_process_group(proc)
                proc.wait()
                return RunOutcome("TLE", elapsed, peak_mb, proc.returncode or -9,
                                  f"time {elapsed:.3f}s > {time_limit:.3f}s")
            if ret is not None:
                message = ""
                if stderr_path is None and proc.stderr is not None:
                    message = proc.stderr.read().decode(errors="replace")[-1000:]
                return RunOutcome("OK" if ret == 0 else "RE", elapsed, peak_mb, ret, message.strip())
            time.sleep(poll_interval)
    finally:
        if hasattr(stdin, "close"):
            stdin.close()
        if hasattr(stdout, "close"):
            stdout.close()
        if hasattr(stderr, "close"):
            stderr.close()


def tokens(path: Path):
    with path.open("rb") as f:
        for raw in f.read().split():
            yield raw


def compare_tokens(output: Path, expected: Path):
    out_tokens = list(tokens(output))
    exp_tokens = list(tokens(expected))
    if out_tokens == exp_tokens:
        return True, ""
    limit = min(len(out_tokens), len(exp_tokens))
    for i in range(limit):
        if out_tokens[i] != exp_tokens[i]:
            return False, f"token {i + 1}: expected {exp_tokens[i][:80]!r}, got {out_tokens[i][:80]!r}"
    if len(out_tokens) < len(exp_tokens):
        return False, f"output ended early: expected {len(exp_tokens)} tokens, got {len(out_tokens)}"
    return False, f"extra output: expected {len(exp_tokens)} tokens, got {len(out_tokens)}"


def checker_message(stderr_path: Path):
    if not stderr_path.exists():
        return ""
    data = stderr_path.read_text(errors="replace").strip()
    return data[-1000:]


def run_case(exe: Path, checker_exe: Path, mode: str, input_file: Path, expected: Path,
             limits: Limits, work_dir: Path, args):
    output = work_dir / f"{input_file.stem}.out"
    run_stderr = work_dir / f"{input_file.stem}.run.err"
    effective_time = limits.time_s * args.time_factor + args.time_grace
    effective_memory = limits.memory_mb + args.memory_grace
    run = run_limited(
        [str(exe)],
        stdin_path=input_file,
        stdout_path=output,
        stderr_path=run_stderr,
        time_limit=effective_time,
        memory_limit_mb=effective_memory,
    )
    if run.status != "OK":
        msg = run.message or checker_message(run_stderr)
        return CaseResult(input_file.name, run.status, run.time_s, run.peak_mb, msg)

    if checker_exe:
        check_stderr = work_dir / f"{input_file.stem}.check.err"
        check_stdout = work_dir / f"{input_file.stem}.check.out"
        checker_output_arg = output
        checker_stdin = None
        if mode == "interaction":
            checker_output_arg = work_dir / f"{input_file.stem}.tout"
            checker_stdin = output
        check = run_limited(
            [str(checker_exe), str(input_file), str(checker_output_arg), str(expected)],
            stdin_path=checker_stdin,
            stdout_path=check_stdout,
            stderr_path=check_stderr,
            time_limit=args.checker_timeout,
            memory_limit_mb=max(1024, limits.memory_mb + 256),
            poll_interval=0.02,
        )
        if check.status == "OK":
            return CaseResult(input_file.name, "AC", run.time_s, run.peak_mb)
        msg = checker_message(check_stderr) or check.message
        status = "WA" if check.status in ("RE", "OK") else check.status
        return CaseResult(input_file.name, status, run.time_s, run.peak_mb, msg)

    ok, msg = compare_tokens(output, expected)
    return CaseResult(input_file.name, "AC" if ok else "WA", run.time_s, run.peak_mb, msg)


def run_task(task_dir: Path, task_index: int, args, suite_work: Path, include_dir: Path):
    limits = parse_limits(task_dir / "题面.md")
    source = resolve_source(task_dir, args)
    data_dir = task_dir / "data"
    input_files = sorted(data_dir.glob("*.in"), key=natural_key)
    if args.case:
        wanted = set(args.case)
        input_files = [
            p for p in input_files
            if p.name in wanted or p.stem in wanted or f"{p.stem}.in" in wanted
        ]
    if not input_files:
        raise SystemExit(f"no .in files under {data_dir}")

    task_work = suite_work / task_dir.name
    task_work.mkdir(parents=True, exist_ok=True)
    exe = task_work / "main"
    ok, msg = compile_solution(task_dir, source, exe, task_work)
    weight = WEIGHTS[task_index - 1]
    if not ok:
        cases = [CaseResult(p.name, "CE", message="compile failed") for p in input_files]
        return TaskResult(task_dir.name, 0, len(cases), 0.0, weight, limits, "CE", cases, msg)

    checker_exe = None
    checker_ok, checker_msg = compile_checker(task_dir, include_dir, task_work / "checker")
    if checker_ok is False:
        cases = [CaseResult(p.name, "CE", message="checker compile failed") for p in input_files]
        return TaskResult(task_dir.name, 0, len(cases), 0.0, weight, limits, "CE", cases, checker_msg)
    if checker_ok is True:
        checker_exe = task_work / "checker"
    mode = checker_mode(task_dir)

    cases = []
    for input_file in input_files:
        expected = expected_for(input_file)
        case = run_case(exe, checker_exe, mode, input_file, expected, limits, task_work, args)
        cases.append(case)
        if args.verbose or case.status != "AC":
            print_case(task_dir.name, case)
            sys.stdout.flush()
    passed = sum(1 for c in cases if c.status == "AC")
    score = task_score_fraction(passed, len(cases))
    return TaskResult(task_dir.name, passed, len(cases), score, weight, limits, "OK", cases)


def print_case(task_name: str, case: CaseResult):
    extra = f" {case.time_s:.3f}s {case.peak_mb:.1f}MB"
    if case.message:
        extra += f" {case.message.splitlines()[-1][:160]}"
    print(f"  {task_name}/{case.name}: {case.status}{extra}")


def print_summary(results):
    total_score = sum(r.score * r.weight for r in results)
    print()
    print("Summary")
    for r in results:
        max_case = max(r.cases, key=lambda c: c.time_s) if r.cases else None
        peak_case = max(r.cases, key=lambda c: c.peak_mb) if r.cases else None
        max_time = max_case.time_s if max_case else 0.0
        peak_mem = peak_case.peak_mb if peak_case else 0.0
        time_ratio = max_time / r.limits.time_s if r.limits.time_s else 0.0
        mem_ratio = peak_mem / r.limits.memory_mb if r.limits.memory_mb else 0.0
        print(
            f"{r.task_name}: {r.passed}/{r.total} score={r.score:.6f} weight={r.weight} "
            f"max_time={max_time:.3f}s/{r.limits.time_s:g}s ({time_ratio:.2f}x"
            f"{',' + max_case.name if max_case else ''}) "
            f"peak_mem={peak_mem:.1f}MB/{r.limits.memory_mb}MB ({mem_ratio:.2f}x)"
        )
        if r.compile_status == "CE" and r.message:
            print(r.message.splitlines()[-1][:200])
    print(f"Total: {total_score:.6f} / 100.000000")


def score_sum_status(status: str) -> str:
    if status == "AC":
        return "OK"
    if status in {"TLE", "RE", "WA", "CE"}:
        return status
    if status == "MLE":
        return "RE"
    return "WA"


def score_sum_scale(results):
    scale = 1
    for result in results:
        if not result.total:
            continue
        denominator = result.total // math.gcd(result.weight, result.total)
        scale = scale * denominator // math.gcd(scale, denominator)
    return scale


def print_score_sum(results):
    scale = score_sum_scale(results)
    total_score = sum(r.score * r.weight for r in results)
    ok_units = 0
    total_units = 0
    for result in results:
        if not result.total:
            continue
        units_per_case = result.weight * scale // result.total
        full_task = result.passed == result.total
        for case in result.cases:
            status = score_sum_status(case.status)
            for unit in range(1, units_per_case + 1):
                name = f"{result.task_name}_{case.name}_{unit:03d}"
                score = 1 if status == "OK" and full_task else 0.5 if status == "OK" else 0
                print(f"CASE {name} {status} score={score}")
                total_units += 1
                if status == "OK":
                    ok_units += 1
    print(f"TOTAL_SCORE {total_score:.6f}")
    print(f"CASES_OK {ok_units}")
    print(f"CASES_TOTAL {total_units}")


def build_arg_parser(suite_dir: Path):
    parser = argparse.ArgumentParser(
        description=f"Evaluate submissions for {suite_dir.name}. Defaults to every task's std.cpp."
    )
    parser.add_argument("--task", action="append", default=[],
                        help="task to run, e.g. T1 or T1_P5611; can be repeated")
    parser.add_argument("--source", help="single source file; requires exactly one --task")
    parser.add_argument("--source-root",
                        help="directory containing T1.cpp/T2.cpp or per-task subdirectories")
    parser.add_argument("--time-factor", type=float, default=4.0,
                        help="multiply statement time limit by this factor")
    parser.add_argument("--time-grace", type=float, default=0.75,
                        help="extra wall-clock seconds added to each time limit")
    parser.add_argument("--memory-grace", type=int, default=16,
                        help="extra MB allowed above the statement memory limit")
    parser.add_argument("--checker-timeout", type=float, default=30.0,
                        help="wall-clock timeout for checker/SPJ")
    parser.add_argument("--case", action="append", default=[],
                        help="run only this input file/stem, e.g. data6.in or 6; can be repeated")
    parser.add_argument("--build-dir",
                        help="keep build and output files in this directory instead of a temporary directory")
    parser.add_argument("--score-sum", action="store_true",
                        help="print CASE/TOTAL_SCORE lines for the SE-Bench score_sum parser")
    parser.add_argument("-v", "--verbose", action="store_true",
                        help="print every test case, not only failing cases")
    return parser


def main(suite_dir: Path):
    suite_dir = suite_dir.resolve()
    parser = build_arg_parser(suite_dir)
    args = parser.parse_args()
    all_tasks = discover_tasks(suite_dir)
    tasks = select_tasks(all_tasks, args.task)
    if len(all_tasks) != 6:
        raise SystemExit(f"expected 6 tasks under {suite_dir}, found {len(all_tasks)}")

    def run_in(work_root: Path):
        testlib_header = suite_dir.parent / "testlib.h"
        if not testlib_header.exists():
            raise SystemExit(f"missing {testlib_header}; download testlib.h before running checkers")
        include_dir = testlib_header.parent
        results = []
        for task_dir in tasks:
            m = re.match(r"T([1-6])_", task_dir.name)
            task_index = int(m.group(1))
            print(f"Running {task_dir.name} ...")
            sys.stdout.flush()
            result = run_task(task_dir, task_index, args, work_root, include_dir)
            results.append(result)
            print(f"{task_dir.name}: {result.passed}/{result.total} ({result.score:.6f})")
            sys.stdout.flush()
        if args.score_sum:
            print_score_sum(results)
        else:
            print_summary(results)
        return 0 if all(r.passed == r.total for r in results) else 1

    if args.build_dir:
        work_root = Path(args.build_dir).resolve()
        work_root.mkdir(parents=True, exist_ok=True)
        return run_in(work_root)
    with tempfile.TemporaryDirectory(prefix=f"{suite_dir.name}_eval_") as tmp:
        return run_in(Path(tmp))


if __name__ == "__main__":
    raise SystemExit(main(Path.cwd()))
