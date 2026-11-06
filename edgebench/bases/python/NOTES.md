# base: python

Reproduces v1 `edgebench.base.python` (BENCHMARK.yaml `python`: `python:3.11` +
git curl jq build-essential) minus `sudo` and the `agent` user.

## FROM provenance
`python:3.11@sha256:5359ebb07451406650903c2e97103ed598a2b1fe20da5a227e3eb6b3b5973e14`
(linux/amd64 manifest; Python 3.11.15 on Debian trixie, built 2026-05-08). All 7 rootfs
diff_ids equal the first 7 layers of the published v1 image. Found through the
docker-library/repo-info history (tag `python:3.11`, 2026-05-08..05-19); pinned by the
platform manifest because the multi-arch index digest changed several times for this build.

## Packages
Debian snapshot `20260617T120000Z` (the v1 base was built 2026-06-17 12:15 UTC), explicit
versions: git 1:2.47.3-0+deb13u1, curl 8.14.1-2+deb13u3 (upgrades libcurl* like v1),
jq 1.7.1-6+deb13u2, build-essential 12.12. `git config --global safe.directory '*'` as in v1.

## Diff vs published v1 (verified: dpkg list, full file tree with sha256/mode/owner, env, CMD, WORKDIR)
* Missing on purpose: `sudo` and its dependency `libapparmor1`; the `agent` user/group
  (/etc/passwd, group, shadow, gshadow, subuid, subgid, /home/agent).
* Derived files differ accordingly: `/etc/ld.so.cache`, dpkg status, apt extended_states.
* Everything else is identical, including /etc/apt. Env, `CMD ["python3"]`, empty WORKDIR,
  user root: identical. Python 3.11.15, pip 24.0, gcc 14.2.0, git 2.47.3. Nothing under /tmp.
