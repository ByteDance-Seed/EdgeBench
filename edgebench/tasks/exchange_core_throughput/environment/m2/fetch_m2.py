#!/usr/bin/env python3
"""Rebuild a pinned Maven local repository from Maven Central.

usage: fetch_m2.py <manifest.tsv> <repository dir> [resolver-state.json]

Every manifest line is `sha256<TAB>size<TAB>path`. A `.jar`/`.pom` is downloaded
from $MAVEN_CENTRAL (default https://repo1.maven.org/maven2) + "/" + path. A
`<file>.sha1` is not downloaded: Maven Resolver stores it as the bare 40-hex SHA-1
of <file> (Central's own .sha1 files sometimes carry a file name), so it is
computed from the verified sibling. Every file must match both size and sha256,
otherwise the build fails. The optional JSON file
maps paths to the text of Maven Resolver's bookkeeping files
(_remote.repositories, *.lastUpdated, resolver-status.properties, cached
maven-metadata) that v1's online resolve left behind; they are written verbatim.
Proxies come only from the standard http(s)_proxy environment variables.
"""
import concurrent.futures, hashlib, json, os, sys, time, urllib.request

BASE = os.environ.get('MAVEN_CENTRAL', 'https://repo1.maven.org/maven2').rstrip('/')


def check(data, size, sha, what):
    if len(data) != size or hashlib.sha256(data).hexdigest() != sha:
        raise RuntimeError(f'{what}: checksum mismatch (got {len(data)} bytes, '
                           f'sha256 {hashlib.sha256(data).hexdigest()}, want {size} {sha})')


def write(dest, data):
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    with open(dest, 'wb') as o:
        o.write(data)
    os.chmod(dest, 0o644)


def derive_sha1(entry, repo):
    sha, size, rel = entry
    data = hashlib.sha1(open(os.path.join(repo, rel[:-5]), 'rb').read()).hexdigest().encode()
    check(data, size, sha, rel)
    write(os.path.join(repo, rel), data)


def fetch(entry, repo):
    sha, size, rel = entry
    url = f'{BASE}/{rel}'
    err = None
    for attempt in range(5):
        try:
            with urllib.request.urlopen(url, timeout=60) as r:
                data = r.read()
            break
        except Exception as e:  # network hiccup: retry
            err = e
            time.sleep(2 * (attempt + 1))
    else:
        raise RuntimeError(f'{url}: {err}')
    check(data, size, sha, url)
    write(os.path.join(repo, rel), data)


def main():
    manifest, repo = sys.argv[1], sys.argv[2]
    entries = []
    for line in open(manifest):
        if line.strip() and not line.startswith('#'):
            sha, size, rel = line.rstrip('\n').split('\t')
            entries.append((sha, int(size), rel))
    sums = [e for e in entries if e[2].endswith('.sha1')]
    files = [e for e in entries if not e[2].endswith('.sha1')]
    with concurrent.futures.ThreadPoolExecutor(16) as ex:
        for f in [ex.submit(fetch, e, repo) for e in files]:
            f.result()
    for e in sums:
        derive_sha1(e, repo)
    n_state = 0
    if len(sys.argv) > 3:
        for rel, text in json.load(open(sys.argv[3])).items():
            dest = os.path.join(repo, rel)
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            with open(dest, 'w', encoding='utf-8', newline='') as o:
                o.write(text)
            os.chmod(dest, 0o644)
            n_state += 1
    print(f'fetch_m2: {len(files)} files from {BASE}, {len(sums)} .sha1 derived, {n_state} resolver-state files -> {repo}')


if __name__ == '__main__':
    main()
