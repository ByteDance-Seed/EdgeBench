"""
K12 Math Knowledge Tracing & Personalized Recommendation — baseline inference script

Load trained model + scenarios.json, produce submission.json.
Strictly splits student history at the scenario cutoff_ts; never uses future answers.

Usage:
    python infer.py --scenarios ../../input_data/dev_scenarios.json \
                    --model ./models/baseline.pkl \
                    --output submission.json
"""
import argparse
import bisect
import json
import pickle
import time
from pathlib import Path


def predict_one_scenario(scenario, model):
    sid = scenario["student_id"]
    cutoff = int(scenario["timestamp"])
    qb = model["qb"]
    prereq = model["prereq"]
    stu_done = model["stu_done"]
    stu_ans = model["stu_ans"]  # [(ts, qid, is_correct, kps), ...]

    # 1) Split the student's answer history at cutoff_ts
    ans = stu_ans.get(sid, [])
    ts_list = [a[0] for a in ans]
    idx = bisect.bisect_right(ts_list, cutoff)
    ans_cut = ans[:idx]

    # 2) knowledge_state: Laplace-smoothed historical correct rate for the 50 KPs
    kp_cnt = [[0, 0] for _ in range(50)]
    for _, _, ic, kps in ans_cut:
        for k in kps:
            kp_cnt[k - 1][1] += 1
            kp_cnt[k - 1][0] += ic
    ks = [(c + 1) / (t + 2) for c, t in kp_cnt]

    # 2) next_question_probs: item-level avg + student KP bonus
    probs = {}
    for q in scenario["candidate_questions"]:
        item = qb.get(q, {})
        base = item.get("avg_correct", 0.5)
        kps = item.get("kps", [])
        if kps:
            stu_bar = sum(ks[k - 1] for k in kps) / len(kps)
            # weighted fusion: linear average of item base and student mastery center
            probs[q] = 0.5 * base + 0.5 * stu_bar
        else:
            probs[q] = base

    # 3) recommended_sequence: ZPD targets + prerequisites passed + difficulty gradient + avoid last 7 days
    zpd_kps = {i + 1 for i, m in enumerate(ks) if 0.25 <= m <= 0.65}
    if not zpd_kps:
        zpd_kps = {i + 1 for i, m in enumerate(ks) if m < 0.5}
    recent7 = {qid for ts, qid in stu_done.get(sid, [])
               if cutoff - 7 * 86400 <= ts <= cutoff}

    cand = []
    for q in scenario["recommendation_pool"]:
        if q in recent7:
            continue
        item = qb.get(q)
        if not item:
            continue
        kps_q = item["kps"]
        # prerequisites passed: all direct prerequisites of involved KPs have mastery >= 0.3
        prereq_ok = all(
            ks[p - 1] >= 0.3
            for kp in kps_q
            for p in prereq.get(kp, [])
        )
        if not prereq_ok:
            continue
        zpd_hits = sum(1 for k in kps_q if k in zpd_kps)
        if zpd_hits == 0:
            continue
        cand.append((q, zpd_hits, item["difficulty"]))
    # greedy: prioritize more ZPD hits, lower difficulty
    cand.sort(key=lambda x: (-x[1], x[2]))

    picked = []
    used = set()
    # satisfy C2 adjacent difficulty gap <=1: greedy selection
    for _ in range(30):
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
    # backfill
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
    parser.add_argument("--model", default="./models/baseline.pkl")
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
