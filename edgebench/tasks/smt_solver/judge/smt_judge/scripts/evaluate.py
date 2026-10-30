#!/usr/bin/env python3
"""SE-Bench SMT Solver Evaluation Script.

Examples:
    python3 scripts/evaluate.py \
      --solver ./solve \
      --benchmarks benchmarks \
      --expected benchmarks/expected_answers.json \
      --manifest benchmarks/selection_manifest.json \
      --timeout 60 \
      --parallel 4

The same script can score either the public set (`benchmarks/`) or the hidden
set (`hidden_benchmarks/`). All benchmark cases, including hard cases, are
included by default.
"""

import argparse
from fractions import Fraction
import hashlib
import json
import os
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import time
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path

sys.setrecursionlimit(max(sys.getrecursionlimit(), 20000))

LOGICS = ["QF_UF", "QF_LRA", "QF_LIA", "QF_UFLRA"]
DIFFICULTIES = ["easy", "medium", "hard"]
WEIGHTS = {"easy": 0.10, "medium": 0.20, "hard": 0.70}
UNSAT_STATUS_ONLY_CREDIT = 0.20
VALID_ANSWERS = {"sat", "unsat", "unknown"}
FORBIDDEN_SOLVER_NAMES = {
    "z3",
    "cvc5",
    "cvc4",
    "yices",
    "mathsat",
    "boolector",
    "bitwuzla",
    "opensmt",
}
FORBIDDEN_DATA_NAMES = {
    "expected_answers.json",
    "selection_manifest.json",
    "hidden_expected_answers.json",
    "hidden_selection_manifest.json",
}
SOURCE_SUFFIXES = {
    ".py",
    ".sh",
    ".bash",
    ".c",
    ".cc",
    ".cpp",
    ".h",
    ".hpp",
    ".rs",
    ".go",
    ".java",
    ".js",
    ".ts",
    ".rb",
    ".pl",
    ".lua",
    ".cmake",
    ".mk",
    ".toml",
    ".yaml",
    ".yml",
}
FORBIDDEN_TEXT_PATTERNS = [
    ("z3_import", re.compile(r"\b(import|from)\s+z3\b", re.IGNORECASE)),
    ("cvc5_import", re.compile(r"\b(import|from)\s+cvc5\b", re.IGNORECASE)),
    ("external_solver_name", re.compile(r"\b(z3|cvc5|cvc4|yices|mathsat|boolector|bitwuzla|opensmt|pysmt)\b", re.IGNORECASE)),
    ("process_spawn", re.compile(r"\b(subprocess|os\.system|popen|execvp|execve|spawn\w*)\b", re.IGNORECASE)),
    ("network_access", re.compile(r"\b(socket|urllib|requests|httpx|curl|wget)\b|https?://", re.IGNORECASE)),
    ("answer_or_manifest_reference", re.compile(r"\b(hidden_expected|hidden_selection_manifest|expected_answers|selection_manifest|hidden_benchmarks|public_score|hidden_score)\b", re.IGNORECASE)),
    ("benchmark_dir_reference", re.compile(r"benchmarks[/\\]", re.IGNORECASE)),
    ("numeric_benchmark_filename", re.compile(r"\b\d{6}\.smt2\b", re.IGNORECASE)),
    ("hash_benchmark_filename", re.compile(r"\b[0-9a-f]{16}\.smt2\b", re.IGNORECASE)),
    ("logic_numeric_path", re.compile(r"\bQF_(?:UF|LRA|LIA|UFLRA)[/\\]\d{6}\.smt2\b", re.IGNORECASE)),
    ("path_fingerprinting", re.compile(r"\b(basename|realpath|readlink)\b|Path\s*\([^)]*\)\.name|sys\.argv\s*\[\s*1\s*\]\.split|\.split\(\s*['\"]\/['\"]\s*\)", re.IGNORECASE)),
    ("family_marker", re.compile(r"\b(CPAchecker|quasigroups?|Ultimate|LassoRanker|Clock\s+Synchronization|CMODELS)\b", re.IGNORECASE)),
]


def load_expected(path):
    if not path:
        return {}
    path = resolve_hidden_metadata_path(path, "hidden_expected_answers.json")
    with open(path) as f:
        return json.load(f)


def load_manifest(path):
    if not path:
        return {}
    path = resolve_hidden_metadata_path(path, "hidden_selection_manifest.json")
    with open(path) as f:
        entries = json.load(f)
    return {entry["selected_path"]: entry for entry in entries}


def resolve_hidden_metadata_path(path, evaluator_side_name):
    candidate = Path(path)
    if candidate.exists():
        return str(candidate)
    if candidate.parent.name == "hidden_benchmarks":
        fallback = candidate.parent.parent / evaluator_side_name
        if fallback.exists():
            return str(fallback)
    if evaluator_side_name == "hidden_expected_answers.json":
        fallback = candidate.parent / "hidden_benchmarks" / "expected_answers.json"
        if fallback.exists():
            return str(fallback)
    if evaluator_side_name == "hidden_selection_manifest.json":
        fallback = candidate.parent / "hidden_benchmarks" / "selection_manifest.json"
        if fallback.exists():
            return str(fallback)
    return str(candidate)


def hide_reference_files(benchmarks_dir, expected_path, manifest_path):
    root = Path(benchmarks_dir).resolve()
    candidates = {
        Path(expected_path).resolve(),
        Path(manifest_path).resolve(),
        root / "expected_answers.json",
        root / "selection_manifest.json",
        root.parent / "hidden_expected_answers.json",
        root.parent / "hidden_selection_manifest.json",
    }
    for path in candidates:
        if not path.exists():
            continue
        try:
            path.unlink()
        except OSError as exc:
            print(
                f"Error: cannot hide evaluator reference file before running solver: {path}: {exc}",
                file=sys.stderr,
            )
            sys.exit(2)


def detect_logic(text, fallback_key):
    for line in text.splitlines()[:100]:
        stripped = line.strip()
        if stripped.startswith("(set-logic") and stripped.endswith(")"):
            parts = stripped.strip("()").split()
            if len(parts) >= 2:
                return parts[1]
    return fallback_key.split("/", 1)[0]


def find_check_sat_offset(text):
    marker = "(check-sat)"
    idx = text.rfind(marker)
    if idx < 0:
        return len(text)
    line_start = text.rfind("\n", 0, idx)
    return 0 if line_start < 0 else line_start + 1


def find_first_assert_offset(text):
    marker = "(assert"
    idx = text.find(marker)
    if idx < 0:
        return find_check_sat_offset(text)
    line_start = text.rfind("\n", 0, idx)
    return 0 if line_start < 0 else line_start + 1


def perturbation_blocks(logic, seed):
    digest = hashlib.sha256(seed.encode("utf-8")).digest()
    prefix = f"__sebench_{digest.hex()[:12]}"
    n_bool = 1 + digest[0] % 5
    n_arith = 1 + digest[1] % 5
    n_extra_asserts = 2 + digest[2] % 11

    decls = ["", f"; se-bench perturbation declarations {digest.hex()[:16]}"]
    for i in range(n_bool):
        decls.append(f"(declare-fun {prefix}_b{i} () Bool)")

    if logic == "QF_LIA":
        arith_sort = "Int"
    elif logic in {"QF_LRA", "QF_UFLRA"}:
        arith_sort = "Real"
    else:
        arith_sort = None

    if arith_sort:
        for i in range(n_arith):
            decls.append(f"(declare-fun {prefix}_x{i} () {arith_sort})")

    asserts = ["", f"; se-bench perturbation assertions {digest.hex()[:16]}"]
    for i in range(n_extra_asserts):
        b = i % n_bool
        mode = digest[(i + 3) % len(digest)] % 4
        if mode == 0:
            asserts.append(f"(assert (or {prefix}_b{b} (not {prefix}_b{b})))")
        elif mode == 1:
            asserts.append(f"(assert (= {prefix}_b{b} {prefix}_b{b}))")
        elif arith_sort and mode == 2:
            x = i % max(n_arith, 1)
            asserts.append(f"(assert (= {prefix}_x{x} {prefix}_x{x}))")
        elif arith_sort:
            x = i % max(n_arith, 1)
            asserts.append(f"(assert (<= {prefix}_x{x} {prefix}_x{x}))")
        else:
            asserts.append(f"(assert (=> {prefix}_b{b} {prefix}_b{b}))")
    decls.append("")
    asserts.append("")
    return "\n".join(decls), "\n".join(asserts)


def make_solver_input_text(benchmark_key, benchmark_path, perturb, perturb_salt):
    with open(benchmark_path, "r", encoding="utf-8", errors="ignore") as f:
        text = f.read()
    if not perturb:
        return text
    logic = detect_logic(text, benchmark_key)
    seed = f"{perturb_salt}\0{benchmark_key}\0{os.path.getsize(benchmark_path)}"
    decl_block, assert_block = perturbation_blocks(logic, seed)
    decl_offset = find_first_assert_offset(text)
    with_decls = text[:decl_offset] + decl_block + text[decl_offset:]
    assert_offset = find_check_sat_offset(with_decls)
    return with_decls[:assert_offset] + assert_block + with_decls[assert_offset:]


def find_benchmarks(benchmarks_dir, logics, manifest=None, difficulties=None):
    root = Path(benchmarks_dir)
    result = {}
    allowed_difficulties = set(difficulties) if difficulties else None
    for logic in logics:
        logic_dir = root / logic
        if not logic_dir.is_dir():
            result[logic] = []
            continue
        files = sorted(logic_dir.glob("*.smt2"))
        selected = []
        for path in files:
            key = f"{logic}/{path.name}"
            if manifest and allowed_difficulties is not None:
                entry = manifest.get(key)
                if not entry or entry.get("difficulty") not in allowed_difficulties:
                    continue
            selected.append((key, str(path)))
        result[logic] = selected
    return result


def should_scan_text(path):
    if path.name.lower() in {"readme.md", "license", "notice"}:
        return False
    return path.suffix.lower() in SOURCE_SUFFIXES or os.access(path, os.X_OK)


def run_preflight(submission_root, solver):
    root = Path(submission_root).resolve()
    solver_path = Path(solver).resolve()
    violations = []
    if not (root / "build.sh").is_file():
        violations.append("submission root must contain build.sh")
    if not (root / "src").is_dir():
        violations.append("submission root must contain src/")
    if not solver_path.is_relative_to(root):
        violations.append(f"solver must be inside submission root: {solver_path} not under {root}")

    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [
            d
            for d in dirnames
            if d not in {".git", "__pycache__", ".mypy_cache", ".pytest_cache", "target", "build", "dist"}
        ]
        current = Path(dirpath)
        for filename in filenames:
            path = current / filename
            lower_name = filename.lower()
            stem = path.stem.lower()
            if lower_name in FORBIDDEN_DATA_NAMES:
                violations.append(f"forbidden answer/manifest file in submission: {path.relative_to(root)}")
            if lower_name in FORBIDDEN_SOLVER_NAMES or stem in FORBIDDEN_SOLVER_NAMES:
                violations.append(f"forbidden external SMT solver binary or wrapper name: {path.relative_to(root)}")
            if not should_scan_text(path):
                continue
            try:
                text = path.read_text(errors="ignore")[:1_000_000]
            except Exception:
                continue
            for rule_name, pattern in FORBIDDEN_TEXT_PATTERNS:
                if pattern.search(text):
                    violations.append(f"forbidden {rule_name} in {path.relative_to(root)}")
                    break

    if violations:
        print("Submission preflight failed:", file=sys.stderr)
        for item in violations[:50]:
            print(f"  - {item}", file=sys.stderr)
        if len(violations) > 50:
            print(f"  ... {len(violations) - 50} more", file=sys.stderr)
        sys.exit(2)


class ModelValidationError(Exception):
    pass


def tokenize_smt2(text):
    tokens = []
    i = 0
    n = len(text)
    while i < n:
        ch = text[i]
        if ch.isspace():
            i += 1
            continue
        if ch == ";":
            while i < n and text[i] != "\n":
                i += 1
            continue
        if ch in "()":
            tokens.append(ch)
            i += 1
            continue
        if ch == "|":
            j = i + 1
            while j < n and text[j] != "|":
                j += 1
            if j >= n:
                raise ModelValidationError("unterminated quoted symbol")
            tokens.append(text[i : j + 1])
            i = j + 1
            continue
        j = i
        while j < n and (not text[j].isspace()) and text[j] not in "();":
            j += 1
        tokens.append(text[i:j])
        i = j
    return tokens


def parse_expr(tokens, index=0):
    if index >= len(tokens):
        raise ModelValidationError("unexpected end of SMT input")
    tok = tokens[index]
    if tok == "(":
        index += 1
        out = []
        while index < len(tokens) and tokens[index] != ")":
            item, index = parse_expr(tokens, index)
            out.append(item)
        if index >= len(tokens):
            raise ModelValidationError("missing closing parenthesis")
        return out, index + 1
    if tok == ")":
        raise ModelValidationError("unexpected closing parenthesis")
    return tok, index + 1


def parse_smt2(text):
    tokens = tokenize_smt2(text)
    forms = []
    index = 0
    while index < len(tokens):
        form, index = parse_expr(tokens, index)
        forms.append(form)
    return forms


def canonical_term(term):
    if isinstance(term, list):
        return "(" + " ".join(canonical_term(part) for part in term) + ")"
    return str(term)


def parse_model_literal(text):
    text = str(text).strip()
    if not text:
        raise ModelValidationError("empty model value")
    if text.startswith("("):
        forms = parse_smt2(text)
        if len(forms) != 1:
            raise ModelValidationError(f"bad literal: {text}")
        return forms[0]
    return text


def decimal_to_fraction(text):
    if "." not in text:
        return Fraction(int(text), 1)
    neg = text.startswith("-")
    body = text[1:] if neg else text
    whole, frac = body.split(".", 1)
    numerator = int((whole or "0") + frac)
    denominator = 10 ** len(frac)
    value = Fraction(numerator, denominator)
    return -value if neg else value


def parse_numeric_literal(term):
    if isinstance(term, str):
        if term.lstrip("-").isdigit():
            return Fraction(int(term), 1)
        if "." in term:
            return decimal_to_fraction(term)
    if isinstance(term, list) and len(term) == 2 and term[0] == "-":
        return -parse_numeric_literal(term[1])
    if isinstance(term, list) and len(term) == 3 and term[0] == "/":
        return parse_numeric_literal(term[1]) / parse_numeric_literal(term[2])
    raise ModelValidationError(f"not a numeric literal: {canonical_term(term)}")


def value_key(kind, value):
    if kind == "num":
        return ("num", value.numerator, value.denominator)
    return (kind, value)


def is_arithmetic_sort(logic, sort):
    return (logic == "QF_LIA" and sort == "Int") or (
        logic in {"QF_LRA", "QF_UFLRA"} and sort == "Real"
    )


def parse_model_value(raw, sort, logic):
    lit = parse_model_literal(raw)
    if sort == "Bool":
        if lit == "true":
            return ("bool", True)
        if lit == "false":
            return ("bool", False)
        raise ModelValidationError(f"Bool value must be true/false: {raw}")
    if is_arithmetic_sort(logic, sort):
        num = parse_numeric_literal(lit)
        if sort == "Int" and num.denominator != 1:
            raise ModelValidationError(f"Int value is not integral: {raw}")
        return ("num", num)
    return ("atom", str(raw))


def require_bool(value, where):
    if value[0] != "bool":
        raise ModelValidationError(f"expected Bool at {where}")
    return value[1]


def require_num(value, where):
    if value[0] != "num":
        raise ModelValidationError(f"expected numeric value at {where}")
    return value[1]


class WitnessChecker:
    def __init__(self, benchmark_path, witness):
        with open(benchmark_path, "r", encoding="utf-8", errors="ignore") as f:
            self.forms = parse_smt2(f.read())
        self.logic = None
        self.decls = {}
        self.defines = {}
        self.define_cache = {}
        self.assertions = []
        self.uf_apps = []
        self.values = witness.get("values") if isinstance(witness, dict) else None
        if not isinstance(self.values, dict):
            raise ModelValidationError("sat witness must be JSON with object field 'values'")
        self._load_commands()

    def _load_commands(self):
        for form in self.forms:
            if not isinstance(form, list) or not form:
                continue
            cmd = form[0]
            if cmd == "set-logic" and len(form) >= 2:
                self.logic = form[1]
            elif cmd == "declare-const" and len(form) == 3:
                self.decls[form[1]] = ([], form[2])
            elif cmd == "declare-fun" and len(form) == 4:
                args = form[2] if isinstance(form[2], list) else []
                self.decls[form[1]] = (args, form[3])
            elif cmd == "define-fun" and len(form) == 5:
                params = form[2] if isinstance(form[2], list) else []
                self.defines[form[1]] = (params, form[3], form[4])
            elif cmd == "assert" and len(form) == 2:
                self.assertions.append(form[1])
        if self.logic is None:
            self.logic = "QF_UF"

    def model_lookup(self, key, sort):
        if key not in self.values:
            raise ModelValidationError(f"missing model value for {key}")
        return parse_model_value(self.values[key], sort, self.logic)

    def model_lookup_any(self, keys, sort):
        for key in keys:
            if key in self.values:
                return parse_model_value(self.values[key], sort, self.logic)
        raise ModelValidationError(f"missing model value for {keys[0]}")

    def expanded_canonical_term(self, term):
        if isinstance(term, str):
            define = self.defines.get(term)
            if define is not None and not define[0]:
                ret_sort = define[1]
                body = define[2]
                if ret_sort == "Real" and isinstance(body, str) and body.lstrip("-").isdigit():
                    return f"{body}.0"
                return self.expanded_canonical_term(body)
            return term
        if not term:
            return "()"
        if term[0] == "!" and len(term) >= 2:
            return self.expanded_canonical_term(term[1])
        if term[0] == "let" and len(term) == 3 and isinstance(term[1], list):
            return canonical_term(term)
        return "(" + " ".join(self.expanded_canonical_term(part) for part in term) + ")"

    def eval(self, term, env=None):
        if env is None:
            env = {}
        if isinstance(term, str):
            if term in env:
                return env[term]
            if term == "true":
                return ("bool", True)
            if term == "false":
                return ("bool", False)
            try:
                if self.logic != "QF_UF":
                    return ("num", parse_numeric_literal(term))
            except Exception:
                pass
            if term in self.decls:
                args, sort = self.decls[term]
                if args:
                    raise ModelValidationError(f"function {term} used without arguments")
                return self.model_lookup(term, sort)
            if term in self.defines:
                params, ret_sort, body = self.defines[term]
                if params:
                    raise ModelValidationError(f"function {term} used without arguments")
                if not env and term in self.define_cache:
                    return self.define_cache[term]
                value = self.eval(body, env)
                if not env:
                    self.define_cache[term] = value
                return value
            if self.logic == "QF_UF":
                return ("atom", term)
            raise ModelValidationError(f"unknown symbol {term}")

        if not term:
            raise ModelValidationError("empty term")
        op = term[0]
        args = term[1:]
        if op == "!":
            return self.eval(args[0], env)
        if op == "let":
            local = dict(env)
            bound = {}
            for binding in args[0]:
                bound[binding[0]] = self.eval(binding[1], env)
            local.update(bound)
            return self.eval(args[1], local)
        if op == "not":
            return ("bool", not require_bool(self.eval(args[0], env), canonical_term(term)))
        if op == "and":
            return ("bool", all(require_bool(self.eval(a, env), canonical_term(a)) for a in args))
        if op == "or":
            return ("bool", any(require_bool(self.eval(a, env), canonical_term(a)) for a in args))
        if op == "=>":
            return ("bool", (not require_bool(self.eval(args[0], env), canonical_term(args[0]))) or require_bool(self.eval(args[1], env), canonical_term(args[1])))
        if op == "ite":
            branch = args[1] if require_bool(self.eval(args[0], env), canonical_term(args[0])) else args[2]
            return self.eval(branch, env)
        if op == "=":
            vals = [value_key(*self.eval(a, env)) for a in args]
            return ("bool", all(v == vals[0] for v in vals[1:]))
        if op == "distinct":
            vals = [value_key(*self.eval(a, env)) for a in args]
            return ("bool", len(vals) == len(set(vals)))
        if op == "+":
            return ("num", sum((require_num(self.eval(a, env), canonical_term(a)) for a in args), Fraction(0)))
        if op == "-":
            nums = [require_num(self.eval(a, env), canonical_term(a)) for a in args]
            if len(nums) == 1:
                return ("num", -nums[0])
            return ("num", nums[0] - sum(nums[1:], Fraction(0)))
        if op == "*":
            product = Fraction(1)
            for arg in args:
                product *= require_num(self.eval(arg, env), canonical_term(arg))
            return ("num", product)
        if op == "/":
            left = require_num(self.eval(args[0], env), canonical_term(args[0]))
            right = require_num(self.eval(args[1], env), canonical_term(args[1]))
            if right == 0:
                raise ModelValidationError("division by zero in term")
            return ("num", left / right)
        if op in {"<", ">", "<=", ">="}:
            left = require_num(self.eval(args[0], env), canonical_term(args[0]))
            right = require_num(self.eval(args[1], env), canonical_term(args[1]))
            return ("bool", {"<": left < right, ">": left > right, "<=": left <= right, ">=": left >= right}[op])
        if op in self.defines:
            params, ret_sort, body = self.defines[op]
            local = dict(env)
            for param, arg in zip(params, args):
                local[param[0]] = self.eval(arg, env)
            return self.eval(body, local)
        if op not in self.decls:
            raise ModelValidationError(f"unknown function {op}")
        arg_sorts, ret_sort = self.decls[op]
        if len(arg_sorts) != len(args):
            raise ModelValidationError(f"arity mismatch for {op}")
        arg_values = tuple(value_key(*self.eval(a, env)) for a in args)
        key = canonical_term(term)
        keys = [key]
        expanded_key = self.expanded_canonical_term(term)
        if expanded_key != key:
            keys.append(expanded_key)
        result = self.model_lookup_any(keys, ret_sort)
        self.uf_apps.append((op, arg_values, value_key(*result)))
        return result

    def validate(self):
        for assertion in self.assertions:
            value = self.eval(assertion)
            if not require_bool(value, canonical_term(assertion)):
                raise ModelValidationError(f"assertion is false: {canonical_term(assertion)[:160]}")
        seen = {}
        for fn, arg_values, result in self.uf_apps:
            key = (fn, arg_values)
            if key in seen and seen[key] != result:
                raise ModelValidationError(f"congruence violation for {fn}")
            seen[key] = result


def validate_sat_witness(benchmark_path, witness):
    WitnessChecker(benchmark_path, witness).validate()


def parse_solver_output(stdout):
    lines = [line.strip() for line in stdout.splitlines() if line.strip()]
    if not lines:
        return "error:stdout", None
    answer = lines[0].lower()
    if answer not in VALID_ANSWERS:
        return "error:stdout", None
    if answer in {"unsat", "unknown"}:
        if len(lines) != 1:
            return "error:stdout", None
        return answer, None
    if len(lines) == 1:
        return "sat", None
    try:
        witness = json.loads("\n".join(lines[1:]))
    except json.JSONDecodeError:
        return "error:model-json", None
    return "sat", witness



def run_solver_case(args):
    solver_path, benchmark_key, benchmark_path, timeout, perturb, perturb_salt = args
    start = time.time()
    proc = None
    try:
        with tempfile.TemporaryDirectory(prefix="smt_case_") as tmpdir:
            isolated_path = str(Path(tmpdir) / "input.smt2")
            solver_input = make_solver_input_text(
                benchmark_key, benchmark_path, perturb, perturb_salt
            )
            with open(isolated_path, "w", encoding="utf-8") as f:
                f.write(solver_input)
            proc = subprocess.Popen(
                [solver_path, isolated_path],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                start_new_session=True,
            )
            stdout, stderr = proc.communicate(timeout=timeout)
            answer, witness = parse_solver_output(stdout)
            model_valid = None
            model_error = None
            if answer == "sat":
                if witness is None:
                    model_valid = False
                    model_error = "missing sat witness"
                else:
                    try:
                        validate_sat_witness(isolated_path, witness)
                        model_valid = True
                    except Exception as exc:
                        model_valid = False
                        model_error = str(exc)
        elapsed = time.time() - start
        if proc.returncode != 0 and not answer.startswith("error"):
            answer = f"error:returncode:{proc.returncode}"
        return {
            "benchmark": benchmark_key,
            "path": benchmark_path,
            "answer": answer,
            "model_valid": model_valid,
            "model_error": model_error,
            "time": round(elapsed, 3),
        }
    except subprocess.TimeoutExpired:
        if proc is not None:
            try:
                os.killpg(proc.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            try:
                proc.communicate(timeout=5)
            except Exception:
                pass
        elapsed = time.time() - start
        return {
            "benchmark": benchmark_key,
            "path": benchmark_path,
            "answer": "timeout",
            "time": round(elapsed, 3),
        }
    except Exception as exc:
        if proc is not None and proc.poll() is None:
            try:
                os.killpg(proc.pid, signal.SIGKILL)
            except Exception:
                pass
        elapsed = time.time() - start
        return {
            "benchmark": benchmark_key,
            "path": benchmark_path,
            "answer": f"error:{exc}",
            "time": round(elapsed, 3),
        }

def classify_result(result, expected):
    exp = expected.get(result["benchmark"])
    answer = result["answer"]
    result["expected"] = exp
    result["credit"] = 0.0
    if exp is None:
        result["verdict"] = "no_reference"
    elif exp == "sat" and answer == "sat":
        if result.get("model_valid") is True:
            result["verdict"] = "correct"
            result["credit"] = 1.0
        else:
            result["verdict"] = "invalid_model"
    elif exp == "unsat" and answer == "unsat":
        result["verdict"] = "status_only_unsat"
        result["credit"] = UNSAT_STATUS_ONLY_CREDIT
    elif answer == "timeout":
        result["verdict"] = "timeout"
    elif answer == "unknown":
        result["verdict"] = "unknown"
    elif str(answer).startswith("error"):
        result["verdict"] = "error"
    else:
        result["verdict"] = "wrong"
    return result


def evaluate_logic(solver, logic, benchmarks, expected, timeout, parallel, perturb, perturb_salt):
    print(f"\n[{logic}] Evaluating {len(benchmarks)} benchmarks...", flush=True)
    jobs = [(solver, key, path, timeout, perturb, perturb_salt) for key, path in benchmarks]
    results = []
    done = 0
    with ProcessPoolExecutor(max_workers=parallel) as executor:
        futures = [executor.submit(run_solver_case, job) for job in jobs]
        for future in as_completed(futures):
            result = classify_result(future.result(), expected)
            results.append(result)
            done += 1
            if done % 25 == 0 or done == len(jobs):
                print(
                    f"  [{done}/{len(jobs)}] {result['verdict']} "
                    f"{os.path.basename(result['path'])}: {result['answer']} "
                    f"({result['time']:.1f}s)",
                    flush=True,
                )
    order = {key: i for i, (key, _) in enumerate(benchmarks)}
    results.sort(key=lambda r: order[r["benchmark"]])
    return results


def summarize_logic(results):
    total = len(results)
    counts = {
        "correct": 0,
        "wrong": 0,
        "timeout": 0,
        "unknown": 0,
        "error": 0,
        "invalid_model": 0,
        "status_only_unsat": 0,
        "no_reference": 0,
    }
    for result in results:
        counts[result["verdict"]] = counts.get(result["verdict"], 0) + 1
    credit = sum(float(result.get("credit", 0.0) or 0.0) for result in results)
    score = credit / total if total else 0.0
    return {"score": score, "credit": credit, "total": total, **counts}


def summarize_status(results):
    expected_status = {
        "sat": {"total": 0, "correct": 0, "wrong": 0, "invalid_model": 0},
        "unsat": {"total": 0, "status_only": 0, "wrong": 0},
    }
    predicted_status = {status: 0 for status in ["sat", "unsat", "unknown", "timeout", "error"]}
    for result in results:
        exp = result.get("expected")
        verdict = result.get("verdict")
        answer = str(result.get("answer", "error"))
        if answer in {"sat", "unsat", "unknown", "timeout"}:
            predicted_status[answer] += 1
        elif answer.startswith("error"):
            predicted_status["error"] += 1
        if exp in expected_status:
            expected_status[exp]["total"] += 1
        if exp == "sat":
            if verdict == "correct":
                expected_status["sat"]["correct"] += 1
            elif verdict == "invalid_model":
                expected_status["sat"]["invalid_model"] += 1
            else:
                expected_status["sat"]["wrong"] += 1
        elif exp == "unsat":
            if verdict == "status_only_unsat":
                expected_status["unsat"]["status_only"] += 1
            else:
                expected_status["unsat"]["wrong"] += 1
    total = len(results)
    mostly_unsat = total > 0 and predicted_status["unsat"] / total >= 0.80
    mostly_unknown = total > 0 and predicted_status["unknown"] / total >= 0.80
    status_only_heavy = total > 0 and expected_status["unsat"]["status_only"] / total >= 0.20
    return {
        "expected_status_summary": expected_status,
        "predicted_status_summary": predicted_status,
        "anti_guess_flags": {
            "mostly_unsat": mostly_unsat,
            "mostly_unknown": mostly_unknown,
            "status_only_heavy": status_only_heavy,
        },
    }


def main():
    parser = argparse.ArgumentParser(description="Evaluate an SMT solver on SE-Bench SMT benchmarks")
    parser.add_argument("--solver", required=True, help="Path to ./solve executable")
    parser.add_argument("--benchmarks", required=True, help="Benchmark root directory")
    parser.add_argument("--expected", default=None, help="expected_answers.json path")
    parser.add_argument("--manifest", default=None, help="selection_manifest.json path")
    parser.add_argument("--timeout", type=int, default=60, help="Per-case timeout in seconds")
    parser.add_argument("--parallel", type=int, default=1, help="Number of parallel solver processes")
    parser.add_argument("--output", default=None, help="Write detailed JSON results to this path")
    parser.add_argument("--logics", nargs="+", default=LOGICS, choices=LOGICS)
    parser.add_argument(
        "--perturb",
        action="store_true",
        help="Run solvers on satisfiability-preserving perturbed temporary copies.",
    )
    parser.add_argument(
        "--perturb-salt",
        default=os.environ.get("SEBENCH_PERTURB_SALT", "public"),
        help="Salt for deterministic perturbations. Use a private value for final hidden scoring.",
    )
    parser.add_argument(
        "--submission-root",
        default=None,
        help="Submission directory to preflight; defaults to the solver parent directory.",
    )
    parser.add_argument(
        "--skip-preflight",
        action="store_true",
        help="Disable submission preflight checks. Intended only for evaluator smoke tests.",
    )
    parser.add_argument(
        "--difficulties",
        nargs="+",
        choices=["easy", "medium", "hard"],
        default=None,
        help="Optional difficulty filter. By default all cases, including hard, are scored.",
    )
    args = parser.parse_args()

    solver = os.path.abspath(args.solver)
    if not os.path.isfile(solver) or not os.access(solver, os.X_OK):
        print(f"Error: solver is not executable: {args.solver}", file=sys.stderr)
        sys.exit(1)
    if not os.path.isdir(args.benchmarks):
        print(f"Error: benchmark directory does not exist: {args.benchmarks}", file=sys.stderr)
        sys.exit(1)
    if not args.skip_preflight:
        run_preflight(args.submission_root or os.path.dirname(solver), solver)

    benchmark_root = Path(args.benchmarks)
    expected_path = args.expected or str(
        benchmark_root / "expected_answers.json"
        if (benchmark_root / "expected_answers.json").exists()
        else benchmark_root.parent / "hidden_expected_answers.json"
    )
    manifest_path = args.manifest or str(
        benchmark_root / "selection_manifest.json"
        if (benchmark_root / "selection_manifest.json").exists()
        else benchmark_root.parent / "hidden_selection_manifest.json"
    )
    expected = load_expected(expected_path)
    manifest = load_manifest(manifest_path)
    hide_reference_files(args.benchmarks, expected_path, manifest_path)
    benchmarks = find_benchmarks(args.benchmarks, args.logics, manifest, args.difficulties)

    all_results = {}
    logic_summary = {}
    difficulty_results = {difficulty: [] for difficulty in DIFFICULTIES}

    for logic in args.logics:
        logic_benchmarks = benchmarks.get(logic, [])
        if not logic_benchmarks:
            logic_summary[logic] = {
                "score": 0.0,
                "total": 0,
                "correct": 0,
                "wrong": 0,
                "timeout": 0,
                "unknown": 0,
                "error": 0,
                "invalid_model": 0,
                "status_only_unsat": 0,
                "no_reference": 0,
                "credit": 0.0,
            }
            continue
        results = evaluate_logic(
            solver,
            logic,
            logic_benchmarks,
            expected,
            args.timeout,
            args.parallel,
            args.perturb,
            args.perturb_salt,
        )
        for result in results:
            difficulty = manifest.get(result["benchmark"], {}).get("difficulty")
            result["difficulty"] = difficulty
            if difficulty in difficulty_results:
                difficulty_results[difficulty].append(result)
        all_results[logic] = results
        logic_summary[logic] = summarize_logic(results)

    scored_difficulties = args.difficulties or DIFFICULTIES
    difficulty_summary = {}
    final_score = 0.0
    for difficulty in scored_difficulties:
        results = difficulty_results.get(difficulty, [])
        difficulty_summary[difficulty] = summarize_logic(results)
        final_score += WEIGHTS[difficulty] * difficulty_summary[difficulty]["score"]
    flat_results = [result for results in all_results.values() for result in results]
    status_summary = summarize_status(flat_results)

    print("\n" + "=" * 72)
    print("SUMMARY")
    print("=" * 72)
    print("By logic (diagnostic):")
    for logic in args.logics:
        s = logic_summary[logic]
        print(
            f"{logic:8s} score={s['score']:.4f} "
            f"correct={s['correct']}/{s['total']} wrong={s['wrong']} "
            f"status_only_unsat={s.get('status_only_unsat', 0)} "
            f"timeout={s['timeout']} unknown={s['unknown']} "
            f"invalid_model={s.get('invalid_model', 0)} error={s['error']}"
        )
    print("By difficulty (scored):")
    for difficulty in scored_difficulties:
        s = difficulty_summary[difficulty]
        print(
            f"{difficulty:8s} score={s['score']:.4f} weight={WEIGHTS[difficulty]:.2f} "
            f"correct={s['correct']}/{s['total']} wrong={s['wrong']} "
            f"status_only_unsat={s.get('status_only_unsat', 0)} "
            f"timeout={s['timeout']} unknown={s['unknown']} "
            f"invalid_model={s.get('invalid_model', 0)} error={s['error']}"
        )
    print(f"{'FINAL':8s} score={final_score:.6f} score_percent={final_score * 100:.2f}")
    print("=" * 72)

    if args.output:
        output = {
            "final_score": final_score,
            "score_percent": final_score * 100,
            "logic_summary": logic_summary,
            "difficulty_summary": difficulty_summary,
            "weights": WEIGHTS,
            "timeout": args.timeout,
            "parallel": args.parallel,
            "perturb": args.perturb,
            "require_sat_model": True,
            "unsat_status_only_credit": UNSAT_STATUS_ONLY_CREDIT,
            **status_summary,
            "solver": solver,
            "benchmarks": os.path.abspath(args.benchmarks),
            "difficulties": args.difficulties,
            "results": all_results,
        }
        with open(args.output, "w") as f:
            json.dump(output, f, indent=2)
        print(f"\nDetailed results written to {args.output}")


if __name__ == "__main__":
    main()
