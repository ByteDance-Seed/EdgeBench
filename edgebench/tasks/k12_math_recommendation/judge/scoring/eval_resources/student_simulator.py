"""
Student answer simulator (evaluator-side, not distributed to Agent).

Core responsibilities:
1. Fit student ability vector theta on 50 KPs from historical answer logs via BKT-style ZPD learning dynamics
   (used as M3 learning gain baseline and M4 C3/C4 objective assessment).
2. Simulate answering + ability updates for Agent-recommended 10 questions, return student
   expected post-test score (M3 agent_post_score).
3. Provide evaluator_mastery_estimate / evaluator_weak_kps / evaluator_prereq_met
   interfaces for evaluate.py C3 (weak KP coverage) and C4 (prerequisite mastery)
   using evaluator independent estimates, not Agent-reported knowledge_state.

Interface example:
    sim = StudentSimulator(logs_path=..., questions_path=..., kp_graph_path=..., seed=42)
    post_score = sim.simulate(student_id, cutoff_ts, recommended, post_test)
    weak_kps  = sim.evaluator_weak_kps(student_id, cutoff_ts)
"""
import csv
import math
from collections import defaultdict
from pathlib import Path

import numpy as np

NUM_KPS = 50

# Two coefficient sets: history fitting vs recommendation
# HIST_* for _fit_theta (replaying student history), consistent with data_generator.
# REC_* for simulate (guided practice dynamics on Agent-recommended questions);
#         larger than HIST_*, reflecting guided recommendations being more efficient than random practice.
#         This ensures recommendations precisely targeting weak/ZPD KPs produce observable post-test gain,
#         while broad random strategies cannot score by luck.
HIST_GAIN_CORRECT = 0.28
HIST_GAIN_WRONG = 0.10
REC_GAIN_CORRECT = 0.55
REC_GAIN_WRONG = 0.18

# M4 thresholds (consistent with scoring rules)
WEAK_THRESHOLD = 0.5
PREREQ_THRESHOLD = 0.3


def _sigmoid(x):
    if isinstance(x, (int, float)):
        return 1.0 / (1.0 + math.exp(-float(x)))
    return 1.0 / (1.0 + np.exp(-np.asarray(x)))


class StudentSimulator:
    def __init__(self, logs_path, questions_path, kp_graph_path, seed=42):
        self.rng = np.random.default_rng(seed)
        self.questions = self._load_questions(questions_path)
        self.prereq = self._load_prereq(kp_graph_path)
        self.logs_by_stu = self._load_logs(logs_path)
        self._cached_theta = {}

    # ------------------------ Data Loading ------------------------
    def _load_questions(self, path):
        qs = {}
        with open(path, newline="", encoding="utf-8") as fp:
            for r in csv.DictReader(fp):
                qs[r["question_id"]] = {
                    "difficulty": int(r["difficulty_level"]),
                    "kps": [int(x) for x in r["knowledge_point_ids"].split(";")],
                    "discrimination": float(r["discrimination"]),
                }
        return qs

    def _load_prereq(self, path):
        pre = {}
        with open(path, newline="", encoding="utf-8") as fp:
            for r in csv.DictReader(fp):
                ids = r["prerequisite_kp_ids"]
                pre[int(r["kp_id"])] = [int(x) for x in ids.split(";")] if ids else []
        return pre

    def _load_logs(self, path):
        by_stu = defaultdict(list)
        with open(path, newline="", encoding="utf-8") as fp:
            for r in csv.DictReader(fp):
                by_stu[r["student_id"]].append({
                    "question_id": r["question_id"],
                    "timestamp": int(r["timestamp"]),
                    "is_correct": int(r["is_correct"]),
                })
        return by_stu

    # ------------------------ Core Estimation ------------------------
    def _fit_theta(self, student_id, cutoff_ts):
        """Estimate theta from student history up to cutoff_ts via ZPD learning dynamics.
        Key: dynamics here must match data_generator.simulate_answering so that
        mastery_truth and real simulated theta are close in expectation.
        """
        key = (student_id, cutoff_ts)
        if key in self._cached_theta:
            return self._cached_theta[key].copy()

        theta = np.zeros(NUM_KPS, dtype=np.float64)
        hist = [r for r in self.logs_by_stu.get(student_id, [])
                if r["timestamp"] <= cutoff_ts]
        if not hist:
            self._cached_theta[key] = theta
            return theta.copy()

        for r in hist:
            q = self.questions.get(r["question_id"])
            if not q:
                continue
            for k in q["kps"]:
                m = float(1.0 / (1.0 + math.exp(-theta[k - 1])))
                if r["is_correct"]:
                    theta[k - 1] += HIST_GAIN_CORRECT * (1.0 - m)
                else:
                    theta[k - 1] -= HIST_GAIN_WRONG * 4.0 * m * (1.0 - m)
        theta = np.clip(theta, -3.0, 3.0)
        self._cached_theta[key] = theta
        return theta.copy()

    def _prob(self, theta, qid):
        q = self.questions[qid]
        theta_bar = float(np.mean([theta[k - 1] for k in q["kps"]]))
        b = (q["difficulty"] - 3) * 0.9
        a = q["discrimination"]
        z = a * (theta_bar - b)
        z = max(-12.0, min(12.0, z))
        return 1.0 / (1.0 + math.exp(-z))

    # ------------------------ M3: Learning Gain Simulation ------------------------
    def simulate(self, student_id, history_cutoff_ts,
                 recommended_question_ids, post_test_question_ids):
        theta = self._fit_theta(student_id, history_cutoff_ts)
        # Answer recommended questions, update theta via ZPD dynamics (learning)
        for qid in recommended_question_ids:
            q = self.questions.get(qid)
            if not q:
                continue
            p = self._prob(theta, qid)
            got_right = self.rng.uniform() < p
            for kp in q["kps"]:
                m = float(1.0 / (1.0 + math.exp(-theta[kp - 1])))
                if got_right:
                    theta[kp - 1] += REC_GAIN_CORRECT * (1.0 - m)
                else:
                    theta[kp - 1] -= REC_GAIN_WRONG * 4.0 * m * (1.0 - m)
        theta = np.clip(theta, -3.0, 3.0)
        # Post-test: expected correct rate (low variance, reproducible)
        correct_probs = [self._prob(theta, qid) for qid in post_test_question_ids
                         if qid in self.questions]
        return float(np.mean(correct_probs)) if correct_probs else 0.0

    # ------------------------ M4: Evaluator Independent Mastery Estimation ------------------------
    def evaluator_mastery_estimate(self, student_id, cutoff_ts):
        """Evaluator objective estimate: sigmoid(theta) from student history.
        Used for M4 C3 (weak KP coverage) and C4 (prerequisite mastery),
        independent of Agent knowledge_state reports.
        """
        theta = self._fit_theta(student_id, cutoff_ts)
        return [float(1.0 / (1.0 + math.exp(-float(t)))) for t in theta]

    def evaluator_weak_kps(self, student_id, cutoff_ts, threshold=None):
        """Return evaluator-assessed weak KP id set (1-based)."""
        m = self.evaluator_mastery_estimate(student_id, cutoff_ts)
        thr = threshold if threshold is not None else WEAK_THRESHOLD
        return {i + 1 for i, v in enumerate(m) if v < thr}

    def evaluator_prereq_met(self, kp_id, student_id, cutoff_ts, threshold=None):
        """Check if all direct prerequisites of kp_id are mastered (for C4)."""
        m = self.evaluator_mastery_estimate(student_id, cutoff_ts)
        thr = threshold if threshold is not None else PREREQ_THRESHOLD
        for pre in self.prereq.get(kp_id, []):
            if m[pre - 1] < thr:
                return False
        return True

    # ------------------------ Compatibility Interface ------------------------
    def mastery_truth(self, student_id, cutoff_ts):
        """Alias: returns per-KP mastery via sigmoid(theta). For offline analysis/compat."""
        return self.evaluator_mastery_estimate(student_id, cutoff_ts)
