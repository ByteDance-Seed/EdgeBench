#!/usr/bin/env python3
# Structured result for rust_multicrate_reconstruction.
# Lines between the BEGIN/END v1 markers are v1's inline `python3 -c '...'` from judge.eval_cmd,
# byte-for-byte. The only addition is at the bottom: write the score-only contract file
# /opt/sforge/result.json (score = v1 total_score, valid = SCORE_STATUS == "OK";
# v1's top-level pass_rate is kept under metrics.pass_rate, informational only).
# ---- BEGIN v1 ----
import json,pathlib,re
PASSED="PASSED"; FAILED="FAILED"; ERROR="ERROR"
txt=pathlib.Path("/tmp/cas_score.out").read_text(errors="replace") if pathlib.Path("/tmp/cas_score.out").exists() else ""
score_json=pathlib.Path("/tmp/cas_eval/run/score-results.json")
def grab(pattern, default=None):
    m=re.search(pattern, txt, re.M)
    return m.group(1) if m else default
score_s=grab(r"^SCORE=([0-9]+(?:\.[0-9]+)?)", "0")
status=grab(r"^SCORE_STATUS=(\S+)", "MISSING")
rawp_s=grab(r"^RAW_PASSED=(\d+)", "0")
rawt_s=grab(r"^RAW_TOTAL=(\d+)", "0")
try:
    score=float(score_s)
except Exception:
    score=0.0
raw_passed=int(rawp_s or 0)
raw_total=int(rawt_s or 0)
score_data={}
if score_json.exists():
    try:
        score_data=json.loads(score_json.read_text(errors="replace"))
    except Exception:
        score_data={}
if score_data:
    score=float(score_data.get("total_score", score))
    status=str(score_data.get("score_status", status))
    raw_passed=int(score_data.get("raw_passed", raw_passed) or 0)
    raw_total=int(score_data.get("raw_total", raw_total) or 0)
pass_rate=(raw_passed/raw_total) if raw_total else (1.0 if score>0 and status=="OK" else 0.0)
ok=(status=="OK")
summary=f"score={score:.4f}; status={status}; raw_passed={raw_passed}; raw_total={raw_total}; pass_rate={pass_rate:.6f}"
def detail_status(passed,total,crate_status=None):
    if crate_status in {"ERROR","TIMEOUT","NO_TESTS"}:
        return ERROR
    return PASSED if total and passed==total else FAILED
def pct(passed,total):
    return (100.0*passed/total) if total else 0.0
details=[
    {
        "name":"overall_score",
        "status":PASSED if ok and score>0 else (FAILED if status in {"OK","FAIL","FAILED","WA"} else ERROR),
        "score":score,
        "weight":1.0,
        "message":summary,
    },
    {
        "name":"raw_test_pass_rate",
        "status":PASSED if raw_total and raw_passed==raw_total else FAILED,
        "score":pct(raw_passed, raw_total),
        "weight":1.0,
        "message":f"raw_passed={raw_passed}; raw_total={raw_total}; pass_rate={pass_rate:.6f}",
    },
]
layer_metrics=[]
for layer in score_data.get("layers", []):
    passed=int(layer.get("passed", 0) or 0)
    total=int(layer.get("total", 0) or 0)
    lname=str(layer.get("layer", "layer"))
    lstatus=str(layer.get("status", "UNKNOWN"))
    lscore=float(layer.get("score", 0.0) or 0.0)
    weight=float(layer.get("weight", 0.0) or 0.0)
    crates=", ".join(layer.get("crates", []))
    layer_metrics.append({"layer": lname, "passed": passed, "total": total, "score": lscore, "status": lstatus, "crates": layer.get("crates", [])})
    details.append({
        "name":f"layer_{lname}",
        "status":detail_status(passed,total,lstatus),
        "score":lscore,
        "weight":weight,
        "message":f"status={lstatus}; passed={passed}; total={total}; crates={crates}",
    })
crate_metrics=[]
for crate in score_data.get("crates", []):
    cname=str(crate.get("crate_name", crate.get("package_name", "crate")))
    passed=int(crate.get("passed", 0) or 0)
    total=int(crate.get("total", 0) or 0)
    cstatus=str(crate.get("status", "UNKNOWN"))
    public_passed=int(crate.get("public_passed", 0) or 0)
    public_failed=int(crate.get("public_failed", 0) or 0)
    hidden_passed=int(crate.get("hidden_passed", 0) or 0)
    hidden_failed=int(crate.get("hidden_failed", 0) or 0)
    crate_metrics.append({
        "crate": cname, "status": cstatus, "passed": passed, "total": total,
        "public_passed": public_passed, "public_failed": public_failed,
        "hidden_passed": hidden_passed, "hidden_failed": hidden_failed,
    })
    details.append({
        "name":f"crate_{cname}",
        "status":detail_status(passed,total,cstatus),
        "score":pct(passed,total),
        "weight":0.0,
        "message":f"status={cstatus}; passed={passed}; total={total}; public_passed={public_passed}; public_failed={public_failed}; hidden_passed={hidden_passed}; hidden_failed={hidden_failed}",
    })
score_lines=[line for line in txt.splitlines() if line.startswith(("SCORE=","SCORE_STATUS=","RAW_PASSED=","RAW_TOTAL=","WEIGHTED_PASSED=","WEIGHTED_TOTAL="))]
result={
    "valid": bool(ok),
    "score": score,
    "pass_rate": pass_rate,
    "summary": summary,
    "metrics": {
        "score_status": status,
        "raw_passed": raw_passed,
        "raw_total": raw_total,
        "weighted_passed": score_data.get("weighted_passed", score),
        "weighted_total": score_data.get("weighted_total", 100.0),
        "total_duration_sec": score_data.get("total_duration_sec"),
        "layers": layer_metrics,
        "crates": crate_metrics,
        "score_lines": score_lines,
    },
    "details": details,
}
print(">>>>> Start Structured Result")
print(json.dumps(result, indent=2, sort_keys=True))
print(">>>>> End Structured Result")
# ---- END v1 ----
import os
os.makedirs("/opt/sforge", exist_ok=True)
contract = {
    "score": result["score"],
    "valid": result["valid"],
    "summary": result["summary"],
    "details": result["details"],
    "metrics": dict(result["metrics"], pass_rate=result["pass_rate"]),
}
with open("/opt/sforge/result.json", "w") as f:
    json.dump(contract, f, indent=2, sort_keys=True)
