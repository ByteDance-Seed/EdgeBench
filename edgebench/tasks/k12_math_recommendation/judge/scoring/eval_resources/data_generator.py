"""
Data generation script (used by task authors, not distributed to Agent).

Generates answering_logs.csv / question_bank.csv / knowledge_graph.csv /
student_info.csv / dev_scenarios.json / test_scenarios.json / test_ground_truth.json
required by this task.

The underlying student answering data is simulated with IRT (2PL) + BKT-style
learning dynamics, exhibiting these real-world characteristics:
- Student ability rises slowly over time (learning), affected by forgetting/state fluctuation
- Question difficulty and discrimination sampled from realistic instructional distributions
- Prerequisite relationships between knowledge points affect mastery propagation
- Both cold-start students and long-sequence active students exist

Notes on generation:
- simulate_answering additionally returns each student's theta snapshot after every
  answer (theta_trajectories), so build_scenarios can read the true theta at cutoff_ts
  and derive knowledge_truth (sigmoid(theta)).
- test_ground_truth.json additionally outputs weak_kps_truth and target_zpd_kps for
  evaluate.py to make objective M4 C3/C4 judgments and align the M3 post-test pool.
- post_test_question_ids are sampled from questions covering each student's 3~5 ZPD
  target KPs, so recommendation strategies that precisely hit ZPD knowledge points
  produce observable post-test score differences.

Usage: python data_generator.py --output_dir ../input_data/ --eval_dir ./
"""
import argparse
import csv
import json
import math
import os
import random
from datetime import datetime, timedelta
from pathlib import Path

import numpy as np

RANDOM_SEED = 20260418
NUM_STUDENTS = 10000
NUM_QUESTIONS = 5000
NUM_KPS = 50
NUM_INTERACTIONS_PER_STUDENT_MEAN = 80
NUM_INTERACTIONS_PER_STUDENT_STD = 30
NUM_DEV_SCENARIOS = 100
NUM_TEST_SCENARIOS = 100

KP_CHAPTERS = {
    (1, 10): "Compulsory 1: Sets & Functions",
    (11, 20): "Compulsory 2: Geometry",
    (21, 30): "Compulsory 3&4: Trigonometry & Sequences",
    (31, 40): "Compulsory 5: Solving Triangles & Inequalities",
    (41, 50): "Elective: Derivatives, Statistics & Probability",
}
KP_NAMES = [
    "Basic concepts and operations of sets", "Domain and range of functions",
    "Monotonicity of functions", "Parity of functions",
    "Properties of exponential functions", "Properties of logarithmic functions",
    "Properties of power functions", "Function graph transformations",
    "Function zeros and equation roots", "Inverse function concept",
    "Spatial solid structures", "Three-view identification",
    "Point-line-plane positional relationships", "Line-plane parallelism",
    "Line-plane perpendicularity", "Dihedral angles", "Line equations",
    "Circles and equations", "Line-circle positional relationships",
    "Spatial rectangular coordinate system",
    "Arbitrary angles and radian measure", "Definition of trigonometric functions",
    "Same-angle trigonometric identities", "Trigonometric reduction formulas",
    "Trig function graph properties", "Sum and difference formulas",
    "Double-angle and half-angle formulas", "Sequence concepts and general terms",
    "Arithmetic sequences", "Geometric sequences",
    "Law of sines", "Law of cosines", "Comprehensive triangle solving",
    "Quadratic inequalities", "Rational inequalities", "Absolute value inequalities",
    "AM-GM inequality", "Linear programming", "Vector concepts",
    "Plane vector operations",
    "Definition and geometric meaning of derivatives",
    "Derivatives of basic elementary functions", "Derivative operation rules",
    "Derivatives and monotonicity", "Derivatives, extrema and absolute values",
    "Definite integrals", "Classical probability", "Geometric probability",
    "Conditional probability", "Normal distribution",
]
PREREQ_EDGES = [
    (3, 2), (4, 2), (8, 2), (9, 2), (9, 3), (10, 2), (5, 2), (6, 5), (7, 2),
    (14, 13), (15, 13), (16, 14), (16, 15), (17, 11), (18, 17), (19, 17), (19, 18),
    (20, 17), (22, 21), (23, 22), (24, 22), (25, 22), (26, 24), (27, 26),
    (29, 28), (30, 28), (31, 22), (32, 22), (33, 31), (33, 32),
    (35, 34), (36, 34), (37, 34), (38, 34), (40, 39),
    (42, 41), (43, 42), (44, 42), (45, 44), (46, 42), (48, 47), (49, 47), (50, 47),
]

# Realistic learning dynamics (BKT-flavored)
# Correct answer boosts KP ability: the shakier the mastery, the larger the single-step
# gain; near-zero gain once fully mastered.
# Wrong answers give a small gain (learning from mistakes), nearly zero if not learned yet.
LEARN_GAIN_CORRECT = 0.28     # multiplied by (1 - sigmoid(theta))
LEARN_GAIN_WRONG = 0.10       # multiplied by sigmoid(theta) * (1 - sigmoid(theta))  # max at boundary
# Tiny forgetting applied to a student's unpracticed KPs after each answer
FORGET_DECAY = 0.002


def gen_knowledge_graph(out_path):
    with open(out_path, "w", newline="", encoding="utf-8") as fp:
        writer = csv.writer(fp)
        writer.writerow(["kp_id", "kp_name", "chapter", "prerequisite_kp_ids"])
        for kp_id in range(1, NUM_KPS + 1):
            chapter = next(v for (lo, hi), v in KP_CHAPTERS.items() if lo <= kp_id <= hi)
            prereqs = [str(p) for (c, p) in PREREQ_EDGES if c == kp_id]
            writer.writerow([kp_id, KP_NAMES[kp_id - 1], chapter, ";".join(prereqs)])


def gen_question_bank(rng, out_path):
    rows = []
    kp_ids = np.arange(1, NUM_KPS + 1)
    for q in range(1, NUM_QUESTIONS + 1):
        primary_kp = int(rng.choice(kp_ids))
        num_kp = int(rng.choice([1, 1, 1, 2, 2, 3], p=[0.5, 0.0, 0.0, 0.35, 0.0, 0.15]))
        extra = rng.choice(np.delete(kp_ids, primary_kp - 1), size=num_kp - 1, replace=False)
        kps = sorted([primary_kp] + extra.tolist())
        difficulty = int(rng.choice([1, 2, 3, 4, 5], p=[0.12, 0.23, 0.30, 0.22, 0.13]))
        qtype = rng.choice(["single_choice", "multi_choice", "fill_blank", "solve"],
                           p=[0.5, 0.15, 0.2, 0.15])
        avg_correct = max(0.05, min(0.95, 0.9 - 0.13 * difficulty + rng.normal(0, 0.08)))
        discrimination = max(0.2, min(2.0, 0.9 + rng.normal(0, 0.35)))
        rows.append({
            "question_id": f"Q{q:05d}",
            "difficulty_level": difficulty,
            "knowledge_point_ids": ";".join(str(k) for k in kps),
            "question_type": qtype,
            "avg_correct_rate": round(float(avg_correct), 4),
            "discrimination": round(float(discrimination), 4),
        })
    with open(out_path, "w", newline="", encoding="utf-8") as fp:
        writer = csv.DictWriter(fp, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)
    return rows


def gen_student_info(rng, out_path):
    rows = []
    for s in range(1, NUM_STUDENTS + 1):
        grade = int(rng.choice([10, 11, 12], p=[0.45, 0.35, 0.20]))
        entry = float(max(0, min(100, rng.normal(65, 14))))
        tier = int(rng.choice([1, 2, 3, 4], p=[0.18, 0.28, 0.34, 0.20]))
        rows.append({
            "student_id": f"S_{s:06d}",
            "grade": grade,
            "entry_test_score": round(entry, 2),
            "region_tier": tier,
        })
    with open(out_path, "w", newline="", encoding="utf-8") as fp:
        writer = csv.DictWriter(fp, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)
    return rows


def _sigmoid(x):
    return 1.0 / (1.0 + np.exp(-x))


def simulate_answering(rng, students, questions, base_start):
    """IRT + BKT-style dynamics simulation.
    Returns:
        logs                  - list of interaction dicts
        theta_trajectories    - dict[student_id] -> list of (timestamp, theta_snapshot)
                                used by the evaluator to extract true theta at cutoff_ts
                                as ground truth
    """
    q_by_id = {q["question_id"]: q for q in questions}
    q_ids = [q["question_id"] for q in questions]
    kp_to_questions = {}
    for q in questions:
        for kp in q["knowledge_point_ids"].split(";"):
            kp_to_questions.setdefault(int(kp), []).append(q["question_id"])

    logs = []
    theta_trajectories = {}

    for stu in students:
        # Each student's ability on 50 KPs (initial value correlated with entry score)
        theta = rng.normal(
            (stu["entry_test_score"] - 65) / 15.0, 0.6, size=NUM_KPS
        )
        n_inter = max(20, int(rng.normal(NUM_INTERACTIONS_PER_STUDENT_MEAN,
                                         NUM_INTERACTIONS_PER_STUDENT_STD)))
        t_cursor = base_start + timedelta(
            hours=float(rng.uniform(0, 24 * 30))
        )
        traj = [(int(t_cursor.timestamp()), theta.copy())]

        for i in range(n_inter):
            # Pick questions biased toward the student's weak KPs, with long-tail noise
            weak_kp = int(np.argmin(theta) + 1) if rng.uniform() < 0.35 else int(
                rng.choice(np.arange(1, NUM_KPS + 1)))
            candidates = kp_to_questions.get(weak_kp, q_ids)
            qid = str(rng.choice(candidates))
            q = q_by_id[qid]
            kps = [int(k) for k in q["knowledge_point_ids"].split(";")]
            # 2PL IRT: P = sigmoid(a*(theta_bar - b))
            theta_bar = float(np.mean([theta[k - 1] for k in kps]))
            b = (q["difficulty_level"] - 3) * 0.9
            a = q["discrimination"]
            p_correct = 1.0 / (1.0 + np.exp(-a * (theta_bar - b)))
            is_correct = 1 if rng.uniform() < p_correct else 0

            # -- Learning dynamics --
            # For KPs involved in the answered question:
            #   correct -> ZPD-principle theta gain: lower m (unmastered) means larger gain
            #   wrong   -> theta drop scaled by current confidence: higher m (should have
            #              gotten it right) means a more surprising miss and larger drop
            # This keeps mastery estimates converging to the true correct-rate distribution
            # over time instead of drifting ever upward.
            for k in kps:
                m = _sigmoid(theta[k - 1])
                if is_correct:
                    theta[k - 1] += LEARN_GAIN_CORRECT * (1.0 - m)
                else:
                    theta[k - 1] -= LEARN_GAIN_WRONG * 4.0 * m * (1.0 - m)
            # Slight forgetting on unpracticed KPs
            touched = set(kps)
            for k in range(1, NUM_KPS + 1):
                if k not in touched:
                    theta[k - 1] -= FORGET_DECAY * _sigmoid(theta[k - 1])

            dt_hours = float(rng.exponential(6.0))
            t_cursor += timedelta(hours=dt_hours)
            time_spent = max(5, int(rng.gamma(3, 15 + (q["difficulty_level"] - 1) * 10)))
            logs.append({
                "student_id": stu["student_id"],
                "question_id": qid,
                "knowledge_point_ids": q["knowledge_point_ids"],
                "timestamp": int(t_cursor.timestamp()),
                "is_correct": is_correct,
                "time_spent_sec": time_spent,
                "response": "A" if is_correct else "B",
            })
            traj.append((int(t_cursor.timestamp()), theta.copy()))

        theta_trajectories[stu["student_id"]] = traj
    return logs, theta_trajectories


def write_logs(logs, out_path):
    logs = sorted(logs, key=lambda r: r["timestamp"])
    with open(out_path, "w", newline="", encoding="utf-8") as fp:
        writer = csv.DictWriter(fp, fieldnames=list(logs[0].keys()))
        writer.writeheader()
        writer.writerows(logs)


def _theta_at(traj, ts):
    """Fetch the latest snapshot with timestamp <= ts from the theta trajectory.
    traj is monotonically increasing by timestamp."""
    chosen = traj[0][1]
    for t, th in traj:
        if t <= ts:
            chosen = th
        else:
            break
    return chosen


def build_scenarios(rng, logs, questions, students, theta_trajectories,
                    n_scenarios, include_truth):
    q_by_id = {q["question_id"]: q for q in questions}
    q_ids = list(q_by_id.keys())
    kp_to_questions = {}
    for q in questions:
        for kp in q["knowledge_point_ids"].split(";"):
            kp_to_questions.setdefault(int(kp), []).append(q["question_id"])

    # Group logs by student
    by_stu = {}
    for r in logs:
        by_stu.setdefault(r["student_id"], []).append(r)
    # Choose students with enough interactions as scenario students
    # (candidate pool is 3x to guarantee we can fill n_scenarios)
    eligible = [s for s, rs in by_stu.items() if 30 <= len(rs) <= 150]
    rng.shuffle(eligible)
    chosen = eligible[:n_scenarios * 3]

    scenarios, ground_truth = [], []
    next_idx = 0
    for sid in chosen:
        if len(scenarios) >= n_scenarios:
            break
        rs = sorted(by_stu[sid], key=lambda r: r["timestamp"])
        cutoff_idx = int(len(rs) * rng.uniform(0.6, 0.85))
        history = rs[:cutoff_idx]
        future = rs[cutoff_idx:cutoff_idx + 20]  # used as next-question candidates
        if len(future) < 10:
            continue
        cutoff_ts = history[-1]["timestamp"]
        i = next_idx
        next_idx += 1
        # True theta snapshot at cutoff
        traj = theta_trajectories.get(sid, [])
        theta_at_cutoff = _theta_at(traj, cutoff_ts) if traj else np.zeros(NUM_KPS)
        true_mastery = _sigmoid(theta_at_cutoff).tolist()

        # Candidate questions: start from actually answered future questions (deduped),
        # backfill from the full question bank when fewer than 20, ensuring exactly
        # 20 **unique** IDs
        seen = []
        seen_set = set()
        for r in future:
            qid = r["question_id"]
            if qid not in seen_set:
                seen.append(qid)
                seen_set.add(qid)
        while len(seen) < 20:
            qid = str(rng.choice(q_ids))
            if qid not in seen_set:
                seen.append(qid)
                seen_set.add(qid)
        candidates = seen[:20]
        assert len(candidates) == 20 and len(set(candidates)) == 20

        done = {r["question_id"] for r in rs}
        pool = rng.choice([q for q in q_ids if q not in done], size=200, replace=False).tolist()

        # post_test_question_ids focus on 3~5 ZPD knowledge points so that
        # recommendations hitting ZPD KPs produce observable learning gain.
        zpd_kps_all = [k + 1 for k, m in enumerate(true_mastery) if 0.25 < m < 0.65]
        if len(zpd_kps_all) < 3:
            # Fall back to KPs with mastery < 0.5 for students with extreme ability
            zpd_kps_all = [k + 1 for k, m in enumerate(true_mastery) if m < 0.5]
        # Randomly pick 5 ZPD KPs as post-test target KPs (Agent doesn't know which 5)
        target_n = min(5, len(zpd_kps_all))
        target_zpd_kps = rng.choice(zpd_kps_all, size=target_n, replace=False).tolist()
        # Sample 10 post-test questions from those covering the 5 target KPs
        narrow_q_pool = set()
        for k in target_zpd_kps:
            for q in kp_to_questions.get(int(k), []):
                if q not in done:
                    narrow_q_pool.add(q)
        narrow_q_pool = list(narrow_q_pool)
        if len(narrow_q_pool) < 10:
            # Fall back to questions of all ZPD-range KPs
            for k in zpd_kps_all:
                for q in kp_to_questions.get(int(k), []):
                    if q not in done:
                        narrow_q_pool.append(q)
            narrow_q_pool = list(set(narrow_q_pool))
        if len(narrow_q_pool) < 10:
            narrow_q_pool = list(set(narrow_q_pool) |
                                 {q for q in q_ids if q not in done})
        post_test_question_ids = rng.choice(narrow_q_pool, size=10,
                                            replace=False).tolist()

        scenario = {
            "scenario_id": f"{'test' if include_truth else 'dev'}_{i + 1:03d}",
            "student_id": sid,
            "timestamp": cutoff_ts,
            "candidate_questions": candidates,
            "recommendation_pool": pool,
        }
        if include_truth:
            scenario["post_test_question_ids"] = post_test_question_ids
        else:
            # Dev scenarios expose a few next-question outcomes for Agent self-testing
            scenario["dev_next_correct"] = {r["question_id"]: r["is_correct"]
                                             for r in future[:10]}
        scenarios.append(scenario)

        if include_truth:
            # knowledge_truth derived from sigmoid of true theta at cutoff
            weak_kps_gt = [k + 1 for k, m in enumerate(true_mastery) if m < 0.5]
            ground_truth.append({
                "scenario_id": scenario["scenario_id"],
                "next_question_truth": {r["question_id"]: r["is_correct"] for r in future},
                "knowledge_truth": [round(float(m), 4) for m in true_mastery],
                "weak_kps_truth": weak_kps_gt,
                "target_zpd_kps": [int(k) for k in target_zpd_kps],
                "post_test_question_ids": post_test_question_ids,
            })

    return scenarios, ground_truth


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output_dir", default="../input_data/")
    parser.add_argument("--eval_dir", default="./")
    args = parser.parse_args()

    rng = np.random.default_rng(RANDOM_SEED)
    random.seed(RANDOM_SEED)

    inp_dir = Path(args.output_dir).resolve()
    eval_dir = Path(args.eval_dir).resolve()
    inp_dir.mkdir(parents=True, exist_ok=True)
    eval_dir.mkdir(parents=True, exist_ok=True)

    print(f"[1/6] Generating knowledge graph -> {inp_dir}/knowledge_graph.csv")
    gen_knowledge_graph(inp_dir / "knowledge_graph.csv")

    print(f"[2/6] Generating question bank -> {inp_dir}/question_bank.csv")
    questions = gen_question_bank(rng, inp_dir / "question_bank.csv")

    print(f"[3/6] Generating student profiles -> {inp_dir}/student_info.csv")
    students = gen_student_info(rng, inp_dir / "student_info.csv")

    print(f"[4/6] Simulating answer logs (~{NUM_STUDENTS * NUM_INTERACTIONS_PER_STUDENT_MEAN} rows)")
    base = datetime(2025, 9, 1, 0, 0, 0)
    logs, theta_trajectories = simulate_answering(rng, students, questions, base)
    print(f"       Actually generated {len(logs)} rows -> {inp_dir}/answering_logs.csv")
    write_logs(logs, inp_dir / "answering_logs.csv")

    print(f"[5/6] Building dev scenarios -> {inp_dir}/dev_scenarios.json")
    dev, _ = build_scenarios(rng, logs, questions, students, theta_trajectories,
                             NUM_DEV_SCENARIOS, include_truth=False)
    with open(inp_dir / "dev_scenarios.json", "w", encoding="utf-8") as fp:
        json.dump({"scenarios": dev}, fp, ensure_ascii=False, indent=2)

    print(f"[6/6] Building test scenarios + ground truth -> {eval_dir}/test_scenarios.json")
    test, truth = build_scenarios(rng, logs, questions, students, theta_trajectories,
                                  NUM_TEST_SCENARIOS, include_truth=True)
    with open(eval_dir / "test_scenarios.json", "w", encoding="utf-8") as fp:
        json.dump({"scenarios": test}, fp, ensure_ascii=False, indent=2)
    with open(eval_dir / "test_ground_truth.json", "w", encoding="utf-8") as fp:
        json.dump({"ground_truth": truth}, fp, ensure_ascii=False, indent=2)

    # Stats report + count validation
    assert len(dev) == NUM_DEV_SCENARIOS, f"dev scenario count {len(dev)} != {NUM_DEV_SCENARIOS}"
    assert len(test) == NUM_TEST_SCENARIOS, f"test scenario count {len(test)} != {NUM_TEST_SCENARIOS}"
    assert len(truth) == NUM_TEST_SCENARIOS, f"ground_truth scenario count {len(truth)} != {NUM_TEST_SCENARIOS}"
    mastery_all = np.concatenate([np.array(gt["knowledge_truth"]) for gt in truth])
    print(f"       Scenario counts: dev={len(dev)} test={len(test)} ground_truth={len(truth)}")
    print(f"       True knowledge_truth stats: mean={mastery_all.mean():.3f} "
          f"std={mastery_all.std():.3f} min={mastery_all.min():.3f} "
          f"max={mastery_all.max():.3f}")
    weak_counts = [len(gt["weak_kps_truth"]) for gt in truth]
    print(f"       Per-scenario weak_kps count: mean={np.mean(weak_counts):.1f} "
          f"min={min(weak_counts)} max={max(weak_counts)}")
    print("Done.")


if __name__ == "__main__":
    main()
