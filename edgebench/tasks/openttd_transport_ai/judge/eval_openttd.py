#!/usr/bin/env python3
"""SE-Bench wrapper for OpenTTD AI eval — delegates to the author's eval_script.py,
parses the '*** 最终得分（平均公司市值）: N ***' line, reports score_sum format."""
import os
import re
import subprocess
import sys

WORK_DIR = "/home/workspace/openttd_ai"
EVAL_SCRIPT = "/judge/openttd_original_eval.py"
AI_FOLDER = os.path.join(WORK_DIR, "my_ai")
SEEDS = int(os.environ.get("OPENTTD_N_SEEDS", "3"))
TIMEOUT = 3600


def main():
    if not os.path.isfile(os.path.join(AI_FOLDER, "info.nut")) or \
       not os.path.isfile(os.path.join(AI_FOLDER, "main.nut")):
        print("Missing info.nut or main.nut in my_ai/", flush=True)
        print("CASE 0000 RE score=0", flush=True)
        print("TOTAL_SCORE 0", flush=True)
        print("CASES_OK 0", flush=True)
        print("CASES_TOTAL 1", flush=True)
        return

    cmd = [sys.executable, EVAL_SCRIPT, AI_FOLDER, "--seeds", str(SEEDS)]
    try:
        proc = subprocess.run(
            cmd, capture_output=True, text=True, timeout=TIMEOUT, cwd=WORK_DIR
        )
        out = proc.stdout + "\n" + proc.stderr
    except subprocess.TimeoutExpired:
        print("CASE 0000 TLE score=0", flush=True)
        print("TOTAL_SCORE 0", flush=True)
        print("CASES_OK 0", flush=True)
        print("CASES_TOTAL 1", flush=True)
        return

    # Print eval output for debugging (agent sees it)
    print(out, flush=True)

    # Look for "最终得分（平均公司市值）: 98,819"
    m = re.search(r"最终得分.*?:\s*([\d,]+)", out)
    if not m:
        m = re.search(r"Final\s+score[:\s]+([\d,]+)", out)
    if not m:
        # Fallback: look for the average line
        m = re.search(r"平均公司市值[:\s]+([\d,]+)", out)

    if m:
        score = int(m.group(1).replace(",", ""))
        status = "OK" if score > 0 else "WA"
        print(f"CASE 0000 {status} score={score}", flush=True)
        print(f"TOTAL_SCORE {score}", flush=True)
        print(f"CASES_OK {1 if status == 'OK' else 0}", flush=True)
    else:
        print("CASE 0000 RE score=0", flush=True)
        print("TOTAL_SCORE 0", flush=True)
        print("CASES_OK 0", flush=True)
    print("CASES_TOTAL 1", flush=True)


if __name__ == "__main__":
    main()
