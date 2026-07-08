#!/usr/bin/env python3
"""Build EdgeBench base images standalone, without building any task images.

Base image tags are deterministic: the tag hashes the (key, spec) entry from
tasks/BENCHMARK.yaml, so an image built from the same BENCHMARK.yaml on any
machine gets the same name, e.g. edgebench.base.cpp:19685ea8d3f4.

Usage:
    python scripts/build_base_images.py --list                 # show keys + resulting tags
    python scripts/build_base_images.py --base cpp python      # build specific keys
    python scripts/build_base_images.py --all                  # build every key in BENCHMARK.yaml
    python scripts/build_base_images.py --all --force-rebuild

Mirrors / proxies are honored via the usual SFORGE_* env vars
(SFORGE_APT_MIRROR_URL, SFORGE_PYPI_INDEX_URL, SFORGE_HTTP_PROXY, ...).
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT))

import docker

from sforge.harness.benchmark import load_benchmark
from sforge.harness.config import load_config
from sforge.harness.docker_build import build_base_image
from sforge.harness.task_spec import JudgeSpec, TaskSpec, WorkSpec


def _stub_spec(benchmark, key: str, platform: str) -> TaskSpec:
    """Minimal TaskSpec carrying just what build_base_image() reads."""
    return TaskSpec(
        task_id=f"__base_{key}",
        name=f"standalone base build ({key})",
        base_image=key,
        platform=platform,
        cwd="/",
        submit_paths=[],
        submit_exclude=[],
        work=WorkSpec(specs_dir="", agent_query=""),
        judge=JudgeSpec(eval_cmd="", eval_timeout=0, parser="pytest_v"),
        benchmark_name=benchmark.name,
        base_image_spec=benchmark.base_images[key],
    )


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--tasks-dir", type=Path, default=REPO_ROOT / "tasks", help="directory holding BENCHMARK.yaml")
    ap.add_argument("--base", nargs="+", metavar="KEY", help="base image keys to build (e.g. cpp python)")
    ap.add_argument("--all", action="store_true", help="build every base key in BENCHMARK.yaml")
    ap.add_argument("--list", action="store_true", help="list base keys and their deterministic tags, then exit")
    ap.add_argument("--platform", default="linux/amd64")
    ap.add_argument("--force-rebuild", action="store_true")
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args()

    benchmark = load_benchmark(args.tasks_dir)

    if args.list:
        for key in sorted(benchmark.base_images):
            spec = _stub_spec(benchmark, key, args.platform)
            print(f"{key:24s} -> {spec.base_image_tag}   (FROM {benchmark.base_images[key]['official_image']})")
        return 0

    if args.all:
        keys = sorted(benchmark.base_images)
    elif args.base:
        keys = args.base
    else:
        ap.error("choose --list, --base KEY..., or --all")

    unknown = [k for k in keys if k not in benchmark.base_images]
    if unknown:
        ap.error(f"unknown base key(s) {unknown}; available: {sorted(benchmark.base_images)}")

    config = load_config()
    client = docker.from_env()

    failures = []
    for key in keys:
        spec = _stub_spec(benchmark, key, args.platform)
        print(f"[build] {key} -> {spec.base_image_tag}", flush=True)
        try:
            tag = build_base_image(
                spec, config, client,
                force_rebuild=args.force_rebuild,
                verbose=args.verbose,
            )
            print(f"[done ] {tag}", flush=True)
        except Exception as exc:  # noqa: BLE001 - report per-key and continue
            print(f"[fail ] {key}: {exc}", flush=True)
            failures.append(key)

    if failures:
        print(f"FAILED: {failures}")
        return 1
    print("all requested base images built")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
