#!/usr/bin/env python3
"""Rebuild the v1 `vendor-deps/` directory from crates.io.

Reads vendor-manifest.tsv (dir, name, version, sha256-of-.crate), downloads each
.crate from static.crates.io (or takes it from --cache), checks its sha256,
unpacks it into <out>/<dir> and writes .cargo-checksum.json the way the cargo
release that produced v1's vendor dir did: every file of the .crate except
.gitignore/.gitattributes/.git/.cargo-ok (any depth); checksum JSON compact
with sorted keys. Files below a directory named `target` are hashed into the
checksum but not written (v1's bundle packer dropped them; see NOTES.md).

usage: build_vendor.py --manifest vendor-manifest.tsv --out vendor-deps [--cache DIR] [--jobs N]
"""
import argparse, hashlib, io, json, os, sys, tarfile, urllib.request
from concurrent.futures import ThreadPoolExecutor

SKIP = {".gitignore", ".gitattributes", ".git", ".cargo-ok"}


def fetch(name, version, cache):
    fn = f"{name}-{version}.crate"
    if cache:
        p = os.path.join(cache, fn)
        if os.path.exists(p):
            return open(p, "rb").read()
    url = f"https://static.crates.io/crates/{name}/{fn}"
    for attempt in range(5):
        try:
            with urllib.request.urlopen(url, timeout=120) as r:
                return r.read()
        except Exception as e:  # retry transient errors
            err = e
    raise RuntimeError(f"download failed: {url}: {err}")


def build_one(row, out, cache):
    d, name, version, sha = row
    data = fetch(name, version, cache)
    got = hashlib.sha256(data).hexdigest()
    if got != sha:
        raise RuntimeError(f"sha256 mismatch for {name} {version}: {got} != {sha}")
    dst = os.path.join(out, d)
    prefix = f"{name}-{version}/"
    files = {}
    with tarfile.open(fileobj=io.BytesIO(data), mode="r:gz") as tf:
        for m in tf.getmembers():
            if not m.name.startswith(prefix):
                raise RuntimeError(f"{name}: unexpected member {m.name}")
            rel = m.name[len(prefix):]
            parts = rel.split("/")
            # cargo vendor (the release v1 used) drops VCS/temp files at any depth.
            if not rel or parts[-1] in SKIP:
                continue
            # v1's bundle was packed without any directory named `target`, *after*
            # cargo had written .cargo-checksum.json: those files are listed in the
            # checksum but absent on disk (only cc/src/target/*.rs is affected).
            dropped = "target" in parts[:-1]
            target = os.path.join(dst, rel)
            if m.isdir():
                if not dropped:
                    os.makedirs(target, exist_ok=True)
                continue
            if not m.isfile():
                raise RuntimeError(f"{name}: non-regular member {m.name}")
            blob = tf.extractfile(m).read()
            files[rel] = hashlib.sha256(blob).hexdigest()
            if dropped:
                continue
            os.makedirs(os.path.dirname(target), exist_ok=True)
            with open(target, "wb") as f:
                f.write(blob)
            os.chmod(target, (m.mode & 0o777) & ~0o022)  # tar mode under umask 022
            os.utime(target, (m.mtime, m.mtime))
    ck = json.dumps({"files": files, "package": sha}, separators=(",", ":"), sort_keys=True, ensure_ascii=False)
    with open(os.path.join(dst, ".cargo-checksum.json"), "w", encoding="utf-8") as f:
        f.write(ck)
    return d


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--manifest", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--cache")
    ap.add_argument("--jobs", type=int, default=16)
    a = ap.parse_args()
    rows = []
    for line in open(a.manifest):
        line = line.rstrip("\n")
        if not line or line.startswith("#"):
            continue
        rows.append(line.split("\t"))
    os.makedirs(a.out, exist_ok=True)
    with ThreadPoolExecutor(a.jobs) as ex:
        for d in ex.map(lambda r: build_one(r, a.out, a.cache), rows):
            pass
    print(f"vendored {len(rows)} crates into {a.out}")


if __name__ == "__main__":
    sys.exit(main())
