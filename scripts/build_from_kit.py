#!/usr/bin/env python3
"""Build an EdgeBench work/judge image from a build kit, and verify the result.

A kit directory (produced by export_task_kit.py) contains:
    Dockerfile, context.tar, MANIFEST.sha256, kit.json

Prerequisite: the base image named in the Dockerfile's FROM line already exists
locally — build it from tasks/BENCHMARK.yaml with scripts/build_base_images.py.
Base tags are deterministic, so a base built from the same BENCHMARK.yaml
anywhere resolves the FROM line with no retagging.

Usage:
    python3 build_from_kit.py --kit kits/ad_placement_optimization/work --verify
    python3 build_from_kit.py --kits-root kits --verify          # every */work, */judge

Only needs python3 stdlib + the docker CLI.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
import tarfile
import tempfile
from pathlib import Path

MANIFEST_RE = re.compile(r"^(\S+)  (0o\d+) (\d+):(\d+) +(\d+)  /(.*)$")


def run(cmd: list[str], **kw) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, check=True, **kw)


def image_exists(ref: str) -> bool:
    return subprocess.run(["docker", "image", "inspect", ref],
                          capture_output=True).returncode == 0


def build_kit(kit_dir: Path) -> str:
    kit = json.loads((kit_dir / "kit.json").read_text())
    final_name, from_tag = kit["final_name"], kit["from_tag"]

    if not image_exists(from_tag):
        sys.exit(f"ERROR: base image '{from_tag}' not found locally.\n"
                 f"Build it first: python3 scripts/build_base_images.py --base <key>")

    print(f"[build] {kit_dir} -> {final_name}")
    run(["docker", "build", "-t", final_name, str(kit_dir)])
    return final_name


def verify_kit(kit_dir: Path, image: str) -> bool:
    """Export the built image and check every MANIFEST entry + every deletion."""
    entries = []
    for line in (kit_dir / "MANIFEST.sha256").read_text().splitlines():
        m = MANIFEST_RE.match(line)
        if not m:
            sys.exit(f"ERROR: unparseable manifest line: {line}")
        entries.append(m.groups())  # (digest, mode, uid, gid, size, path)
    kit = json.loads((kit_dir / "kit.json").read_text())
    if "deletions" in kit:
        deletions = kit["deletions"]
    else:  # older kit layout kept them in a sidecar file
        dt = kit_dir / "deletions.txt"
        deletions = [d.strip() for d in dt.read_text().splitlines() if d.strip()] if dt.is_file() else []

    print(f"[verify] exporting {image} ...")
    with tempfile.TemporaryDirectory() as td:
        export = Path(td) / "rootfs.tar"
        cid = subprocess.run(["docker", "create", image], check=True,
                             capture_output=True, text=True).stdout.strip()
        try:
            run(["docker", "export", cid, "-o", str(export)])
        finally:
            subprocess.run(["docker", "rm", cid], capture_output=True)

        seen: dict[str, tuple] = {}  # path -> (kind, digest, mode, uid, gid)
        with tarfile.open(export) as t:
            for mem in t:
                p = mem.name.strip("/").removeprefix("./")
                if mem.isreg():
                    h = hashlib.sha256()
                    f = t.extractfile(mem)
                    for chunk in iter(lambda: f.read(1 << 20), b""):
                        h.update(chunk)
                    seen[p] = ("file", h.hexdigest(), mem.mode, mem.uid, mem.gid)
                elif mem.issym():
                    seen[p] = ("symlink", mem.linkname, mem.mode, mem.uid, mem.gid)
                elif mem.isdir():
                    seen[p] = ("dir", None, mem.mode, mem.uid, mem.gid)
                elif mem.islnk():
                    seen[p] = ("hardlink", mem.linkname.strip("/"), mem.mode, mem.uid, mem.gid)

        bad = 0
        manifest_paths = set()
        for digest, mode_s, uid_s, gid_s, _size, path in entries:
            path = path.rstrip("/")
            manifest_paths.add(path)
            got = seen.get(path)
            mode, uid, gid = int(mode_s, 8), int(uid_s), int(gid_s)
            if got is None:
                print(f"  MISSING  /{path}"); bad += 1; continue
            kind, gdigest, gmode, guid, ggid = got
            want_kind = ("dir" if digest == "dir"
                         else "symlink" if digest.startswith("symlink->")
                         else "hardlink" if digest.startswith("hardlink->")
                         else "file")
            ok_content = (
                (want_kind == "dir" and kind == "dir")
                or (want_kind == "symlink" and kind == "symlink" and gdigest == digest[len("symlink->"):])
                or (want_kind == "hardlink" and kind in ("hardlink", "file"))
                or (want_kind == "file" and kind == "file" and gdigest == digest)
            )
            if not ok_content:
                print(f"  CONTENT  /{path}  want {digest[:32]} got {kind}:{str(gdigest)[:32]}"); bad += 1
            if (gmode, guid, ggid) != (mode, uid, gid):
                print(f"  META     /{path}  want {oct(mode)} {uid}:{gid} got {oct(gmode)} {guid}:{ggid}"); bad += 1

        for d in deletions:
            if d in seen and d not in manifest_paths:
                print(f"  UNDELETED  /{d}"); bad += 1

        print(f"[verify] {len(entries)} manifest entries, {len(deletions)} deletions, "
              f"{bad} problem(s) -> {'FAIL' if bad else 'OK'}")
        return bad == 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--kit", type=Path, help="one kit directory")
    ap.add_argument("--kits-root", type=Path, help="root holding <task>/{work,judge} kits")
    ap.add_argument("--verify", action="store_true", help="verify built image against MANIFEST.sha256")
    args = ap.parse_args()

    if bool(args.kit) == bool(args.kits_root):
        ap.error("choose exactly one of --kit / --kits-root")

    kits = [args.kit] if args.kit else sorted(
        p for p in args.kits_root.glob("*/*") if (p / "kit.json").is_file())
    if not kits:
        sys.exit("no kits found")

    failures = []
    for kit_dir in kits:
        try:
            image = build_kit(kit_dir)
            if args.verify and not verify_kit(kit_dir, image):
                failures.append(str(kit_dir))
        except subprocess.CalledProcessError as exc:
            print(f"[fail ] {kit_dir}: {exc}")
            failures.append(str(kit_dir))

    if failures:
        print(f"FAILED: {failures}")
        return 1
    print(f"all {len(kits)} kit(s) built" + (" and verified" if args.verify else ""))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
