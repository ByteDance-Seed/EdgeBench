#!/usr/bin/env python3
"""Audit SMT benchmark label-prior baselines.

This is intended for author-side checks before publishing hidden data. The SMT
task requires a validated witness for `sat`, but still does not require an
`unsat` proof, so the most important free baseline is always printing `unsat`.
"""

import argparse
import collections
import json
import sys
import zipfile


WEIGHTS = {"easy": 0.10, "medium": 0.20, "hard": 0.70}


def load_zip(path):
    with zipfile.ZipFile(path) as zf:
        expected = json.loads(zf.read("expected_answers.json"))
        manifest = {
            entry["selected_path"]: entry
            for entry in json.loads(zf.read("selection_manifest.json"))
        }
    missing = sorted(set(expected) - set(manifest))
    if missing:
        raise SystemExit(f"manifest missing {len(missing)} expected-answer keys")
    return expected, manifest


def weighted_guess_score(expected, manifest, guess):
    score = 0.0
    by_difficulty = {}
    for difficulty, weight in WEIGHTS.items():
        keys = [key for key in expected if manifest[key]["difficulty"] == difficulty]
        correct = sum(1 for key in keys if expected[key] == guess)
        fraction = correct / len(keys) if keys else 0.0
        by_difficulty[difficulty] = (correct, len(keys), fraction)
        score += weight * fraction
    return score, by_difficulty


def print_guess(name, expected, manifest):
    score, by_difficulty = weighted_guess_score(expected, manifest, name)
    print(f"weighted always_{name}: {score * 100:.2f}%")
    for difficulty in WEIGHTS:
        correct, total, fraction = by_difficulty[difficulty]
        print(f"  {difficulty:6s}: {correct:4d}/{total:<4d} {fraction * 100:6.2f}%")
    return score


def bucket_report(expected, manifest):
    buckets = collections.defaultdict(collections.Counter)
    for key, answer in expected.items():
        logic = key.split("/", 1)[0]
        difficulty = manifest[key]["difficulty"]
        buckets[(logic, difficulty)][answer] += 1
    print("\nlogic+difficulty buckets:")
    max_unsat_fraction = 0.0
    for bucket in sorted(buckets):
        counts = buckets[bucket]
        total = counts["sat"] + counts["unsat"]
        unsat_fraction = counts["unsat"] / total if total else 0.0
        max_unsat_fraction = max(max_unsat_fraction, unsat_fraction)
        print(
            f"  {bucket[0]:8s} {bucket[1]:6s} "
            f"n={total:4d} sat={counts['sat']:4d} unsat={counts['unsat']:4d} "
            f"unsat={unsat_fraction * 100:6.2f}%"
        )
    return max_unsat_fraction


def main():
    parser = argparse.ArgumentParser(description="Audit SMT label-prior baselines")
    parser.add_argument("zipfile", help="Benchmark zip containing expected_answers.json and selection_manifest.json")
    parser.add_argument("--max-always-unsat", type=float, default=0.30)
    parser.add_argument("--max-bucket-unsat", type=float, default=0.35)
    args = parser.parse_args()

    expected, manifest = load_zip(args.zipfile)
    counts = collections.Counter(expected.values())
    total = len(expected)
    print(f"total={total} sat={counts['sat']} unsat={counts['unsat']}")
    print_guess("sat", expected, manifest)
    always_unsat = print_guess("unsat", expected, manifest)
    max_bucket_unsat = bucket_report(expected, manifest)

    failed = False
    if always_unsat > args.max_always_unsat:
        print(
            f"\nFAIL: always_unsat {always_unsat * 100:.2f}% exceeds "
            f"{args.max_always_unsat * 100:.2f}%",
            file=sys.stderr,
        )
        failed = True
    if max_bucket_unsat > args.max_bucket_unsat:
        print(
            f"FAIL: bucket unsat {max_bucket_unsat * 100:.2f}% exceeds "
            f"{args.max_bucket_unsat * 100:.2f}%",
            file=sys.stderr,
        )
        failed = True
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
