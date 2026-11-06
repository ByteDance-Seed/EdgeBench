#!/usr/bin/env python3
"""SE-Bench evaluator for molecules task (parallel)."""
import subprocess, os, glob, re
from concurrent.futures import ProcessPoolExecutor, as_completed

WORK_DIR = "/home/workspace/molecules"
CASES_DIR = os.path.join(WORK_DIR, "cases")
TESTER = os.path.join(WORK_DIR, "tools", "bin", "tester")
TIME_LIMIT = 30
TESTER_TIMEOUT = 60
SCORE_RE = re.compile(r"^Score\s*[=:]\s*(inf|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)\s*$")


def _short_reason(text):
    for line in text.splitlines():
        line = line.strip()
        if line:
            return line[:200].replace("\t", " ")
    return ""


def run_case(args):
    i, case_file = args
    cid = f"{i:04d}"
    try:
        with open(case_file) as fin:
            proc = subprocess.run(["python3", "solution.py"], stdin=fin,
                                  capture_output=True, text=True, timeout=TIME_LIMIT,
                                  cwd=WORK_DIR)
        if proc.returncode != 0:
            return cid, "RE", 0, _short_reason(proc.stderr or proc.stdout)

        out_file = f"/tmp/molecules_out_{cid}.txt"
        with open(out_file, "w") as fout:
            fout.write(proc.stdout)

        try:
            result = subprocess.run([TESTER, case_file, out_file],
                                    capture_output=True, text=True, timeout=TESTER_TIMEOUT)
        except subprocess.TimeoutExpired:
            return cid, "TLE", 0, "tester timeout"

        combined = result.stdout + result.stderr
        if result.returncode != 0:
            return cid, "WA", 0, _short_reason(combined)

        for line in combined.splitlines():
            match = SCORE_RE.match(line.strip())
            if match:
                return cid, "OK", int(float(match.group(1))), ""
        return cid, "WA", 0, "tester returned success but no strict Score line"
    except subprocess.TimeoutExpired:
        return cid, "TLE", 0, "solution timeout"
    except Exception as exc:
        return cid, "RE", 0, type(exc).__name__


if __name__ == "__main__":
    os.chdir(WORK_DIR)
    case_files = sorted(f for f in glob.glob(os.path.join(CASES_DIR, "*")) if os.path.isfile(f))
    results = {}
    max_workers = min(int(os.environ.get("SEBENCH_MOLECULES_WORKERS", "8")), len(case_files))
    with ProcessPoolExecutor(max_workers=max_workers) as pool:
        futures = {pool.submit(run_case, (i, cf)): i for i, cf in enumerate(case_files)}
        for fut in as_completed(futures):
            cid, status, score, reason = fut.result()
            results[cid] = (status, score, reason)
    total_score = 0
    ok_count = 0
    for cid in sorted(results):
        status, score, reason = results[cid]
        if status == "OK":
            total_score += score
            ok_count += 1
        suffix = f" reason={reason}" if reason else ""
        print(f"CASE {cid} {status} score={score}{suffix}", flush=True)
    print(f"TOTAL_SCORE {total_score}", flush=True)
    print(f"CASES_OK {ok_count}", flush=True)
    print(f"CASES_TOTAL {len(case_files)}", flush=True)
