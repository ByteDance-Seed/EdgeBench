#!/usr/bin/env python3
"""Scoring policy for port-git-to-zig task.

Reads evidence.json (written by test.sh) and TAP output from git's test suite.
Makes all scoring decisions — test.sh only collects data.
"""

import json
import os
import re
import sys
from collections import defaultdict
from pathlib import Path


ORACLE_TOTAL_ATTEMPTED = 29075

CATEGORIES = {
    "t0xxx": {"label": "basics-and-infrastructure", "oracle_attempted": 5379},
    "t1xxx": {"label": "tree-operations",           "oracle_attempted": 3191},
    "t2xxx": {"label": "checkout-worktree",          "oracle_attempted": 980},
    "t3xxx": {"label": "index-ls-files",             "oracle_attempted": 4778},
    "t4xxx": {"label": "diff",                       "oracle_attempted": 3485},
    "t5xxx": {"label": "fetch-push-transport",       "oracle_attempted": 4540},
    "t6xxx": {"label": "merge-rebase-revision",      "oracle_attempted": 2355},
    "t7xxx": {"label": "porcelain",                  "oracle_attempted": 2912},
    "t8xxx": {"label": "patchwork-sendemail",        "oracle_attempted": 493},
    "t9xxx": {"label": "svn-p4-gui-misc",            "oracle_attempted": 962},
}


def write_reward(outdir: str, reward: float, detail: dict) -> None:
    detail["score"] = reward
    detail["reward"] = reward
    os.makedirs(outdir, exist_ok=True)
    with open(os.path.join(outdir, "reward.json"), "w") as f:
        json.dump(detail, f, indent=2)
    with open(os.path.join(outdir, "reward.txt"), "w") as f:
        f.write(f"{reward}\n")
    print(f"Reward: {reward}")


def parse_tap_results(results_dir: str) -> dict:
    total_passed = 0
    total_failed = 0
    total_skipped = 0
    category_stats = defaultdict(lambda: {"passed": 0, "failed": 0, "skipped": 0})

    results_dir = Path(results_dir)
    if not results_dir.exists():
        return {
            "total_passed": 0,
            "total_failed": 0,
            "total_skipped": 0,
            "categories": {},
            "scripts_run": 0,
        }

    scripts_run = 0
    for result_file in sorted(results_dir.glob("t*.out")):
        scripts_run += 1
        script_name = result_file.stem
        match = re.match(r"t(\d)", script_name)
        category = f"t{match.group(1)}xxx" if match else "other"

        try:
            content = result_file.read_text(errors="replace")
        except Exception:
            continue

        for line in content.splitlines():
            line = line.strip()
            if line.startswith("ok "):
                if "# skip" in line.lower():
                    total_skipped += 1
                    category_stats[category]["skipped"] += 1
                else:
                    total_passed += 1
                    category_stats[category]["passed"] += 1
            elif line.startswith("not ok "):
                if "# todo" in line.lower():
                    total_skipped += 1
                    category_stats[category]["skipped"] += 1
                else:
                    total_failed += 1
                    category_stats[category]["failed"] += 1

    return {
        "total_passed": total_passed,
        "total_failed": total_failed,
        "total_skipped": total_skipped,
        "categories": dict(category_stats),
        "scripts_run": scripts_run,
    }


def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", required=True)
    parser.add_argument("--evidence", required=True, help="Path to evidence.json from test.sh")
    args = parser.parse_args()

    outdir = args.output_dir

    try:
        with open(args.evidence) as f:
            evidence = json.load(f)
    except Exception as e:
        write_reward(outdir, 0.0, {
            "subscores": [],
            "reason": f"evidence_read_error: {e}",
        })
        return

    # ── Anti-cheat decision ─────────────────────────────────────────
    ac = evidence.get("anti_cheat", {})
    if ac.get("result") == "fail":
        write_reward(outdir, 0.0, {
            "subscores": [],
            "reason": f"anti_cheat_failed: {ac.get('violations', '')}",
        })
        return

    if ac.get("strace_cheat"):
        write_reward(outdir, 0.0, {
            "subscores": [],
            "reason": f"strace_detected_external_git: {ac.get('strace_details', '')}",
        })
        return

    # ── Build decision ──────────────────────────────────────────────
    build = evidence.get("build", {})
    if build.get("exit_code", 1) != 0:
        write_reward(outdir, 0.0, {
            "subscores": [],
            "reason": "build_failed",
        })
        return

    binary_path = build.get("binary_path", "")
    if not binary_path:
        write_reward(outdir, 0.0, {
            "subscores": [],
            "reason": "no_binary_produced",
        })
        return

    binary_type = build.get("binary_type", "")
    if not evidence.get("is_oracle") and binary_type and "ELF" not in binary_type:
        write_reward(outdir, 0.0, {
            "subscores": [],
            "reason": f"binary_not_elf: {binary_type}",
        })
        return

    if build.get("links_libgit2"):
        write_reward(outdir, 0.0, {
            "subscores": [],
            "reason": "links_libgit2",
        })
        return

    # ── Test results ────────────────────────────────────────────────
    results_dir = evidence.get("results_dir", "")
    if not evidence.get("tests_ran") or not results_dir:
        write_reward(outdir, 0.0, {
            "subscores": [],
            "reason": "tests_did_not_run",
        })
        return

    results = parse_tap_results(results_dir)

    reward = results["total_passed"] / ORACLE_TOTAL_ATTEMPTED

    subscores = []
    for cat_key in sorted(CATEGORIES.keys()):
        cat_info = CATEGORIES[cat_key]
        stats = results["categories"].get(cat_key, {"passed": 0, "failed": 0, "skipped": 0})
        oracle_attempted = cat_info["oracle_attempted"]
        cat_score = stats["passed"] / oracle_attempted if oracle_attempted > 0 else 0.0
        subscores.append({
            "subtask": f"{cat_key}-{cat_info['label']}",
            "score": round(cat_score, 4),
            "stdout": f"passed={stats['passed']} failed={stats['failed']} skipped={stats['skipped']} oracle_baseline={oracle_attempted}",
            "stderr": "",
        })

    write_reward(outdir, round(reward, 6), {
        "total_passed": results["total_passed"],
        "total_failed": results["total_failed"],
        "total_skipped": results["total_skipped"],
        "total_attempted": results["total_passed"] + results["total_failed"],
        "scripts_run": results["scripts_run"],
        "subscores": subscores,
    })


if __name__ == "__main__":
    main()
