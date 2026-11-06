"""
Main evaluation script (evaluator-side, not distributed to Agent).

Key design:
- All metrics iterate over all 100 official test scenarios; missing scenarios count as zero,
  preventing selective submission to game the score.
- M2 uses knowledge_truth derived from data_generator true theta,
  scored as 50/50 per-student ECE + per-student Spearman rank correlation.
- M4 C3/C4 uses StudentSimulator independent estimates from student history, not Agent-reported
  knowledge_state; C5 checks both no-duplicates and all-from-recommendation_pool.
- M3 uses StudentSimulator.simulate to model student ability updates after Agent recommendations,
  evaluating expected score on predefined post-test questions vs random baseline.

Usage:
    python evaluate.py \
        --submission path/to/submission.json \
        --ground_truth test_ground_truth.json \
        --scenarios test_scenarios.json \
        --logs ../input_data/answering_logs.csv \
        --questions ../input_data/question_bank.csv \
        --kp_graph ../input_data/knowledge_graph.csv \
        --infer_time_seconds 187.5 \
        --output report.json
"""
import argparse
import csv
import json
import math
from pathlib import Path
from collections import defaultdict

import numpy as np
from sklearn.metrics import roc_auc_score
from scipy.stats import spearmanr

try:
    from student_simulator import StudentSimulator
except ImportError:
    from .student_simulator import StudentSimulator

WEIGHTS = {"M1": 0.35, "M2": 0.30, "M3": 0.30, "M4": 0.04, "M5": 0.01}
NUM_KPS = 50

# Tightened metric parameters
M1_AUC_FLOOR = 0.65          # AUC below this floor scores 0 (was 0.5, tightened to 0.6 then 0.65)
M1_AUC_CEILING = 0.90        # AUC above this ceiling scores full marks
M2_ECE_FULL = 0.02           # ECE <= 0.02 -> full marks
M2_ECE_ZERO = 0.10           # ECE >= 0.10 -> 0 (was 0.25 -> 0.15 -> 0.10)
M2_SPEAR_FULL = 0.60         # Spearman >= 0.6 -> full marks (was 1.0 -> 0.5 -> 0.6)
# M3 piecewise: anchors shifted to restrain small-gain feedback from short hill-climbing
M3_ANCHORS = [(0.0, 0.0), (0.005, 4.0), (0.012, 15.0),
              (0.025, 45.0), (0.040, 75.0), (0.060, 100.0)]


def m3_piecewise(gain: float) -> float:
    """M3 piecewise: linear interpolation with preset anchors, [0, 0.040] range more sensitive."""
    if gain <= M3_ANCHORS[0][0]:
        return 0.0
    if gain >= M3_ANCHORS[-1][0]:
        return 100.0
    for (g0, s0), (g1, s1) in zip(M3_ANCHORS[:-1], M3_ANCHORS[1:]):
        if g0 <= gain <= g1:
            t = (gain - g0) / max(g1 - g0, 1e-9)
            return s0 + t * (s1 - s0)
    return 0.0


def compute_m1(submission_by_id, ground_truth, scenarios_meta):
    """M1: Next-question answer prediction AUC (macro-average over all official scenarios).

    - Evaluation computes AUC on all questions with ground truth labels.
    - Agent must provide probabilities for all 20 candidate questions;
      missing candidates treated as 0.5 (random prediction, penalizing selective submission).
    - Missing entire scenario: per-scenario AUC = 0.5.
    """
    sc_meta_by_id = {s["scenario_id"]: s for s in scenarios_meta["scenarios"]}
    aucs_per_scenario = []
    for gt in ground_truth:
        sid = gt["scenario_id"]
        meta = sc_meta_by_id.get(sid, {})
        candidate_set = set(meta.get("candidate_questions", []))
        sc = submission_by_id.get(sid)
        truths = gt["next_question_truth"]
        if not sc:
            aucs_per_scenario.append(0.5)
            continue
        probs = sc.get("next_question_probs") or {}
        y_true, y_pred = [], []
        for qid, t in truths.items():
            if qid not in candidate_set:
                continue
            y_true.append(int(t))
            # missing submission -> 0.5; submitted probabilities clipped to [0,1]
            if qid in probs:
                y_pred.append(max(0.0, min(1.0, float(probs[qid]))))
            else:
                y_pred.append(0.5)
        if len(set(y_true)) < 2 or len(y_true) < 2:
            aucs_per_scenario.append(0.5)
            continue
        try:
            aucs_per_scenario.append(float(roc_auc_score(y_true, y_pred)))
        except ValueError:
            aucs_per_scenario.append(0.5)
    auc = float(np.mean(aucs_per_scenario)) if aucs_per_scenario else 0.5
    # Tightened M1: AUC >= 0.6 starts scoring, 0.9 full marks (was 0.5/0.9)
    score = 100.0 * max(0.0, min(1.0,
                                  (auc - M1_AUC_FLOOR) / max(M1_AUC_CEILING - M1_AUC_FLOOR, 1e-9)))
    # Extra report: ratio of scenarios with all 20 questions covered
    fully_covered = 0
    for gt in ground_truth:
        sid = gt["scenario_id"]
        meta = sc_meta_by_id.get(sid, {})
        sc = submission_by_id.get(sid)
        if not sc:
            continue
        probs = sc.get("next_question_probs") or {}
        candidates = meta.get("candidate_questions", [])
        if all(q in probs for q in candidates):
            fully_covered += 1
    return {
        "auc_macro": auc,
        "n_scenarios_total": len(ground_truth),
        "n_scenarios_submitted": sum(1 for g in ground_truth if g["scenario_id"] in submission_by_id),
        "n_scenarios_fully_covered_20": fully_covered,
        "score": float(score),
    }


def _per_student_ece(preds, trues, n_bins=10):
    bins = np.linspace(0, 1, n_bins + 1)
    preds = np.asarray(preds)
    trues = np.asarray(trues)
    ece = 0.0
    n = len(preds)
    for lo, hi in zip(bins[:-1], bins[1:]):
        mask = (preds >= lo) & (preds < hi)
        if hi == 1.0:
            mask |= preds == 1.0
        if mask.sum() == 0:
            continue
        conf = preds[mask].mean()
        acc = trues[mask].mean()
        ece += (mask.sum() / n) * abs(conf - acc)
    return float(ece)


def compute_m2(submission_by_id, ground_truth):
    """M2: Knowledge mastery probability calibration.

    Over all official scenarios: missing = ECE=0.25 (worst) + Spearman=0.
    Uses per-student ECE + per-student Spearman rank correlation weighted 50 pts each.
    Ground truth from data_generator true theta snapshot (sigmoid(theta_at_cutoff)).
    """
    per_student_ece, per_student_spear = [], []
    for gt in ground_truth:
        sid = gt["scenario_id"]
        sc = submission_by_id.get(sid)
        kt = gt.get("knowledge_truth", [])
        if len(kt) != NUM_KPS:
            continue
        if not sc:
            per_student_ece.append(0.25)
            per_student_spear.append(0.0)
            continue
        ks = sc.get("knowledge_state") or []
        if len(ks) != NUM_KPS:
            per_student_ece.append(0.25)
            per_student_spear.append(0.0)
            continue
        preds = np.clip(np.asarray(ks, dtype=float), 0.0, 1.0)
        trues = np.asarray(kt, dtype=float)
        per_student_ece.append(_per_student_ece(preds, trues))
        if float(np.std(preds)) < 1e-9 or float(np.std(trues)) < 1e-9:
            rho = 0.0
        else:
            rho, _ = spearmanr(preds, trues)
            if rho is None or np.isnan(rho):
                rho = 0.0
        per_student_spear.append(max(0.0, float(rho)))

    if not per_student_ece:
        return {"ece_per_student_mean": 0.25, "spearman_per_student_mean": 0.0,
                "ece_component": 0.0, "spearman_component": 0.0, "score": 0.0}

    ece_mean = float(np.mean(per_student_ece))
    spear_mean = float(np.mean(per_student_spear))
    # Tightened ECE scale: <= 0.02 full marks; >= 0.15 zero (was >= 0.25)
    if ece_mean <= M2_ECE_FULL:
        ece_component = 100.0
    elif ece_mean >= M2_ECE_ZERO:
        ece_component = 0.0
    else:
        ece_component = 100.0 * (M2_ECE_ZERO - ece_mean) / (M2_ECE_ZERO - M2_ECE_FULL)
    # Tightened Spearman scale: full-marks threshold 1.0 to 0.5 (was linear spear*100)
    spear_component = 100.0 * max(0.0, min(1.0, spear_mean / M2_SPEAR_FULL))
    score = 0.5 * ece_component + 0.5 * spear_component
    return {
        "ece_per_student_mean": ece_mean,
        "spearman_per_student_mean": spear_mean,
        "ece_component": ece_component,
        "spearman_component": spear_component,
        "n_scenarios_total": len(ground_truth),
        "score": float(score),
    }


def compute_m3(submission_by_id, ground_truth, scenarios_meta, simulator):
    """M3: Recommendation sequence learning gain (all scenarios; missing = gain 0)."""
    rng = np.random.default_rng(0)
    sc_meta_by_id = {s["scenario_id"]: s for s in scenarios_meta["scenarios"]}
    agent_scores, random_scores = [], []
    for gt in ground_truth:
        sid = gt["scenario_id"]
        meta = sc_meta_by_id.get(sid)
        if not meta:
            continue
        post = gt.get("post_test_question_ids") or meta.get("post_test_question_ids", [])
        pool = meta.get("recommendation_pool", [])
        if not post:
            continue

        sub = submission_by_id.get(sid)
        if not sub:
            # missing scenario: agent_post = random_post -> gain = 0
            rand_runs = []
            for _ in range(5):
                rand = rng.choice(pool, size=10, replace=False).tolist()
                rand_runs.append(simulator.simulate(
                    student_id=meta["student_id"],
                    history_cutoff_ts=meta["timestamp"],
                    recommended_question_ids=rand,
                    post_test_question_ids=post,
                ))
            base = float(np.mean(rand_runs))
            agent_scores.append(base)
            random_scores.append(base)
            continue

        rec = (sub.get("recommended_sequence") or [])[:10]
        if not rec:
            rand_runs = []
            for _ in range(5):
                rand = rng.choice(pool, size=10, replace=False).tolist()
                rand_runs.append(simulator.simulate(
                    student_id=meta["student_id"],
                    history_cutoff_ts=meta["timestamp"],
                    recommended_question_ids=rand,
                    post_test_question_ids=post,
                ))
            base = float(np.mean(rand_runs))
            agent_scores.append(base)
            random_scores.append(base)
            continue

        agent_sc = simulator.simulate(
            student_id=meta["student_id"],
            history_cutoff_ts=meta["timestamp"],
            recommended_question_ids=rec,
            post_test_question_ids=post,
        )
        rand_runs = []
        for _ in range(5):
            rand = rng.choice(pool, size=10, replace=False).tolist()
            rand_runs.append(simulator.simulate(
                student_id=meta["student_id"],
                history_cutoff_ts=meta["timestamp"],
                recommended_question_ids=rand,
                post_test_question_ids=post,
            ))
        agent_scores.append(agent_sc)
        random_scores.append(float(np.mean(rand_runs)))

    gain = float(np.mean(agent_scores) - np.mean(random_scores)) if agent_scores else 0.0
    # Piecewise: clear feedback for common 0.005~0.040 range
    # Anchors: gain=0->0; 0.005->10; 0.012->30; 0.025->65; 0.040->90; 0.060->100
    # - Simple ZPD heuristic gain ~0.005 -> 10 pts
    # - BKT+aligned gain ~0.012 -> 30 pts
    # - Target KP recognizer gain ~0.025 -> 65 pts
    # - Oracle (knows truth) gain ~0.040 -> 90 pts
    # This makes hill-climbing gain produce significant total score changes, improving M3 discrimination.
    score = m3_piecewise(gain)
    return {
        "agent_mean": float(np.mean(agent_scores)) if agent_scores else 0.0,
        "random_mean": float(np.mean(random_scores)) if random_scores else 0.0,
        "gain": gain,
        "scoring": "piecewise",
        "anchors": M3_ANCHORS,
        "n_scenarios_total": len(ground_truth),
        "score": score,
    }


def compute_m4(submission_by_id, ground_truth, scenarios_meta, simulator,
               logs_path, questions_path):
    """M4: Recommendation constraint satisfaction rate (all scenarios; missing = 0/5).

    Five constraints:
        C1 Do not recommend questions done in past 7 days
        C2 Difficulty gap between adjacent questions <= 1
        C3 Cover >= 3 evaluator-assessed weak knowledge points
        C4 Direct prerequisites of recommended KPs have evaluator-estimated mastery >= 0.3
        C5 Sequence length exactly 10, no duplicates, all from scenario recommendation_pool
    """
    sc_meta_by_id = {s["scenario_id"]: s for s in scenarios_meta["scenarios"]}

    questions = {}
    with open(questions_path, newline="", encoding="utf-8") as fp:
        for r in csv.DictReader(fp):
            questions[r["question_id"]] = {
                "difficulty": int(r["difficulty_level"]),
                "kps": [int(x) for x in r["knowledge_point_ids"].split(";")],
            }

    recent_done = defaultdict(list)
    with open(logs_path, newline="", encoding="utf-8") as fp:
        for r in csv.DictReader(fp):
            recent_done[r["student_id"]].append((int(r["timestamp"]), r["question_id"]))
    for sid in recent_done:
        recent_done[sid].sort()

    def done_in_7days(sid, cutoff_ts):
        lo = cutoff_ts - 7 * 86400
        return {qid for ts, qid in recent_done.get(sid, []) if lo <= ts <= cutoff_ts}

    per_scenario = []
    per_constraint_counts = {f"C{i}": 0 for i in range(1, 6)}
    for gt in ground_truth:
        sid = gt["scenario_id"]
        meta = sc_meta_by_id.get(sid)
        if not meta:
            continue
        sub = submission_by_id.get(sid)
        rec_raw = (sub.get("recommended_sequence") if sub else None) or []
        rec = rec_raw[:10]  # take first 10 for C1~C4 evaluation
        flags = {"C1": 0, "C2": 0, "C3": 0, "C4": 0, "C5": 0}

        if not rec:
            # missing scenario or recommendation -> 0/5
            per_scenario.append(0.0)
            continue

        eval_mastery = simulator.evaluator_mastery_estimate(
            meta["student_id"], meta["timestamp"]
        )
        eval_weak_kps = {i + 1 for i, v in enumerate(eval_mastery) if v < 0.5}
        pool_set = set(meta.get("recommendation_pool", []))

        # C1
        recent = done_in_7days(meta["student_id"], meta["timestamp"])
        flags["C1"] = 0 if any(q in recent for q in rec) else 1
        # C2
        diffs = [questions.get(q, {}).get("difficulty", 3) for q in rec]
        flags["C2"] = 0 if any(abs(diffs[i + 1] - diffs[i]) > 1
                                for i in range(len(diffs) - 1)) else 1
        # C3
        covered = set()
        for q in rec:
            for kp in questions.get(q, {}).get("kps", []):
                if kp in eval_weak_kps:
                    covered.add(kp)
        flags["C3"] = 1 if len(covered) >= 3 else 0
        # C4
        c4 = 1
        for q in rec:
            for kp in questions.get(q, {}).get("kps", []):
                if not simulator.evaluator_prereq_met(
                    kp, meta["student_id"], meta["timestamp"]
                ):
                    c4 = 0
                    break
            if c4 == 0:
                break
        flags["C4"] = c4
        # C5: length exactly 10 + no duplicates + all from pool
        # Note: use rec_raw (original) not rec (truncated), preventing 11+ items bypassing length check
        if len(rec_raw) != 10:
            flags["C5"] = 0
        elif len(set(rec_raw)) != 10:
            flags["C5"] = 0
        elif any(q not in pool_set for q in rec_raw):
            flags["C5"] = 0
        else:
            flags["C5"] = 1

        for k, v in flags.items():
            per_constraint_counts[k] += v
        per_scenario.append(sum(flags.values()) / 5.0)

    n = max(1, len(per_scenario))
    satisfied_rate = float(np.mean(per_scenario)) if per_scenario else 0.0
    return {
        "per_scenario_mean": satisfied_rate,
        "per_constraint_pass_rate": {k: v / n for k, v in per_constraint_counts.items()},
        "n_scenarios_total": len(ground_truth),
        "score": 100.0 * satisfied_rate,
    }


def compute_m5(infer_time_seconds):
    if infer_time_seconds <= 200:
        score = 100.0
    elif infer_time_seconds >= 400:
        score = 0.0
    else:
        score = 100.0 - (infer_time_seconds - 200) / 10.0
    return {"infer_time_seconds": infer_time_seconds, "score": max(0.0, float(score))}


# Required deliverables for Agent submission
REQUIRED_DELIVERABLES = ["train.py", "infer.py", "requirements.txt", "README.md"]


def check_deliverables(deliverables_dir):
    """Check if Agent submission dir contains all required deliverables. Returns dict + completeness."""
    if not deliverables_dir:
        return {"checked": False, "missing": [], "present": []}
    root = Path(deliverables_dir)
    present, missing = [], []
    for name in REQUIRED_DELIVERABLES:
        if (root / name).is_file():
            present.append(name)
        else:
            missing.append(name)
    return {
        "checked": True,
        "deliverables_dir": str(root),
        "required": REQUIRED_DELIVERABLES,
        "present": present,
        "missing": missing,
        "complete": len(missing) == 0,
    }


def run_and_time_inference(infer_cmd, output_path):
    """Run Agent infer.py and time it (closed-loop mode, higher M5 reliability).

    infer_cmd: string template with {scenarios} and {output} placeholders.
               e.g.: "python infer.py --scenarios {scenarios} --output {output}"
    output_path: expected path for infer.py to write submission.json.
    Returns wall-clock time (seconds).
    """
    import subprocess
    import time as _time
    if "{output}" not in infer_cmd:
        raise SystemExit("--infer_cmd must contain {output} placeholder")
    cmd = infer_cmd.replace("{output}", output_path)
    t0 = _time.time()
    proc = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=600)
    elapsed = _time.time() - t0
    if proc.returncode != 0:
        print(f"[infer failed] return={proc.returncode}\n--- stderr ---\n{proc.stderr}")
    return elapsed


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--submission", help="Path to submission.json (omittable with --infer_cmd)")
    parser.add_argument("--ground_truth", required=True)
    parser.add_argument("--scenarios", required=True)
    parser.add_argument("--logs", required=True)
    parser.add_argument("--questions", required=True)
    parser.add_argument("--kp_graph", required=True)
    parser.add_argument("--infer_time_seconds", type=float, default=None,
                        help="Directly pass inference wall-clock time (compat); mutually exclusive with --infer_cmd")
    parser.add_argument("--infer_cmd", default=None,
                        help='Closed-loop timing: eval script runs infer.py and measures time.'
                             'Command template must contain {output} placeholder, e.g. '
                             '"python infer.py --scenarios <path> --output {output}"')
    parser.add_argument("--deliverables_dir", default=None,
                        help="Agent submission root dir for validating train.py / requirements.txt / README.md "
                             "and other required deliverables. Missing items flagged in deliverables_completeness, "
                             "with -5 M5 penalty per missing item.")
    parser.add_argument("--output", default="report.json")
    args = parser.parse_args()

    # Closed-loop timing mode
    if args.infer_cmd:
        if args.submission is None:
            args.submission = "/tmp/_eval_submission.json"
        t = run_and_time_inference(args.infer_cmd, args.submission)
        infer_time = t
        print(f"[timing] infer.py wall-clock {t:.2f}s")
    elif args.infer_time_seconds is not None and args.submission is not None:
        infer_time = float(args.infer_time_seconds)
    else:
        raise SystemExit("Must provide --infer_cmd or (--submission + --infer_time_seconds)")

    submission = json.load(open(args.submission, encoding="utf-8"))
    ground_truth = json.load(open(args.ground_truth, encoding="utf-8"))["ground_truth"]
    scenarios = json.load(open(args.scenarios, encoding="utf-8"))

    submission_by_id = {s["scenario_id"]: s for s in submission["scenarios"]}
    n_total = len(ground_truth)
    n_submit = len(submission_by_id)
    n_match = sum(1 for g in ground_truth if g["scenario_id"] in submission_by_id)

    simulator = StudentSimulator(
        logs_path=args.logs,
        questions_path=args.questions,
        kp_graph_path=args.kp_graph,
        seed=42,
    )

    m1 = compute_m1(submission_by_id, ground_truth, scenarios)
    m2 = compute_m2(submission_by_id, ground_truth)
    m3 = compute_m3(submission_by_id, ground_truth, scenarios, simulator)
    m4 = compute_m4(submission_by_id, ground_truth, scenarios, simulator,
                    args.logs, args.questions)
    m5 = compute_m5(infer_time)

    # Deliverables completeness check
    deliverables = check_deliverables(args.deliverables_dir)
    if deliverables.get("checked"):
        missing_count = len(deliverables["missing"])
        # -5 M5 points per missing deliverable
        m5["score"] = max(0.0, m5["score"] - 5.0 * missing_count)
        m5["deliverables_penalty"] = -5.0 * missing_count
        m5["deliverables_missing"] = deliverables["missing"]

    total = (WEIGHTS["M1"] * m1["score"] + WEIGHTS["M2"] * m2["score"]
             + WEIGHTS["M3"] * m3["score"] + WEIGHTS["M4"] * m4["score"]
             + WEIGHTS["M5"] * m5["score"])

    report = {
        "weights": WEIGHTS,
        "scenarios_total": n_total,
        "scenarios_submitted": n_submit,
        "scenarios_matched": n_match,
        "deliverables_completeness": deliverables,
        "M1_next_question_auc": m1,
        "M2_knowledge_calibration": m2,
        "M3_learning_gain": m3,
        "M4_constraint_satisfaction": m4,
        "M5_inference_efficiency": m5,
        "total_score": round(float(total), 3),
    }
    with open(args.output, "w", encoding="utf-8") as fp:
        json.dump(report, fp, ensure_ascii=False, indent=2)
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return report


if __name__ == "__main__":
    main()
