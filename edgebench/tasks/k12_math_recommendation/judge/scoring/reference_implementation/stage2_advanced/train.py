"""
K12 Math Knowledge Tracing & Personalized Recommendation — advanced training script

Improvements over the baseline:
1. Mastery estimation: BKT-style cumulative theta model, initial theta derived from entry test score
   (closer to real initial ability distribution), with slight forgetting decay on unpracticed KPs.
2. IRT parameters: 2PL IRT prediction using question discrimination and difficulty.
3. Keep question index, prerequisite graph, and recent-answer lists for recommendation constraints.

Output: ./models/advanced.pkl
"""
import argparse
import csv
import math
import pickle
from collections import defaultdict
from pathlib import Path

import numpy as np

NUM_KPS = 50
GAIN_CORRECT = 0.28
GAIN_WRONG = 0.10
FORGET_DECAY = 0.002  # slight decay on unpracticed KPs after each answer


def train(data_dir: Path, model_out: Path):
    # 1) Question bank
    qb = {}
    with open(data_dir / "question_bank.csv", encoding="utf-8") as fp:
        for r in csv.DictReader(fp):
            qb[r["question_id"]] = {
                "difficulty": int(r["difficulty_level"]),
                "kps": [int(x) for x in r["knowledge_point_ids"].split(";")],
                "avg_correct": float(r["avg_correct_rate"]),
                "discrimination": float(r["discrimination"]),
            }
    print(f"loaded {len(qb)} questions")

    # 2) Prerequisite graph
    prereq = {}
    with open(data_dir / "knowledge_graph.csv", encoding="utf-8") as fp:
        for r in csv.DictReader(fp):
            ids = r["prerequisite_kp_ids"]
            prereq[int(r["kp_id"])] = [int(x) for x in ids.split(";")] if ids else []
    print("loaded prerequisite graph")

    # 3) Student profiles (for theta prior)
    stu_info = {}
    with open(data_dir / "student_info.csv", encoding="utf-8") as fp:
        for r in csv.DictReader(fp):
            stu_info[r["student_id"]] = {
                "entry_test_score": float(r["entry_test_score"]),
                "grade": int(r["grade"]),
            }
    print(f"loaded {len(stu_info)} student profiles")

    # 4) Aggregate answer sequences per student
    stu_hist = defaultdict(list)
    with open(data_dir / "answering_logs.csv", encoding="utf-8") as fp:
        for r in csv.DictReader(fp):
            stu_hist[r["student_id"]].append(
                (int(r["timestamp"]), r["question_id"], int(r["is_correct"]))
            )
    for sid in stu_hist:
        stu_hist[sid].sort()
    print(f"aggregated history for {len(stu_hist)} students")

    # 5) Persist
    model = {
        "qb": qb,
        "prereq": prereq,
        "stu_info": stu_info,
        "stu_hist": dict(stu_hist),
        "gain_correct": GAIN_CORRECT,
        "gain_wrong": GAIN_WRONG,
        "forget_decay": FORGET_DECAY,
    }
    model_out.parent.mkdir(parents=True, exist_ok=True)
    with open(model_out, "wb") as fp:
        pickle.dump(model, fp)
    print(f"wrote {model_out} ({model_out.stat().st_size / 1024 / 1024:.1f} MB)")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--data_dir", default="../../input_data/")
    parser.add_argument("--model_out", default="./models/advanced.pkl")
    args = parser.parse_args()
    train(Path(args.data_dir).resolve(), Path(args.model_out).resolve())
