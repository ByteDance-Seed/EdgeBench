#!/usr/bin/env python3
"""Evaluate Lean axiom-check output and emit structured JSON.

This script consumes the output of a Lean helper such as `ListDeclAxiom.lean`,
which prints lines like:

    BAD Chapter2.Nat.succ_ne : type=Nat.succ n ≠ 0; unexpected=[sorryAx]; all=[sorryAx]
    OK Chapter2.Nat.decLe._proof_5 : type=Decidable (a ≤ b); axioms=[]
    BAD Chapter2.Nat.isOrderedRing : type=OrderedRing Nat; unexpected=[sorryAx];
    all=[propext, sorryAx, Classical.choice, Quot.sound]

The script converts that output into the structured JSON schema expected by
`sebench.harness.log_parsers.structured_json`.

Two scoring modes are supported:

1. `weighted`
   Scores repaired declarations by weights loaded from a JSON file.
2. `unweighted`
   Scores each baseline declaration equally.

The baseline is the set of declarations that originally depended on `sorryAx`.
This script only compares Lean-generated text outputs. It does not inspect the
repository source tree heuristically.

Example usage:

Compare two saved ListDeclAxiom outputs:
    python3 eval_lean.py /path/to/current.txt \
      --baseline-output /path/to/baseline.txt \
      --json-only

Run weighted single-file evaluation in the current repo only:
    python3 eval_lean.py \
      --current-repo /path/to/current_repo \
      --mode weighted \
      --weights /path/to/weights.json \
      --json-only

Example weights.json (dict form):
    {
      "Chapter2.Nat.lt_of_le_of_lt": {
        "weight": 2.0,
        "type": "a ≤ b → b < c → a < c"
      },
      "Chapter2.Nat.instLinearOrder._simp_1": {
        "weight": 1.0,
        "type": "min a b = a"
      }
    }

Example weights.json (list form):
    [
      {
        "decl": "Chapter2.Nat.lt_of_le_of_lt",
        "weight": 2.0,
        "type": "a ≤ b → b < c → a < c"
      },
      {
        "decl": "Chapter2.Nat.instLinearOrder._simp_1",
        "weight": 1.0,
        "type": "min a b = a"
      }
    ]

Compare two Lean repos directly:
    python3 eval_lean.py \
      --baseline-repo /path/to/original_repo \
      --current-repo /path/to/current_repo \
      --json-only
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

ALLOWED_CLASSICAL_AXIOMS = {"propext", "Classical.choice", "Quot.sound"}
SORRY_AXIOM = "sorryAx"
DEFAULT_BASELINE_OUTPUT_CANDIDATES = (
    "sorry_state.json",
    "baseline_sorry.json",
    "ListDeclAxiom.out",
    "ListDeclAxiom.txt",
    "list_decl_axiom.out",
    "list_decl_axiom.txt",
    "bad_decls.txt",
)
DECL_KEY_CANDIDATES = ("decl", "declaration", "name")
WEIGHT_KEY_CANDIDATES = ("weight", "score", "points")
TYPE_KEY_CANDIDATES = ("type", "type_text", "signature")
STRUCTURED_START = ">>>>> Start Structured Result"
STRUCTURED_END = ">>>>> End Structured Result"
LIST_DECL_AXIOM_INFO_PREFIX = r"(?:info:\s+ListDeclAxiom\.lean:\d+:\d+:\s+)?"


@dataclass(frozen=True)
class DeclarationRecord:
    decl: str
    type_text: str | None
    unexpected_axioms: tuple[str, ...]
    all_axioms: tuple[str, ...]

    @property
    def has_sorry(self) -> bool:
        return SORRY_AXIOM in self.all_axioms or SORRY_AXIOM in self.unexpected_axioms


@dataclass(frozen=True)
class ParsedOutput:
    bad: dict[str, DeclarationRecord]
    ok: dict[str, DeclarationRecord]
    hash_checks: dict[str, bool]

    @property
    def all_decl_names(self) -> set[str]:
        return set(self.bad) | set(self.ok)

    @property
    def all_records(self) -> dict[str, DeclarationRecord]:
        return {**self.ok, **self.bad}


@dataclass(frozen=True)
class WeightedDeclaration:
    decl: str
    type_text: str
    weight: float


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Evaluate Lean ListDeclAxiom output and emit structured JSON."
    )
    parser.add_argument(
        "current_output",
        type=Path,
        nargs="?",
        help="Path to the current ListDeclAxiom output file.",
    )
    parser.add_argument(
        "--mode",
        choices=("weighted", "unweighted"),
        default="unweighted",
        help="Scoring mode. Defaults to unweighted.",
    )
    parser.add_argument(
        "--baseline-dir",
        type=Path,
        help="Directory containing baseline state files.",
    )
    parser.add_argument(
        "--baseline-output",
        type=Path,
        help="Explicit path to baseline ListDeclAxiom output or baseline state JSON.",
    )
    parser.add_argument(
        "--current-repo",
        type=Path,
        help="Current repo root. Runs `lake build ListDeclAxiom` in this repo.",
    )
    parser.add_argument(
        "--baseline-repo",
        type=Path,
        help="Baseline repo root. Runs `lake build ListDeclAxiom` in this repo.",
    )
    parser.add_argument(
        "--weights",
        type=Path,
        help="Weight JSON file. Required in weighted mode.",
    )
    parser.add_argument(
        "--dump-baseline-state",
        type=Path,
        help="Write the normalized baseline sorry state JSON to this path.",
    )
    parser.add_argument(
        "--json-only",
        action="store_true",
        help="Print bare JSON instead of wrapping it in structured-result markers.",
    )
    return parser.parse_args()


def parse_bad_output(text: str) -> dict[str, DeclarationRecord]:
    """Parse BAD lines from ListDeclAxiom output."""
    pattern = re.compile(
        rf"^{LIST_DECL_AXIOM_INFO_PREFIX}BAD\s+(?P<decl>\S+)\s*:\s*(?:type=(?P<type>.*?);\s*)?"
        r"unexpected=\[(?P<unexpected>[^\]]*)\]\s*;\s*all=\[(?P<all>[^\]]*)\]\s*$",
        re.MULTILINE,
    )
    parsed: dict[str, DeclarationRecord] = {}
    for match in pattern.finditer(text):
        decl = match.group("decl").strip()
        type_text = match.group("type")
        parsed[decl] = DeclarationRecord(
            decl=decl,
            type_text=type_text.strip() if type_text is not None else None,
            unexpected_axioms=tuple(_split_axiom_list(match.group("unexpected"))),
            all_axioms=tuple(_split_axiom_list(match.group("all"))),
        )
    return parsed


def parse_ok_output(text: str) -> dict[str, DeclarationRecord]:
    """Parse OK lines from ListDeclAxiom output."""
    pattern = re.compile(
        rf"^{LIST_DECL_AXIOM_INFO_PREFIX}OK\s+(?P<decl>\S+)\s*:\s*(?:type=(?P<type>.*?);\s*axioms=\[(?P<all>[^\]]*)\]"
        r"|\[(?P<legacy_all>[^\]]*)\])\s*$",
        re.MULTILINE,
    )
    parsed: dict[str, DeclarationRecord] = {}
    for match in pattern.finditer(text):
        decl = match.group("decl").strip()
        type_text = match.group("type")
        all_axioms_raw = match.group("all")
        if all_axioms_raw is None:
            all_axioms_raw = match.group("legacy_all") or ""
        parsed[decl] = DeclarationRecord(
            decl=decl,
            type_text=type_text.strip() if type_text is not None else None,
            unexpected_axioms=(),
            all_axioms=tuple(_split_axiom_list(all_axioms_raw)),
        )
    return parsed


def parse_hash_checks(text: str) -> dict[str, bool]:
    """Parse HASH lines used to detect protected declaration changes."""
    pattern = re.compile(
        rf"^{LIST_DECL_AXIOM_INFO_PREFIX}HASH\s+checked=(?P<decl>\S+)\s+"
        r"result=(?P<result>true|false)\s*$",
        re.IGNORECASE | re.MULTILINE,
    )
    parsed: dict[str, bool] = {}
    for match in pattern.finditer(text):
        parsed[match.group("decl").strip()] = match.group("result").lower() == "true"
    return parsed


def parse_decl_output(text: str) -> ParsedOutput:
    return ParsedOutput(
        bad=parse_bad_output(text),
        ok=parse_ok_output(text),
        hash_checks=parse_hash_checks(text),
    )


def _split_axiom_list(raw: str) -> list[str]:
    if not raw.strip():
        return []
    return [part.strip() for part in raw.split(",") if part.strip()]


def find_baseline_output(baseline_dir: Path) -> Path:
    for name in DEFAULT_BASELINE_OUTPUT_CANDIDATES:
        candidate = baseline_dir / name
        if candidate.exists():
            return candidate
    raise FileNotFoundError(
        f"Could not find a baseline state file under {baseline_dir}. "
        f"Tried: {', '.join(DEFAULT_BASELINE_OUTPUT_CANDIDATES)}"
    )


def load_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def load_json(path: Path) -> Any:
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def run_list_decl_axiom(repo_root: Path) -> str:
    file_path = repo_root / "ListDeclAxiom.lean"
    if not file_path.exists():
        raise FileNotFoundError(f"Missing {file_path}")
    proc = subprocess.run(
        ["lake", "build", "ListDeclAxiom"],
        cwd=repo_root,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if proc.returncode != 0:
        stderr = proc.stderr.strip()
        raise RuntimeError(
            f"Failed to run ListDeclAxiom.lean in {repo_root}: "
            f"{stderr or f'exit code {proc.returncode}'}"
        )
    return proc.stdout


def load_baseline_sorry(path: Path) -> dict[str, str]:
    """Load baseline declarations that originally depended on sorryAx, with types."""
    if path.suffix.lower() == ".json":
        data = load_json(path)
        return _extract_baseline_sorry_from_json(data)

    parsed = parse_decl_output(load_text(path))
    baseline: dict[str, str] = {}
    for decl, info in parsed.bad.items():
        if not info.has_sorry:
            continue
        baseline[decl] = _require_type_text(
            decl,
            info.type_text,
            f"baseline output {path}",
        )
    return baseline


def _extract_baseline_sorry_from_json(data: Any) -> dict[str, str]:
    if isinstance(data, dict):
        if isinstance(data.get("declarations"), list):
            return _extract_decl_types_from_sequence(data["declarations"], require_type=True)
        if isinstance(data.get("details"), list):
            return _extract_decl_types_from_sequence(data["details"], require_type=True)
        if isinstance(data.get("baseline_types"), dict):
            return {str(k): str(v) for k, v in data["baseline_types"].items()}
        if isinstance(data.get("baseline_sorry"), list):
            raise ValueError(
                "Baseline JSON is missing declaration types; regenerate it with the updated "
                "eval_lean.py."
            )
        if all(isinstance(k, str) for k in data):
            extracted = _extract_decl_types_from_mapping(data)
            if extracted:
                return extracted
            raise ValueError(
                "Baseline JSON is missing declaration types; expected entries containing a "
                "`type` field."
            )
    if isinstance(data, list):
        return _extract_decl_types_from_sequence(data, require_type=True)
    raise ValueError("Unsupported baseline JSON format")


def _truthy_baseline_entry(value: Any) -> bool:
    if isinstance(value, bool):
        return value
    if isinstance(value, (int, float)):
        return value != 0
    if isinstance(value, dict):
        return bool(value.get("has_sorry", True))
    return bool(value)


def _extract_decl_types_from_sequence(
    items: list[Any],
    *,
    require_type: bool,
) -> dict[str, str]:
    names: dict[str, str] = {}
    for item in items:
        if isinstance(item, str):
            if require_type:
                raise ValueError(f"Missing type for declaration {item}")
            continue
        if isinstance(item, dict):
            decl = _extract_decl_name(item)
            if decl is None:
                continue
            type_text = _extract_type_text(item)
            if type_text is None:
                if require_type:
                    raise ValueError(f"Missing type for declaration {decl}")
                continue
            names[decl] = type_text
    return names


def _extract_decl_types_from_mapping(items: dict[str, Any]) -> dict[str, str]:
    records: dict[str, str] = {}
    for key, value in items.items():
        if not _truthy_baseline_entry(value):
            continue
        if isinstance(value, dict):
            decl = _extract_decl_name(value) or str(key)
            type_text = _extract_type_text(value)
            if type_text is not None:
                records[decl] = type_text
    return records


def load_weights(path: Path) -> dict[str, WeightedDeclaration]:
    data = load_json(path)
    weights: dict[str, WeightedDeclaration] = {}

    if isinstance(data, dict):
        for key, value in data.items():
            if not isinstance(value, dict):
                raise ValueError(
                    "Weighted mode requires each weight entry to be an object with `weight` "
                    "and `type` fields."
                )
            decl = _extract_decl_name(value) or str(key)
            weights[decl] = WeightedDeclaration(
                decl=decl,
                type_text=_extract_required_weight_type(value, decl),
                weight=_extract_weight(value),
            )
        return weights

    if isinstance(data, list):
        for item in data:
            if not isinstance(item, dict):
                raise ValueError("Weight list entries must be JSON objects")
            decl = _extract_decl_name(item)
            if decl is None:
                raise ValueError(f"Missing declaration name in weight entry: {item}")
            weights[decl] = WeightedDeclaration(
                decl=decl,
                type_text=_extract_required_weight_type(item, decl),
                weight=_extract_weight(item),
            )
        return weights

    raise ValueError("Unsupported weights JSON format")


def _extract_decl_name(item: dict[str, Any]) -> str | None:
    for key in DECL_KEY_CANDIDATES:
        if key in item:
            return str(item[key])
    return None


def _extract_type_text(item: dict[str, Any]) -> str | None:
    for key in TYPE_KEY_CANDIDATES:
        if key in item:
            return str(item[key])
    return None


def _extract_required_weight_type(item: dict[str, Any], decl: str) -> str:
    if "type" not in item:
        raise ValueError(f"Missing type in weight entry for {decl}: {item}")
    return str(item["type"])


def _extract_weight(item: dict[str, Any]) -> float:
    for key in WEIGHT_KEY_CANDIDATES:
        if key in item:
            return float(item[key])
    raise ValueError(f"Missing weight in entry: {item}")


def _require_type_text(decl: str, type_text: str | None, source_desc: str) -> str:
    if type_text is None:
        raise ValueError(
            f"Missing type for baseline declaration {decl} in {source_desc}. "
            "Regenerate ListDeclAxiom output with the updated format."
        )
    return type_text


def normalize_weights(
    mode: str,
    baseline_decls: dict[str, str],
    weights_path: Path | None,
) -> dict[str, float]:
    if mode == "weighted":
        if weights_path is None:
            raise ValueError("--weights is required in weighted mode")
        weights = load_weights(weights_path)
        missing = sorted(decl for decl in baseline_decls if decl not in weights)
        if missing:
            raise ValueError(
                "Missing weights for baseline declarations: "
                + ", ".join(missing[:10])
                + (f" (+{len(missing) - 10} more)" if len(missing) > 10 else "")
            )
        mismatched_types = sorted(
            decl for decl, type_text in baseline_decls.items() if weights[decl].type_text != type_text
        )
        if mismatched_types:
            sample = mismatched_types[:10]
            raise ValueError(
                "Weight JSON type does not match baseline for declarations: "
                + ", ".join(sample)
                + (
                    f" (+{len(mismatched_types) - 10} more)"
                    if len(mismatched_types) > 10
                    else ""
                )
            )
        return {decl: float(weights[decl].weight) for decl in baseline_decls}

    return {decl: 1.0 for decl in baseline_decls}


def baseline_inputs_provided(args: argparse.Namespace) -> bool:
    return any(
        value is not None
        for value in (args.baseline_repo, args.baseline_output, args.baseline_dir)
    )


def resolve_baseline_sorry(
    args: argparse.Namespace,
) -> tuple[dict[str, str], Path | None, str | None]:
    """Resolve the baseline declaration set.

    In weighted mode, if no baseline repo/output is provided, the weights file
    itself defines the baseline declaration scope and baseline types.
    """
    if args.mode == "weighted" and not baseline_inputs_provided(args):
        if args.weights is None:
            raise ValueError(
                "Weighted mode requires --weights, and needs either weights-only baseline "
                "or an explicit baseline repo/output."
            )
        weights = load_weights(args.weights)
        if not weights:
            raise ValueError(f"No weighted declarations found in {args.weights}")
        return {decl: entry.type_text for decl, entry in weights.items()}, None, None

    baseline_source, baseline_text = resolve_baseline_input(args)

    if baseline_text is not None:
        baseline_sorry: dict[str, str] = {}
        for decl, info in parse_decl_output(baseline_text).bad.items():
            if not info.has_sorry:
                continue
            baseline_sorry[decl] = _require_type_text(
                decl,
                info.type_text,
                "baseline repo output",
            )
    else:
        assert baseline_source is not None
        baseline_sorry = load_baseline_sorry(baseline_source)
    return baseline_sorry, baseline_source, baseline_text


def build_report(
    *,
    mode: str,
    baseline_sorry: dict[str, str],
    baseline_weights: dict[str, float],
    current_parsed: ParsedOutput,
) -> dict[str, Any]:
    baseline_names = set(baseline_sorry)
    current_bad = current_parsed.bad
    current_ok = current_parsed.ok
    current_records = current_parsed.all_records
    current_bad_sorry = {decl for decl, info in current_bad.items() if info.has_sorry}
    declaration_changed = sorted(
        decl for decl, result in current_parsed.hash_checks.items() if not result
    )
    new_bad_decls = sorted(set(current_bad) - baseline_names)
    type_changed = sorted(
        decl
        for decl, baseline_type in baseline_sorry.items()
        if decl in current_records and current_records[decl].type_text != baseline_type
    )
    disappeared = sorted(
        decl
        for decl in baseline_sorry
        if decl not in current_records
    )
    baseline_bad_remaining = [
        decl
        for decl in baseline_sorry
        if decl in current_bad and decl not in disappeared and decl not in type_changed
    ]
    repaired = sorted(
        decl
        for decl in baseline_sorry
        if decl in current_ok and decl not in disappeared and decl not in type_changed
    )
    baseline_bad_remaining = sorted(baseline_bad_remaining)

    repaired_weight = sum(baseline_weights[decl] for decl in repaired)
    unresolved_weight = sum(baseline_weights[decl] for decl in baseline_bad_remaining)
    disappeared_weight = sum(baseline_weights[decl] for decl in disappeared)

    baseline_total_weight = sum(baseline_weights.values())
    score_denominator = baseline_total_weight
    raw_score_numerator = max(0.0, repaired_weight)
    raw_score = raw_score_numerator / score_denominator if score_denominator > 0 else 0.0
    score_numerator = 0.0 if declaration_changed else raw_score_numerator
    score = score_numerator / score_denominator if score_denominator > 0 else 0.0

    details = []
    for decl in sorted(baseline_sorry):
        weight = baseline_weights[decl]
        if decl in repaired:
            details.append(
                {
                    "name": decl,
                    "status": "PASSED",
                    "message": "repaired",
                    "score": weight,
                    "weight": weight,
                }
            )
            continue
        if decl in disappeared:
            details.append(
                {
                    "name": decl,
                    "status": "FAILED",
                    "message": "missing from current ListDeclAxiom output",
                    "score": 0.0,
                    "weight": weight,
                }
            )
            continue
        if decl in type_changed:
            current_info = current_records[decl]
            details.append(
                {
                    "name": decl,
                    "status": "FAILED",
                    "message": "type changed: baseline="
                    + repr(baseline_sorry[decl])
                    + ", current="
                    + repr(current_info.type_text),
                    "score": 0.0,
                    "weight": weight,
                }
            )
            continue

        info = current_bad.get(decl)
        message = "still depends on unexpected axioms"
        if info is not None:
            message = (
                "still bad: unexpected="
                + _fmt_axioms(info.unexpected_axioms)
                + "; all="
                + _fmt_axioms(info.all_axioms)
            )
        details.append(
            {
                "name": decl,
                "status": "FAILED",
                "message": message,
                "score": 0.0,
                "weight": weight,
            }
        )

    for decl in new_bad_decls:
        info = current_bad[decl]
        details.append(
            {
                "name": decl,
                "status": "FAILED",
                "message": "new bad declaration introduced: unexpected="
                + _fmt_axioms(info.unexpected_axioms)
                + "; all="
                + _fmt_axioms(info.all_axioms),
                "score": 0.0,
                "weight": 0.0,
            }
        )

    for decl in declaration_changed:
        details.append(
            {
                "name": decl,
                "status": "FAILED",
                "message": "declaration changed: HASH check failed",
                "score": 0.0,
                "weight": 0.0,
            }
        )

    summary_bits = [
        f"mode={mode}",
        f"repaired={len(repaired)}/{len(baseline_sorry)}",
        f"remaining_bad={len(baseline_bad_remaining)}",
    ]
    if disappeared:
        summary_bits.append(f"disappeared={len(disappeared)}")
    if type_changed:
        summary_bits.append(f"type_changed={len(type_changed)}")
    if new_bad_decls:
        summary_bits.append(f"new_bad={len(new_bad_decls)}")
    if declaration_changed:
        summary_bits.append(f"declaration_changed={len(declaration_changed)}")

    metrics = {
        "mode": mode,
        "allowed_axioms": sorted(ALLOWED_CLASSICAL_AXIOMS),
        "baseline_total": len(baseline_sorry),
        "baseline_total_weight": baseline_total_weight,
        "repaired": repaired,
        "repaired_count": len(repaired),
        "repaired_weight": repaired_weight,
        "remaining_bad": baseline_bad_remaining,
        "remaining_bad_count": len(baseline_bad_remaining),
        "remaining_bad_weight": unresolved_weight,
        "disappeared": disappeared,
        "disappeared_count": len(disappeared),
        "disappeared_weight": disappeared_weight,
        "type_changed": type_changed,
        "type_changed_count": len(type_changed),
        "current_ok_total": len(current_ok),
        "current_decl_total": len(current_parsed.all_decl_names),
        "current_bad_total": len(current_bad),
        "current_bad_with_sorry_count": len(current_bad_sorry),
        "new_bad_declarations": new_bad_decls,
        "new_bad_count": len(new_bad_decls),
        "hash_checks": current_parsed.hash_checks,
        "hash_check_count": len(current_parsed.hash_checks),
        "declaration_changed": declaration_changed,
        "declaration_changed_count": len(declaration_changed),
        "hash_penalty_applied": bool(declaration_changed),
        "raw_score_before_hash_check": raw_score,
        "raw_score_numerator_before_hash_check": raw_score_numerator,
        "score_numerator": score_numerator,
        "score_denominator": score_denominator,
    }

    return {
        "valid": True,
        "score": score,
        "pass_rate": score,
        "summary": ", ".join(summary_bits),
        "details": details,
        "metrics": metrics,
    }


def _fmt_axioms(axioms: tuple[str, ...]) -> str:
    return "[" + ", ".join(axioms) + "]"


def dump_baseline_state(path: Path, baseline_sorry: dict[str, str], weights: dict[str, float]) -> None:
    payload = {
        "baseline_sorry": sorted(baseline_sorry),
        "baseline_types": {decl: baseline_sorry[decl] for decl in sorted(baseline_sorry)},
        "weights": {decl: weights[decl] for decl in sorted(weights)},
        "declarations": [
            {
                "decl": decl,
                "type": baseline_sorry[decl],
                "weight": weights[decl],
            }
            for decl in sorted(baseline_sorry)
        ],
    }
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def emit_result(result: dict[str, Any], json_only: bool) -> None:
    payload = json.dumps(result, indent=2, ensure_ascii=False)
    if json_only:
        print(payload)
        return
    print(STRUCTURED_START)
    print(payload)
    print(STRUCTURED_END)


def main() -> int:
    args = parse_args()

    try:
        current_text = resolve_current_text(args)
        current_parsed = parse_decl_output(current_text)

        baseline_sorry, baseline_source, _baseline_text = resolve_baseline_sorry(args)
        if not baseline_sorry:
            source_desc = baseline_source or args.baseline_repo or args.weights
            raise ValueError(f"No baseline sorry declarations found in {source_desc}")

        baseline_weights = normalize_weights(args.mode, baseline_sorry, args.weights)

        if args.dump_baseline_state is not None:
            dump_baseline_state(args.dump_baseline_state, baseline_sorry, baseline_weights)

        result = build_report(
            mode=args.mode,
            baseline_sorry=baseline_sorry,
            baseline_weights=baseline_weights,
            current_parsed=current_parsed,
        )
        emit_result(result, args.json_only)
        return 0
    except Exception as exc:
        error_result = {
            "valid": False,
            "score": 0.0,
            "pass_rate": 0.0,
            "summary": f"eval_lean error: {exc}",
            "details": [],
            "metrics": {
                "error_type": type(exc).__name__,
            },
        }
        emit_result(error_result, args.json_only)
        return 1


def resolve_current_text(args: argparse.Namespace) -> str:
    if args.current_repo is not None:
        return run_list_decl_axiom(args.current_repo)
    if args.current_output is not None:
        return load_text(args.current_output)
    raise ValueError("Provide either current_output or --current-repo")


def resolve_baseline_input(args: argparse.Namespace) -> tuple[Path | None, str | None]:
    if args.baseline_repo is not None:
        return None, run_list_decl_axiom(args.baseline_repo)

    baseline_source = args.baseline_output
    if baseline_source is None:
        if args.baseline_dir is None:
            raise ValueError(
                "Provide one of --baseline-repo, --baseline-output, or --baseline-dir"
            )
        baseline_source = find_baseline_output(args.baseline_dir)
    return baseline_source, None


if __name__ == "__main__":
    sys.exit(main())
