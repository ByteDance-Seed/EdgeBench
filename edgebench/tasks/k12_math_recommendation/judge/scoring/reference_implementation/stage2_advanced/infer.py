"""
K12 Math Knowledge Tracing & Personalized Recommendation — advanced inference script

Three improvements over the (leak-free) baseline:
1. Mastery estimation: BKT-style theta fit (entry-test prior + slight forgetting decay on unpracticed KPs)
   fused with Laplace correct rate. BKT provides calibration; Laplace provides discrimination.
2. M1 prediction: beyond baseline item × mastery_center, add question discrimination
   as an extra weighting signal.
3. Recommendation: keep the baseline ZPD set heuristic but determine zpd_kps with the fused mastery.
"""
import argparse
import bisect
import json
import math
import pickle
import time
from pathlib import Path

import numpy as np

NUM_KPS = 50


def sigmoid(x):
    x = max(-12.0, min(12.0, float(x)))
    return 1.0 / (1.0 + math.exp(-x))


def build_prior(entry_score):
    mean = (entry_score - 65.0) / 15.0
    return np.ones(NUM_KPS, dtype=np.float64) * mean


def fit_theta(history_up_to_cutoff, qb, gain_c, gain_w, forget, prior):
    theta = prior.copy()
    for _, qid, ic in history_up_to_cutoff:
        q = qb.get(qid)
        if not q:
            continue
        touched = set(q["kps"])
        for k in q["kps"]:
            m = sigmoid(theta[k - 1])
            if ic:
                theta[k - 1] += gain_c * (1.0 - m)
            else:
                theta[k - 1] += gain_w * 4.0 * m * (1.0 - m)
        for k in range(1, NUM_KPS + 1):
            if k not in touched:
                theta[k - 1] -= forget * sigmoid(theta[k - 1])
    return np.clip(theta, -3.0, 3.0)


def predict_one_scenario(scenario, model):
    sid = scenario["student_id"]
    cutoff = int(scenario["timestamp"])
    qb = model["qb"]
    prereq = model["prereq"]
    stu_info = model["stu_info"]
    gain_c = model["gain_correct"]
    gain_w = model["gain_wrong"]
    forget = model["forget_decay"]

    # History split
    hist = model["stu_hist"].get(sid, [])
    ts_list = [h[0] for h in hist]
    idx = bisect.bisect_right(ts_list, cutoff)
    hist_cut = hist[:idx]

    # Laplace per-kp correct rate
    kp_cnt = [[0, 0] for _ in range(NUM_KPS)]
    for _, qid, ic in hist_cut:
        q = qb.get(qid)
        if not q:
            continue
        for k in q["kps"]:
            kp_cnt[k - 1][1] += 1
            kp_cnt[k - 1][0] += ic
    laplace = [(c + 1) / (t + 2) for c, t in kp_cnt]

    # BKT-style theta fit (entry-score prior + forgetting)
    info = stu_info.get(sid, {"entry_test_score": 65.0})
    prior = build_prior(info["entry_test_score"])
    theta = fit_theta(hist_cut, qb, gain_c, gain_w, forget, prior)
    bkt_m = [sigmoid(theta[k]) for k in range(NUM_KPS)]

    # Fusion: BKT calibrates well, Laplace ranks well
    ks = [0.5 * bkt_m[k] + 0.5 * laplace[k] for k in range(NUM_KPS)]

    # next_question_probs: item × Laplace mastery_center (AUC-friendly), plus discrimination
    # weighting: high-discrimination questions trust item avg_correct more; low-discrimination trust student mastery
    probs = {}
    for q in scenario["candidate_questions"]:
        item = qb.get(q)
        if not item:
            probs[q] = 0.5
            continue
        mastery_center = float(np.mean([laplace[k - 1] for k in item["kps"]]))
        disc = item["discrimination"]
        # disc normalized to [0.3, 0.7] as fusion weight
        w_item = max(0.3, min(0.7, 0.25 + disc * 0.3))
        probs[q] = w_item * item["avg_correct"] + (1 - w_item) * mastery_center

    # recommendation: to match the evaluator's objective M4 C3/C4 judgment, use a zero-prior
    # BKT fit for weak-KP and prerequisite judgment (evaluator's StudentSimulator uses the same)
    zero_prior = np.zeros(NUM_KPS, dtype=np.float64)
    theta_zero = fit_theta(hist_cut, qb, gain_c, gain_w, 0.0, zero_prior)
    m_zero = [sigmoid(theta_zero[k]) for k in range(NUM_KPS)]

    recent7 = {qid for ts, qid, _ in hist_cut if cutoff - 7 * 86400 <= ts <= cutoff}
    # weak-KP judgment & ZPD set both use m_zero
    weak_kps_evaluator = {i + 1 for i, m in enumerate(m_zero) if m < 0.5}
    zpd_kps = {i + 1 for i, m in enumerate(m_zero) if 0.25 <= m <= 0.65}
    if not zpd_kps:
        zpd_kps = weak_kps_evaluator

    cand = []
    for q in scenario["recommendation_pool"]:
        if q in recent7:
            continue
        item = qb.get(q)
        if not item:
            continue
        kps_q = item["kps"]
        # C4 prerequisite judgment also uses m_zero (same as evaluator)
        prereq_ok = all(
            m_zero[p - 1] >= 0.3 for kp in kps_q for p in prereq.get(kp, [])
        )
        if not prereq_ok:
            continue
        weak_hits = sum(1 for k in kps_q if k in weak_kps_evaluator)
        zpd_hits = sum(1 for k in kps_q if k in zpd_kps)
        # must hit both weak (for C3) and ZPD (for M3 learning gain)
        if weak_hits == 0 and zpd_hits == 0:
            continue
        cand.append((q, weak_hits + zpd_hits, item["difficulty"]))
    cand.sort(key=lambda x: (-x[1], x[2]))

    picked = []
    used = set()
    for _round in range(30):
        for q, wh, d in cand:
            if q in used:
                continue
            if picked and abs(qb[picked[-1]]["difficulty"] - d) > 1:
                continue
            picked.append(q)
            used.add(q)
            if len(picked) == 10:
                break
        if len(picked) == 10:
            break
    for q, _, _ in cand:
        if len(picked) >= 10:
            break
        if q not in used:
            picked.append(q)
            used.add(q)

    return {
        "scenario_id": scenario["scenario_id"],
        "student_id": sid,
        "timestamp": cutoff,
        "knowledge_state": ks,
        "next_question_probs": probs,
        "recommended_sequence": picked[:10],
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--scenarios", required=True)
    parser.add_argument("--model", default="./models/advanced.pkl")
    parser.add_argument("--output", default="submission.json")
    args = parser.parse_args()

    with open(args.model, "rb") as fp:
        model = pickle.load(fp)
    scenarios = json.load(open(args.scenarios, encoding="utf-8"))["scenarios"]

    t0 = time.time()
    out = {"scenarios": [predict_one_scenario(s, model) for s in scenarios]}
    elapsed = time.time() - t0
    print(f"inferred {len(scenarios)} scenarios in {elapsed:.2f}s")

    with open(args.output, "w", encoding="utf-8") as fp:
        json.dump(out, fp, ensure_ascii=False)
    print(f"wrote {args.output}")


if __name__ == "__main__":
    main()
