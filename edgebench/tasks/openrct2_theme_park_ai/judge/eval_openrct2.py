#!/usr/bin/env python3
"""SE-Bench wrapper for OpenRCT2 plugin eval.

Runs the judge-owned OpenRCT2 evaluator and converts its per-scenario score and
safe diagnostics into score_sum output. The submitted plugin's stdout remains
untrusted; it is only surfaced as diagnostic text after the judge has prefixed
and sampled it.
"""
import os
import re
import subprocess
import sys

WORK_DIR = "/home/workspace/openrct2"
PLUGIN_PATH = os.path.join(WORK_DIR, "my_plugin.js")
ORIG_EVAL = "/judge/openrct2_original_eval.py"
SCENARIOS_DIR = os.path.join(WORK_DIR, "scenarios")
TIMEOUT_PER_SCENARIO = int(os.environ.get("OPENRCT2_TIMEOUT", "120"))
TOTAL_TIMEOUT = 1800
DIAGNOSTIC_LIMIT = 900
CASE_PASS_SCORE = int(os.environ.get("SEBENCH_OPENRCT2_CASE_PASS_SCORE", "5000"))
ANSI_RE = re.compile(r"\x1b\[[0-9;]*[A-Za-z]")
SCENARIO_RE = re.compile(r"\[(scenario_\w+\.park)\]\s+(.*)")
BLOCKING_PROGRESS_TAGS = {
    "opgate",
    "expansion_missing",
    "expansion_open_failed",
    "expansion_open_unsustained",
}


def clean_line(line):
    line = ANSI_RE.sub("", line).strip()
    return re.sub(r"\s+", " ", line)


def shorten(text, limit):
    if len(text) <= limit:
        return text
    return text[: max(0, limit - 15)].rstrip() + " ...[truncated]"


def clean_plugin_log(line):
    line = clean_line(line)
    line = re.sub(r"^(ERROR|WARNING|WARN)\[[^\]]+\]:\s*", r"\1: ", line)
    return shorten(line, 180)


def extract_feedback(out):
    feedback = {}
    sample_scenario = None

    for raw in out.splitlines():
        line = clean_line(raw)
        if not line:
            continue

        m = SCENARIO_RE.match(line)
        if m:
            scenario, rest = m.groups()
            info = feedback.setdefault(scenario, {})
            sample_scenario = None

            if rest.startswith("judge diagnostics:"):
                info["diagnostics"] = rest[len("judge diagnostics:"):].strip()
            elif rest.startswith("judge maxima:"):
                info["maxima"] = rest[len("judge maxima:"):].strip()
            elif rest.startswith("judge expansion:"):
                info["expansion"] = rest[len("judge expansion:"):].strip()
            elif rest.startswith("scoring:"):
                info["scoring"] = rest[len("scoring:"):].strip()
            elif rest.startswith("final company value ="):
                info["final_value"] = rest.split("=", 1)[1].strip()
            elif rest.startswith("untrusted plugin log sample:"):
                sample_scenario = scenario
            continue

        if sample_scenario:
            entry = clean_plugin_log(line)
            if not entry:
                continue
            if "api.github.com/repos/OpenRCT2/OpenRCT2/releases/latest" in entry:
                continue
            useful = (
                "ERROR" in entry
                or "WARN" in entry
                or "not found" in entry
                or "Can't " in entry
                or "Unavailable" in entry
                or "failed" in entry.lower()
                or "invalid" in entry.lower()
            )
            if not useful:
                continue
            errors = feedback.setdefault(sample_scenario, {}).setdefault("errors", [])
            if entry not in errors and len(errors) < 3:
                errors.append(entry)

    return feedback


def case_tags(info, status):
    tags = []
    scoring = (info.get("scoring") or "").lower()

    if "operation gate failed:" in scoring:
        tags.append("opgate")
        reason = scoring.split("operation gate failed:", 1)[1]
        reason_tags = set(t for t in re.split(r"[^a-z]+", reason) if t)
        for tag in ("rides", "openrides", "staff"):
            if tag in reason_tags:
                tags.append(tag)
    elif "quality gate failed" in scoring:
        tags.append("opgate")

    if "expansion created but not open" in scoring:
        tags.append("expansion_created")
        tags.append("expansion_open_failed")
    elif "expansion open but not sustained" in scoring:
        tags.append("expansion_open_unsustained")
    elif "expansion missing" in scoring:
        tags.append("expansion_missing")

    maxima = (info.get("maxima") or "").lower()
    m = re.search(r"\bactionerrors\s+([0-9]+)\b", maxima)
    if (m and int(m.group(1)) > 0) or info.get("errors"):
        tags.append("actionerrors")

    if status != "OK" and not tags:
        tags.append("lowvalue")

    return tags


def make_case_id(index, tags):
    base = f"{index:04d}"
    if not tags:
        return base
    return base + "_" + "_".join(tags)


def format_case_message(name, tags):
    if tags:
        return f"{name}; feedback categories: " + ", ".join(tags)
    return f"{name}; feedback categories: score"


def zero_case_tag(reason):
    reason = reason.lower()
    if "anti-cheat" in reason or "anti-hack" in reason:
        return "anticheat"
    if "missing" in reason:
        return "missingplugin"
    if "timed out" in reason or "timeout" in reason:
        return "timeout"
    if "no per-scenario" in reason:
        return "noscores"
    return "judgeerror"


def format_case_message_verbose(name, norm_f, feedback):
    info = feedback.get(name, {})
    parts = [f"{name} norm={norm_f:.4f}"]

    diagnostics = info.get("diagnostics")
    if diagnostics:
        diagnostics = diagnostics.replace("companyValue", "value")
        parts.append(diagnostics)
    elif info.get("final_value"):
        parts.append("final value " + info["final_value"])

    if info.get("maxima"):
        parts.append("max " + info["maxima"])
    if info.get("scoring"):
        parts.append("scoring " + info["scoring"])
    if info.get("errors"):
        parts.append("first action errors: " + " | ".join(info["errors"]))

    return shorten("; ".join(parts), DIAGNOSTIC_LIMIT)


def print_zero(status, reason):
    print(f"CASE 0000_{zero_case_tag(reason)} {status} score=0  # {reason}", flush=True)
    print("TOTAL_SCORE 0", flush=True)
    print("CASES_OK 0", flush=True)
    print("CASES_TOTAL 1", flush=True)


def extract_rejection_reason(out):
    for raw in out.splitlines():
        line = clean_line(raw)
        if line.startswith("Submission rejected by anti-cheat checks"):
            return "anti-cheat rejection: cheating or attempted cheating receives zero score"
        if line.startswith("Submission rejected by anti-hack checks"):
            return "anti-cheat rejection: cheating or attempted cheating receives zero score"
    return None


def main():
    if not os.path.isfile(PLUGIN_PATH):
        print("No my_plugin.js found", flush=True)
        print_zero("RE", "submission is missing my_plugin.js")
        return

    env = {**os.environ, "OPENRCT2_DIR": "/home/workspace/openrct2/release/OpenRCT2"}
    cmd = [sys.executable, ORIG_EVAL, PLUGIN_PATH,
           "--timeout", str(TIMEOUT_PER_SCENARIO),
           "--scenarios-dir", SCENARIOS_DIR]
    try:
        proc = subprocess.run(cmd, env=env, capture_output=True,
                              text=True, timeout=TOTAL_TIMEOUT, cwd=WORK_DIR)
        out = proc.stdout + "\n" + proc.stderr
    except subprocess.TimeoutExpired:
        print_zero("TLE", "OpenRCT2 evaluation timed out before producing scenario scores")
        return

    print(out, flush=True)

    # Per-scenario lines: "[scenario_small.park] normalized = 1.0453"
    per_scenario = re.findall(
        r"\[(scenario_\w+\.park)\]\s+normalized\s*=\s*([\d.]+)", out)
    feedback = extract_feedback(out)

    avg_match = re.search(r"Average\s+normalized\s+score[:\s]+([\d.]+)", out)
    final_match = re.search(r"Final\s+score[:\s]+([\d.]+)", out)

    ok_count = 0
    for i, (name, norm) in enumerate(per_scenario):
        norm_f = float(norm)
        # Scale 10000x so integer parser preserves 4 decimal places.
        score = int(round(norm_f * 10000))
        status = "OK" if score >= CASE_PASS_SCORE else "WA"
        tags = case_tags(feedback.get(name, {}), status)
        # Partial operation scores are useful feedback, but missing or
        # ineffective expansion should not count as a fully passed case.
        if any(tag in BLOCKING_PROGRESS_TAGS for tag in tags):
            status = "WA"
        if status == "OK":
            ok_count += 1
        case_id = make_case_id(i, tags)
        message = format_case_message(name, tags)
        print(f"CASE {case_id} {status} score={score}  # {message}", flush=True)

    if avg_match:
        avg = float(avg_match.group(1))
    elif final_match:
        avg = float(final_match.group(1))
    elif per_scenario:
        avg = sum(float(n) for _, n in per_scenario) / len(per_scenario)
    else:
        avg = 0.0

    total_score = int(round(avg * 10000))
    if not per_scenario:
        rejection_reason = extract_rejection_reason(out)
        if rejection_reason:
            print_zero("WA", rejection_reason)
        else:
            print_zero("RE", "judge produced no per-scenario normalized scores")
        return

    print(f"TOTAL_SCORE {total_score}", flush=True)
    print(f"CASES_OK {ok_count}", flush=True)
    print(f"CASES_TOTAL {len(per_scenario)}", flush=True)


if __name__ == "__main__":
    main()
