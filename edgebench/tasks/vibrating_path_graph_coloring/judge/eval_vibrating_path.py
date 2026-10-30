#!/usr/bin/env python3
"""SE-Bench evaluator for vibrating_path task (parallel)."""
import subprocess, os, glob
from concurrent.futures import ProcessPoolExecutor, as_completed

WORK_DIR = "/home/workspace/vibrating_path"
CASES_DIR = os.path.join(WORK_DIR, "cases")
TESTER = os.path.join(WORK_DIR, "tools", "bin", "tester")
TIME_LIMIT = 30

def run_case(args):
    i, case_file = args
    cid = f"{i:04d}"
    try:
        with open(case_file) as fin:
            proc = subprocess.run(["python3", "solution.py"], stdin=fin,
                                  capture_output=True, text=True, timeout=TIME_LIMIT,
                                  cwd=WORK_DIR)
        if proc.returncode != 0:
            return cid, "RE", float('inf')
        out_file = f"/tmp/vibrating_path_out_{cid}.txt"
        with open(out_file, "w") as fout:
            fout.write(proc.stdout)
        result = subprocess.run([TESTER, case_file, out_file],
                                capture_output=True, text=True, timeout=60)
        for line in (result.stdout + result.stderr).splitlines():
            if "Score" in line and ("=" in line or ":" in line):
                try:
                    # Handle both "Score = 12345" and "Score: 12345.00"
                    sep = "=" if "=" in line else ":"
                    val = line.split(sep)[-1].strip().split()[0]
                    return cid, "OK", int(float(val))
                except (ValueError, IndexError):
                    pass
        return cid, "WA", float('inf')
    except subprocess.TimeoutExpired:
        return cid, "TLE", float('inf')
    except Exception:
        return cid, "RE", float('inf')

if __name__ == "__main__":
    os.chdir(WORK_DIR)
    case_files = sorted(f for f in glob.glob(os.path.join(CASES_DIR, "*")) if os.path.isfile(f))
    results = {}
    with ProcessPoolExecutor(max_workers=min(8, len(case_files))) as pool:
        futures = {pool.submit(run_case, (i, cf)): i for i, cf in enumerate(case_files)}
        for fut in as_completed(futures):
            cid, status, score = fut.result()
            results[cid] = (status, score)
    total_score = 0
    ok_count = 0
    for cid in sorted(results):
        status, score = results[cid]
        total_score += score
        if status == "OK":
            ok_count += 1
        print(f"CASE {cid} {status} score={score}", flush=True)
    print(f"TOTAL_SCORE {total_score}", flush=True)
    print(f"CASES_OK {ok_count}", flush=True)
    print(f"CASES_TOTAL {len(case_files)}", flush=True)
