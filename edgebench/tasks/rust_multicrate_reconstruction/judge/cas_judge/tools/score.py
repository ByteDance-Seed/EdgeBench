#!/usr/bin/env python3
"""
CAS Benchmark Scorer

Runs cargo test per crate, classifies failures, and computes weighted
L0-L9 layer scores. Hidden test scoring prefers --hidden-source-dir
snippet injection: the agent workspace is copied to a temporary directory,
hidden Rust test snippets are restored into their original files, and cargo
tests run against that temporary workspace. --original-dir remains only as a
legacy fallback when hidden snippets are unavailable.

Usage:
    python3 tools/score.py --workspace /path/to/submission --manifest hidden-tests/split-manifest.json --hidden-source-dir hidden-tests/hidden-sources --output results.json
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
import time
import re
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Optional

LAYER_CONFIG = [
    {"layer": "L0", "crates": ["cas-types"], "weight": 13},
    {"layer": "L1", "crates": ["cas-code"], "weight": 8},
    {"layer": "L2", "crates": ["cas-factory-protocol", "cas-diffs"], "weight": 10},
    {"layer": "L3", "crates": ["cas-pty", "cas-recording"], "weight": 4},
    {"layer": "L4", "crates": ["cas-store"], "weight": 15},
    {"layer": "L5", "crates": ["cas-search"], "weight": 12},
    {"layer": "L6", "crates": ["cas-core"], "weight": 15},
    {"layer": "L7", "crates": ["cas-mux", "cas-factory"], "weight": 8},
    {"layer": "L8", "crates": ["cas-mcp", "cas-tui-test"], "weight": 5},
    {"layer": "L9", "crates": ["cas-cli"], "weight": 10},
]

CRATE_TO_PACKAGE = {
    "cas-cli": "cas", "cas-types": "cas-types", "cas-code": "cas-code",
    "cas-store": "cas-store", "cas-search": "cas-search", "cas-core": "cas-core",
    "cas-mcp": "cas-mcp", "cas-mux": "cas-mux", "cas-pty": "cas-pty",
    "cas-recording": "cas-recording", "cas-factory-protocol": "cas-factory-protocol",
    "cas-diffs": "cas-diffs", "cas-factory": "cas-factory", "cas-tui-test": "cas-tui-test",
}

DEPENDENCY_GRAPH = {
    "cas-types": [], "cas-code": ["cas-types"], "cas-pty": [], "cas-recording": [],
    "cas-factory-protocol": [], "cas-diffs": [],
    "cas-store": ["cas-types", "cas-code"],
    "cas-search": ["cas-types", "cas-code", "cas-store"],
    "cas-core": ["cas-types", "cas-store"],
    "cas-mux": ["cas-recording", "cas-factory-protocol", "cas-pty"],
    "cas-factory": ["cas-mux", "cas-pty", "cas-store", "cas-recording", "cas-factory-protocol", "cas-types"],
    "cas-mcp": ["cas-types", "cas-store", "cas-core"],
    "cas-tui-test": [],
    "cas-cli": ["cas-types", "cas-store", "cas-core", "cas-code", "cas-diffs", "cas-search",
                "cas-mux", "cas-recording", "cas-factory-protocol", "cas-factory"],
}

KNOWN_FAILURES = {
    "cas-pty": ["pty::tests::test_pty_config_claude_with_teams"],
    "cas-cli": ["factory_mcp_ops_test"],
}

KNOWN_CRASH_CRATES = {"cas-mux"}
KNOWN_CRASH_SIGNATURES = {
    # The original cas-mux tests can abort inside the Ghostty VT stub before
    # libtest prints per-test results. Only normalize that specific native
    # crash family; arbitrary no-output crashes remain score loss.
    "cas-mux": (
        "signal:",
        "sigsegv",
        "segmentation fault",
        "memory allocation",
        "libghostty",
        "ghostty",
    ),
}
INFRA_STATUSES = {"ERROR", "TIMEOUT", "NO_TESTS"}

HIDDEN_TESTS_BY_CRATE = {}

# Fixed denominator from the vetted original-repository scoring run.  Keeping
# these totals in the scorer prevents denominator drift when an agent submission
# breaks compilation or aborts before all test binaries execute.
EXPECTED_TOTALS = {
    "cas-types": 136,
    "cas-code": 50,
    "cas-factory-protocol": 98,
    "cas-diffs": 98,
    "cas-pty": 11,
    "cas-recording": 29,
    "cas-store": 216,
    "cas-search": 136,
    "cas-core": 201,
    "cas-mux": 37,
    "cas-factory": 134,
    "cas-mcp": 16,
    "cas-tui-test": 105,
    "cas-cli": 1344,
}

def load_split_manifest(manifest_path):
    """Load split manifest and build per-crate hidden test name sets."""
    global HIDDEN_TESTS_BY_CRATE
    if not os.path.exists(manifest_path):
        return
    m = json.load(open(manifest_path))
    for t in m.get("hidden_tests", []):
        crate = t["crate"]
        fn_name = t["fn_name"]
        HIDDEN_TESTS_BY_CRATE.setdefault(crate, set()).add(fn_name)


def ignore_top_level_target(root_dir, skip_vendor=False):
    """Return a copytree ignore function for bulky top-level build/cache dirs."""
    def _ignore(directory, contents):
        ignored = []
        if os.path.relpath(directory, root_dir) == ".":
            if "target" in contents:
                ignored.append("target")
            if skip_vendor and "vendor-deps" in contents:
                ignored.append("vendor-deps")
        return ignored
    return _ignore


def copy_workspace_tree(src, dst, share_vendor=True):
    """Copy a workspace for scoring without duplicating target/ or vendored deps."""
    src_path = Path(src)
    dst_path = Path(dst)
    shutil.copytree(src_path, dst_path, symlinks=False,
                    ignore=ignore_top_level_target(src_path, skip_vendor=share_vendor))

    if share_vendor:
        vendor_src = src_path / "vendor-deps"
        vendor_dst = dst_path / "vendor-deps"
        if vendor_src.exists() and not vendor_dst.exists():
            try:
                os.symlink(vendor_src.resolve(), vendor_dst, target_is_directory=True)
            except OSError:
                shutil.copytree(vendor_src, vendor_dst, symlinks=True)


def find_cfg_test_module_close(content):
    """Find the closing brace of the last #[cfg(test)] module in a Rust file."""
    anchor = content.rfind("#[cfg(test)]")
    if anchor == -1:
        anchor = content.rfind("#[cfg(all(")
    if anchor == -1:
        return None
    mod_pos = content.find("mod ", anchor)
    if mod_pos == -1:
        return None
    open_pos = content.find("{", mod_pos)
    if open_pos == -1:
        return None

    depth = 0
    for i in range(open_pos, len(content)):
        ch = content[i]
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return i
    return None


def inject_hidden_tests(workspace_dir, hidden_source_dir):
    """Inject hidden test snippets back into a copied agent workspace."""
    hidden_root = Path(hidden_source_dir)
    if not hidden_root.exists():
        return 0

    injected = 0
    for snippet_file in sorted(hidden_root.rglob("*.rs")):
        rel = snippet_file.relative_to(hidden_root)
        dest = Path(workspace_dir) / rel
        if not dest.exists():
            continue

        snippets = snippet_file.read_text(errors="replace").strip()
        if not snippets:
            continue

        content = dest.read_text(errors="replace")
        names = re.findall(r"\bfn\s+([A-Za-z_][A-Za-z0-9_]*)", snippets)
        if names and all(f"fn {name}" in content for name in names):
            continue

        rel_str = str(rel)
        if "/tests/" in rel_str or rel_str.startswith("cas-cli/tests/"):
            content = content.rstrip() + "\n\n" + snippets + "\n"
        else:
            insert_at = find_cfg_test_module_close(content)
            if insert_at is None:
                content = content.rstrip() + "\n\n" + snippets + "\n"
            else:
                content = content[:insert_at].rstrip() + "\n\n" + snippets + "\n" + content[insert_at:]

        dest.write_text(content)
        injected += len(names) if names else 1

    return injected


def is_known_crash(crate_name, stdout, stderr):
    """Return true only for a narrowly recognized native crash signature."""
    haystack = f"{stdout}\n{stderr}".lower()
    return any(sig in haystack for sig in KNOWN_CRASH_SIGNATURES.get(crate_name, ()))


@dataclass
class CrateResult:
    crate_name: str
    package_name: str
    status: str
    passed: int
    failed: int
    total: int
    public_passed: int
    public_failed: int
    hidden_passed: int
    hidden_failed: int
    blocked_by: Optional[str]
    duration_sec: float
    error_message: Optional[str]


def run_crate_test(workspace_dir, crate_name, timeout_sec):
    pkg = CRATE_TO_PACKAGE.get(crate_name, crate_name)
    expected_total = EXPECTED_TOTALS.get(crate_name, 0)
    start = time.time()

    try:
        discovery_timeout = max(300, min(timeout_sec, 1800))
        lr = subprocess.run(
            ["cargo", "test", "--frozen", "-p", pkg, "--", "--list"],
            capture_output=True, text=True, timeout=discovery_timeout, cwd=workspace_dir,
            env={**os.environ, "RUST_BACKTRACE": "0"})
    except subprocess.TimeoutExpired:
        return CrateResult(crate_name=crate_name, package_name=pkg,
            status="TIMEOUT", passed=0, failed=expected_total, total=expected_total,
            public_passed=0, public_failed=0, hidden_passed=0, hidden_failed=0,
            blocked_by=None, duration_sec=time.time()-start,
            error_message=f"Test discovery timed out after {discovery_timeout:.0f}s")
    except Exception as e:
        return CrateResult(crate_name=crate_name, package_name=pkg,
            status="ERROR", passed=0, failed=expected_total, total=expected_total,
            public_passed=0, public_failed=0, hidden_passed=0, hidden_failed=0,
            blocked_by=None, duration_sec=time.time()-start,
            error_message=f"Test discovery failed: {e}")
    if lr.returncode != 0 and "could not compile" in lr.stderr:
        return CrateResult(crate_name=crate_name, package_name=pkg,
            status="COMPILE_FAIL_ROOT", passed=0, failed=expected_total, total=expected_total,
            public_passed=0, public_failed=0, hidden_passed=0, hidden_failed=0,
            blocked_by=None, duration_sec=time.time()-start, error_message=lr.stderr[:500])
    discovered = sum(1 for l in lr.stdout.splitlines() if l.strip().endswith(": test"))
    discovered = max(discovered, expected_total)

    try:
        result = subprocess.run(
            ["cargo", "test", "--frozen", "-p", pkg, "--", "--test-threads=4"],
            capture_output=True, text=True, timeout=timeout_sec,
            cwd=workspace_dir,
            env={**os.environ, "RUST_BACKTRACE": "0"},
        )
        duration = time.time() - start
        stdout, stderr = result.stdout, result.stderr

        if result.returncode != 0 and "could not compile" in stderr:
            return CrateResult(crate_name=crate_name, package_name=pkg,
                status="COMPILE_FAIL_ROOT", passed=0, failed=expected_total, total=expected_total,
                public_passed=0, public_failed=0, hidden_passed=0, hidden_failed=0,
                blocked_by=None, duration_sec=duration, error_message=stderr[:500])

        passed, failed = 0, 0
        pub_passed, pub_failed, hid_passed, hid_failed = 0, 0, 0, 0
        hidden_set = HIDDEN_TESTS_BY_CRATE.get(crate_name, set())

        for line in stdout.splitlines():
            if line.startswith("test result:"):
                parts = line.split()
                for i, part in enumerate(parts):
                    if part == "passed;": passed += int(parts[i - 1])
                    elif part == "failed;": failed += int(parts[i - 1])
            elif line.startswith("test ") and (" ... " in line):
                parts = line.split(" ... ")
                test_path = parts[0].replace("test ", "").strip()
                test_fn = test_path.rsplit("::", 1)[-1] if "::" in test_path else test_path
                result_str = parts[1].strip() if len(parts) > 1 else ""
                is_hidden = test_fn in hidden_set
                if result_str == "ok":
                    if is_hidden: hid_passed += 1
                    else: pub_passed += 1
                elif result_str == "FAILED":
                    if is_hidden: hid_failed += 1
                    else: pub_failed += 1

        known = KNOWN_FAILURES.get(crate_name, [])
        if known and failed > 0:
            for test_name in known:
                if test_name in stdout:
                    failed -= 1
                    passed += 1
                    pub_passed += 1
                    pub_failed = max(0, pub_failed - 1)

        executed = passed + failed

        if executed == 0 and result.returncode != 0 and discovered > 0:
            if crate_name in KNOWN_CRASH_CRATES and is_known_crash(crate_name, stdout, stderr):
                return CrateResult(crate_name=crate_name, package_name=pkg,
                    status="TEST_CRASH", passed=0, failed=discovered, total=discovered,
                    public_passed=0, public_failed=0, hidden_passed=0, hidden_failed=0,
                    blocked_by=None, duration_sec=duration,
                    error_message=f"Known crash signature observed ({discovered} tests lost)")
            return CrateResult(crate_name=crate_name, package_name=pkg,
                status="TEST_CRASH", passed=0, failed=discovered, total=discovered,
                public_passed=0, public_failed=0, hidden_passed=0, hidden_failed=0,
                blocked_by=None, duration_sec=duration,
                error_message=f"Test binary crashed ({discovered} tests lost)")

        total = max(discovered, executed)
        if total > executed:
            failed += (total - executed)

        status = "PASS" if failed == 0 and total > 0 else "TEST_FAIL"
        if total == 0 and result.returncode == 0:
            status = "NO_TESTS"

        return CrateResult(crate_name=crate_name, package_name=pkg, status=status,
            passed=passed, failed=failed, total=total,
            public_passed=pub_passed, public_failed=pub_failed,
            hidden_passed=hid_passed, hidden_failed=hid_failed,
            blocked_by=None, duration_sec=duration, error_message=None)

    except subprocess.TimeoutExpired:
        return CrateResult(crate_name=crate_name, package_name=pkg, status="TIMEOUT",
            passed=0, failed=expected_total, total=expected_total, public_passed=0, public_failed=0,
            hidden_passed=0, hidden_failed=0, blocked_by=None,
            duration_sec=time.time()-start, error_message=f"Timeout after {timeout_sec}s")
    except Exception as e:
        return CrateResult(crate_name=crate_name, package_name=pkg, status="ERROR",
            passed=0, failed=expected_total, total=expected_total, public_passed=0, public_failed=0,
            hidden_passed=0, hidden_failed=0, blocked_by=None,
            duration_sec=time.time()-start, error_message=str(e))


def classify_downstream_failures(results):
    root_failures = {r.crate_name for r in results if r.status == "COMPILE_FAIL_ROOT"}
    if not root_failures:
        return
    for r in results:
        if r.status == "COMPILE_FAIL_ROOT":
            deps = DEPENDENCY_GRAPH.get(r.crate_name, [])
            failed_deps = [d for d in deps if d in root_failures and d != r.crate_name]
            if failed_deps:
                r.status = "COMPILE_FAIL_DOWNSTREAM"
                r.blocked_by = failed_deps[0]


def compute_score(results, layer_config):
    crate_results = {r.crate_name: r for r in results}
    layers = []
    total_score = 0.0
    for layer_def in layer_config:
        layer_name, weight, crates = layer_def["layer"], layer_def["weight"], layer_def["crates"]
        layer_passed, layer_total, layer_statuses = 0, 0, []
        for cn in crates:
            r = crate_results.get(cn)
            if r is None: continue
            layer_passed += r.passed
            layer_total += r.total
            layer_statuses.append(r.status)
        layer_score = weight * (layer_passed / layer_total) if layer_total > 0 else 0.0
        worst = "PASS"
        for s in ["COMPILE_FAIL_ROOT", "COMPILE_FAIL_DOWNSTREAM", "TEST_CRASH", "TIMEOUT", "TEST_FAIL"]:
            if s in layer_statuses:
                worst = s
                break
        total_score += layer_score
        layers.append({"layer": layer_name, "weight": weight, "crates": crates,
                       "passed": layer_passed, "total": layer_total,
                       "score": round(layer_score, 4), "status": worst})
    return round(total_score, 4), layers


def determine_score_status(results, hidden_source_dir=None, injected_hidden_count=None):
    """Return top-level SCORE_STATUS and machine-readable infra errors."""
    infra_errors = []
    for r in results:
        if r.status in INFRA_STATUSES:
            infra_errors.append(f"{r.crate_name}:{r.status}:{r.error_message or ''}".rstrip(":"))

    if HIDDEN_TESTS_BY_CRATE and hidden_source_dir and injected_hidden_count == 0:
        infra_errors.append("hidden test injection produced zero snippets")

    return ("INFRA_FAIL" if infra_errors else "OK"), infra_errors


def run_all_crates(workspace_dir, all_crates, timeout_per_crate, timeout_total, label=""):
    results = []
    total_start = time.time()
    for crate_name in all_crates:
        elapsed = time.time() - total_start
        if elapsed > timeout_total:
            pkg = CRATE_TO_PACKAGE.get(crate_name, crate_name)
            results.append(CrateResult(crate_name=crate_name, package_name=pkg,
                status="TIMEOUT", passed=0, failed=0, total=0,
                public_passed=0, public_failed=0, hidden_passed=0, hidden_failed=0,
                blocked_by=None, duration_sec=0, error_message="Total timeout exceeded"))
            continue
        remaining = min(timeout_per_crate, timeout_total - elapsed)
        print(f"  [{label}] Testing {crate_name}...", end=" ", flush=True)
        result = run_crate_test(workspace_dir, crate_name, remaining)
        print(f"{result.status} ({result.passed}/{result.total}) in {result.duration_sec:.1f}s")
        results.append(result)
    classify_downstream_failures(results)
    return results


def score_workspace(workspace_dir, original_dir=None, timeout_per_crate=1800, timeout_total=14400,
                    public_test_workspace=None, hidden_source_dir=None):
    """Score CAS workspace.

    For agent scoring: --workspace is agent submission; --hidden-source-dir enables hidden snippet injection. --original-dir is a legacy fallback only.
    For original baseline: --workspace is original repo, --public-test-workspace is skeleton
    (which has public tests only). Public phase runs original code + public tests, combined
    runs original code + all tests.
    """
    import tempfile

    all_crates = []
    for ld in LAYER_CONFIG:
        all_crates.extend(ld["crates"])

    if public_test_workspace:
        ptw_dir = tempfile.mkdtemp(prefix="cas-pub-orig-")
        pub_ws = os.path.join(ptw_dir, "ws")
        print(f"\n=== Creating public-original workspace ===")

        copy_workspace_tree(public_test_workspace, pub_ws, share_vendor=True)

        copied = 0
        for rs_file in Path(workspace_dir).rglob("*.rs"):
            rel = rs_file.relative_to(workspace_dir)
            rel_str = str(rel)
            if rel_str.startswith("vendor") or rel_str.startswith("target") or rel_str.startswith("."): continue
            if "/tests/" in rel_str or rel_str.endswith("_test.rs"): continue
            dest = Path(pub_ws) / rel
            if dest.exists():
                shutil.copy2(rs_file, dest)
                copied += 1
        print(f"  Overlaid {copied} original .rs onto skeleton (public tests only)")

        print("\n=== Public Tests (original code + public tests) ===")
        public_results = run_all_crates(pub_ws, all_crates, timeout_per_crate, timeout_total // 2, label="public")

        print("\n=== Combined Tests (original code + all tests) ===")
        combined_results = run_all_crates(workspace_dir, all_crates, timeout_per_crate, timeout_total // 2, label="combined")
        shutil.rmtree(ptw_dir, ignore_errors=True)
    else:
        print("\n=== Public Tests (agent workspace) ===")
        public_results = run_all_crates(workspace_dir, all_crates, timeout_per_crate, timeout_total // 2, label="public")

        combined_results = list(public_results)

        injected_hidden_count = None
        if hidden_source_dir and os.path.exists(hidden_source_dir):
            temp_dir = tempfile.mkdtemp(prefix="cas-hidden-inject-")
            combined_ws = os.path.join(temp_dir, "ws")
            print(f"\n=== Creating hidden-test workspace at {combined_ws} ===")
            copy_workspace_tree(workspace_dir, combined_ws, share_vendor=True)
            injected_hidden_count = inject_hidden_tests(combined_ws, hidden_source_dir)
            print(f"  Injected {injected_hidden_count} hidden test snippets")

            print("\n=== Combined Tests (agent code + public and hidden tests) ===")
            combined_results = run_all_crates(combined_ws, all_crates, timeout_per_crate, timeout_total // 2, label="combined")
            shutil.rmtree(temp_dir, ignore_errors=True)

        elif original_dir and os.path.exists(original_dir):
            temp_dir = tempfile.mkdtemp(prefix="cas-hidden-")
            combined_ws = os.path.join(temp_dir, "ws")
            print(f"\n=== Creating overlay workspace at {combined_ws} ===")
            print("  WARNING: falling back to original-dir overlay; hidden inline tests may be erased by source overlay")

            copy_workspace_tree(original_dir, combined_ws, share_vendor=True)

            copied = 0
            for rs_file in Path(workspace_dir).rglob("*.rs"):
                rel = rs_file.relative_to(workspace_dir)
                rel_str = str(rel)
                if rel_str.startswith("vendor") or rel_str.startswith("target") or rel_str.startswith("."): continue
                if "/tests/" in rel_str or rel_str.endswith("_test.rs"): continue
                dest = Path(combined_ws) / rel
                if dest.exists():
                    shutil.copy2(rs_file, dest)
                    copied += 1
            print(f"  Overlaid {copied} agent .rs files (excluding test files)")

            print("\n=== Combined Tests (agent code + all original tests) ===")
            combined_results = run_all_crates(combined_ws, all_crates, timeout_per_crate, timeout_total // 2, label="combined")
            shutil.rmtree(temp_dir, ignore_errors=True)

    combined_score, combined_layers = compute_score(combined_results, LAYER_CONFIG)
    public_score, public_layers = compute_score(public_results, LAYER_CONFIG)
    raw_passed = sum(r.passed for r in combined_results)
    raw_total = sum(EXPECTED_TOTALS.get(r.crate_name, r.total) for r in combined_results)

    score_status, infra_errors = determine_score_status(
        combined_results,
        hidden_source_dir=hidden_source_dir,
        injected_hidden_count=locals().get("injected_hidden_count"),
    )

    return {
        "total_score": combined_score, "public_score": public_score, "max_score": 100.0,
        "score_status": score_status,
        "infra_errors": infra_errors,
        "raw_passed": raw_passed, "raw_total": raw_total,
        "weighted_passed": combined_score, "weighted_total": 100.0,
        "total_duration_sec": round(sum(r.duration_sec for r in combined_results), 2),
        "layers": combined_layers, "public_layers": public_layers,
        "crates": [asdict(r) for r in combined_results],
    }


def main():
    ap = argparse.ArgumentParser(description="CAS Benchmark Scorer")
    ap.add_argument("--workspace", required=True, help="Path to agent submission workspace")
    ap.add_argument("--original-dir", help="Legacy fallback path to original repo for overlay scoring when hidden snippets are unavailable")
    ap.add_argument("--public-test-workspace", help="Path to skeleton for original baseline public/hidden split")
    ap.add_argument("--manifest", help="Path to split-manifest.json for public/hidden classification")
    ap.add_argument("--hidden-source-dir", help="Path to extracted hidden test snippets for injection")
    ap.add_argument("--timeout-per-crate", type=int, default=1800)
    ap.add_argument("--timeout-total", type=int, default=14400)
    ap.add_argument("--output", help="JSON output path")
    args = ap.parse_args()

    if args.manifest:
        load_split_manifest(args.manifest)
        print(f"Loaded manifest: {sum(len(v) for v in HIDDEN_TESTS_BY_CRATE.values())} hidden test names across {len(HIDDEN_TESTS_BY_CRATE)} crates")
    hidden_source_dir = args.hidden_source_dir
    if hidden_source_dir is None and args.manifest:
        candidate = os.path.join(os.path.dirname(args.manifest), "hidden-sources")
        if os.path.exists(candidate):
            hidden_source_dir = candidate

    print("CAS Benchmark Scorer")
    print(f"Workspace: {args.workspace}")
    if args.original_dir: print(f"Original: {args.original_dir}")
    if args.public_test_workspace: print(f"Public tests: {args.public_test_workspace}")
    if hidden_source_dir: print(f"Hidden sources: {hidden_source_dir}")
    print(f"Timeout: {args.timeout_per_crate}s/crate, {args.timeout_total}s total\n")

    result = score_workspace(args.workspace, original_dir=args.original_dir,
                             timeout_per_crate=args.timeout_per_crate, timeout_total=args.timeout_total,
                             public_test_workspace=args.public_test_workspace,
                             hidden_source_dir=hidden_source_dir)

    output_json = json.dumps(result, indent=2)
    if args.output:
        with open(args.output, "w") as f: f.write(output_json)
        print(f"\nResults written to {args.output}")
    else:
        print(f"\n{output_json}")
    print(f"\nFinal Score: {result['total_score']}/{result['max_score']}")


if __name__ == "__main__":
    main()
