"""
K12 Math Knowledge Tracing & Personalized Recommendation — baseline training script

Design choices:
- Knowledge tracing: Laplace-smoothed correct rate aggregated per (student_id, kp_id),
  no deep model. Pros: zero training cost, interpretable, CPU-friendly; cons: no temporal or forgetting modeling.
- Next-question prediction: item-level avg_correct_rate combined with the student's
  mastery adjustment on the question's KPs.
- Recommendation: ZPD-aware heuristic (target mastery in [0.25, 0.65]) + constraint checks.

Training output: ./models/baseline.pkl (student-kp mastery table + question index + prerequisite graph)

Usage: python train.py --data_dir ../../input_data/ --model_out ./models/baseline.pkl
"""
import argparse
import csv
import os
import pickle
from collections import defaultdict
from pathlib import Path


def train(data_dir: Path, model_out: Path):
    # 1) Load question bank
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

    # 2) Load knowledge point graph
    prereq = {}
    with open(data_dir / "knowledge_graph.csv", encoding="utf-8") as fp:
        for r in csv.DictReader(fp):
            ids = r["prerequisite_kp_ids"]
            prereq[int(r["kp_id"])] = (
                [int(x) for x in ids.split(";")] if ids else []
            )
    print(f"loaded prerequisite graph")

    # 3) Keep full answer sequence per student (bisected at cutoff_ts during inference to avoid future leakage)
    stu_ans = defaultdict(list)  # list of (ts, qid, is_correct, kps)
    stu_done = defaultdict(list)  # list of (ts, qid)
    with open(data_dir / "answering_logs.csv", encoding="utf-8") as fp:
        for r in csv.DictReader(fp):
            sid = r["student_id"]
            qid = r["question_id"]
            ts = int(r["timestamp"])
            ic = int(r["is_correct"])
            kps = [int(x) for x in r["knowledge_point_ids"].split(";")]
            stu_ans[sid].append((ts, qid, ic, kps))
            stu_done[sid].append((ts, qid))
    for sid in stu_ans:
        stu_ans[sid].sort()
        stu_done[sid].sort()
    print(f"aggregated history for {len(stu_ans)} students")

    # 4) Persist
    model = {
        "qb": qb,
        "prereq": prereq,
        "stu_ans": dict(stu_ans),
        "stu_done": dict(stu_done),
    }
    model_out.parent.mkdir(parents=True, exist_ok=True)
    with open(model_out, "wb") as fp:
        pickle.dump(model, fp)
    print(f"wrote {model_out} ({model_out.stat().st_size / 1024:.1f} KB)")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--data_dir", default="../../input_data/")
    parser.add_argument("--model_out", default="./models/baseline.pkl")
    args = parser.parse_args()
    train(Path(args.data_dir).resolve(), Path(args.model_out).resolve())
