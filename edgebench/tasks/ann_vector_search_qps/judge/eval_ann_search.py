#!/usr/bin/env python3
"""SE-Bench evaluator for ann_benchmarks task (anti-hack hardened).

Runs the agent-provided 'custom' algorithm on sift-128-euclidean, reads
per-config hdf5 outputs, enforces Recall@10 >= 0.95, reports QPS.

Anti-hack measures:
  1. Ground truth isolation: neighbors removed from data file during run
  2. Timing integrity: QPS computed from raw 'times' dataset, not attrs
  3. QPS sanity limit: caps QPS at a physically reasonable maximum
  4. Static code scan: detects oracle/timer/pattern hacks before run

Output format (parsed by score_sum + extract_score):
  CASE <cfg_id> OK|WA|TLE|RE score=<int QPS>
  TOTAL_SCORE <best_qps_among_valid_cases>
  CASES_OK <n>
  CASES_TOTAL <n>
"""
import glob
import os
import re
import shutil
import subprocess
import sys

WORK_DIR = "/home/workspace/ann-benchmarks"
RESULTS_DIR = os.path.join(WORK_DIR, "results", "sift-128-euclidean", "10", "custom")
ALGO = "custom"
DATASET = "sift-128-euclidean"
K = 10
RECALL_THRESHOLD = 0.95
RUN_TIMEOUT = 7200
QPS_SANITY_LIMIT = 500000
GT_BACKUP = "/tmp/_sebench_gt_neighbors.npy"
DATA_PATH = os.path.join(WORK_DIR, "data", f"{DATASET}.hdf5")
CUSTOM_MODULE = os.path.join(WORK_DIR, "ann_benchmarks", "algorithms", "custom", "module.py")

HACK_PATTERNS = [
    (r'h5py\.File\s*\(\s*["\'].*sift.*\.hdf5', "oracle: reading ground truth data file in algorithm code"),
    (r'memmap\s*\(\s*["\'].*sift', "oracle: memmap of ground truth data file"),
    (r'best_search_time', "timer: referencing 'best_search_time' in algorithm code"),
    (r'time\.time\s*=\s', "timer: monkey-patching time.time()"),
    (r'\.time\s*=\s*(?:lambda|function)', "timer: replacing time function"),
    (r'__import__\s*\(\s*["\']time', "obfuscation: dynamic import of time module"),
]


def scan_for_hacks(module_path):
    """Static code scan for hack patterns in agent-submitted module.py."""
    if not os.path.isfile(module_path):
        return []
    with open(module_path, "r") as f:
        code = f.read()
    violations = []
    for pattern, desc in HACK_PATTERNS:
        if re.search(pattern, code):
            violations.append(desc)
    return violations


def isolate_ground_truth():
    """Remove 'neighbors' from data HDF5 so algorithm cannot oracle-cheat.
    
    ann-benchmarks runner.py only reads 'train' and 'test' datasets,
    never 'neighbors'. So removing it does not affect normal benchmark runs.
    """
    import h5py
    import numpy as np
    if not os.path.isfile(DATA_PATH):
        return False
    try:
        with h5py.File(DATA_PATH, "a") as f:
            if "neighbors" not in f:
                return True
            neighbors = np.array(f["neighbors"])
            np.save(GT_BACKUP, neighbors)
            del f["neighbors"]
        return True
    except Exception as e:
        print(f"WARNING: isolate_ground_truth failed: {e}", flush=True)
        return False


def restore_ground_truth():
    """Restore 'neighbors' to data HDF5 for recall computation."""
    import h5py
    import numpy as np
    if not os.path.isfile(GT_BACKUP):
        return False
    try:
        neighbors = np.load(GT_BACKUP)
        with h5py.File(DATA_PATH, "a") as f:
            if "neighbors" not in f:
                f.create_dataset("neighbors", data=neighbors)
        os.remove(GT_BACKUP)
        return True
    except Exception as e:
        print(f"WARNING: restore_ground_truth failed: {e}", flush=True)
        return False


def run_algorithm():
    os.chdir(WORK_DIR)
    env = {**os.environ, "PYTHONPATH": WORK_DIR}
    subprocess.run(["rm", "-rf", RESULTS_DIR], check=False)
    cmd = [
        sys.executable, "run.py",
        "--local",
        "--algorithm", ALGO,
        "--dataset", DATASET,
        "-k", str(K),
        "--runs", "1",
        "--run-disabled",
    ]
    try:
        proc = subprocess.run(cmd, env=env, capture_output=True,
                              text=True, timeout=RUN_TIMEOUT, cwd=WORK_DIR)
        return proc.returncode, proc.stdout + proc.stderr
    except subprocess.TimeoutExpired:
        return -1, "RUN_TIMEOUT"


def score_hdf5(path):
    """Read hdf5 results, compute recall@10 and QPS with integrity checks."""
    import h5py
    import numpy as np
    try:
        with h5py.File(path, "r") as f:
            # --- Timing integrity: compute QPS from raw 'times' dataset ---
            times_ds = f.get("times")
            if times_ds is not None and len(times_ds) > 0:
                times_array = np.array(times_ds)
                computed_search_time = float(np.sum(times_array) / len(times_array))
            else:
                computed_search_time = 0.0

            # Cross-validate: check if attrs.best_search_time was manipulated
            attrs_best_time = float(f.attrs.get("best_search_time", 0))
            if computed_search_time > 0 and attrs_best_time > 0:
                ratio = attrs_best_time / computed_search_time
                if ratio < 0.5:
                    return 0.0, 0, f"HACK: best_search_time manipulated (attrs/computed ratio={ratio:.3f})"

            # Use computed_search_time (trustworthy source)
            qps = int(1.0 / computed_search_time) if computed_search_time > 0 else 0

            # --- QPS sanity limit ---
            if qps > QPS_SANITY_LIMIT:
                return 0.0, 0, f"HACK: QPS {qps} exceeds sanity limit {QPS_SANITY_LIMIT}"

            # --- Recall computation ---
            ds_path = os.path.join(WORK_DIR, "data", f"{DATASET}.hdf5")
            with h5py.File(ds_path, "r") as d:
                if "neighbors" not in d:
                    return 0.0, 0, "ERROR: ground truth 'neighbors' not available for recall computation"
                true_nbrs = np.array(d["neighbors"])[:, :K]
            pred_nbrs = np.array(f["neighbors"])
            n = min(len(true_nbrs), len(pred_nbrs))
            recall_sum = 0.0
            for i in range(n):
                recall_sum += len(set(true_nbrs[i].tolist()) &
                                   set(pred_nbrs[i][:K].tolist()))
            recall = recall_sum / (n * K) if n else 0.0

        return recall, qps, computed_search_time
    except Exception as exc:
        return 0.0, 0, str(exc)


def main():
    # --- Step 0: Static code scan ---
    violations = scan_for_hacks(CUSTOM_MODULE)
    if violations:
        print("HACK_DETECTED ann_search static_check " + "; ".join(violations), flush=True)
        print("CASE 0000 RE score=0", flush=True)
        print("TOTAL_SCORE 0", flush=True)
        print("CASES_OK 0", flush=True)
        print("CASES_TOTAL 1", flush=True)
        return

    # --- Step 1: Isolate ground truth ---
    isolated = isolate_ground_truth()

    try:
        # --- Step 2: Run algorithm ---
        rc, out = run_algorithm()

        if rc != 0:
            print("RUN LOG (tail):", flush=True)
            for line in out.splitlines()[-50:]:
                print(line, flush=True)
            print("CASE 0000 RE score=0", flush=True)
            print("TOTAL_SCORE 0", flush=True)
            print("CASES_OK 0", flush=True)
            print("CASES_TOTAL 1", flush=True)
            return

        # --- Step 3: Restore ground truth for recall computation ---
        if isolated:
            restore_ground_truth()

        # --- Step 4: Score results ---
        hdf5_files = sorted(glob.glob(os.path.join(RESULTS_DIR, "*.hdf5")))
        if not hdf5_files:
            print("No result files produced", flush=True)
            print("CASE 0000 WA score=0", flush=True)
            print("TOTAL_SCORE 0", flush=True)
            print("CASES_OK 0", flush=True)
            print("CASES_TOTAL 1", flush=True)
            return

        best_qps = 0
        ok_count = 0
        for i, hf in enumerate(hdf5_files):
            cid = f"{i:04d}"
            recall, qps, detail = score_hdf5(hf)
            cfg = os.path.basename(hf)
            if "HACK:" in str(detail):
                print(f"CASE {cid} RE score=0  # {cfg} {detail}", flush=True)
            elif recall >= RECALL_THRESHOLD and qps > 0:
                ok_count += 1
                if qps > best_qps:
                    best_qps = qps
                print(f"CASE {cid} OK score={qps}  # {cfg} recall={recall:.4f}",
                      flush=True)
            else:
                print(f"CASE {cid} WA score=0  # {cfg} recall={recall:.4f} qps={qps}",
                      flush=True)

        print(f"TOTAL_SCORE {best_qps}", flush=True)
        print(f"CASES_OK {ok_count}", flush=True)
        print(f"CASES_TOTAL {len(hdf5_files)}", flush=True)

    finally:
        # Ensure ground truth is always restored, even on error
        if isolated and os.path.isfile(GT_BACKUP):
            restore_ground_truth()


if __name__ == "__main__":
    main()

