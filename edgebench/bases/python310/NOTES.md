# base: python310

Reproduces v1 `edgebench.base.python310` (BENCHMARK.yaml `python310`: `python:3.10` +
git curl jq build-essential) minus `sudo` and the `agent` user.

## FROM provenance
`python:3.10@sha256:11a7f29da0d339f0bbf647555e082015da58509f493f196ddc3512858f0311f3`
(Python 3.10.20 on Debian trixie, built 2026-05-08). All 7 rootfs diff_ids equal the
first 7 layers of the published v1 image.

## Packages
Debian snapshot `20260609T060000Z` (the v1 base was built 2026-06-09 06:04 UTC), explicit
versions: git 1:2.47.3-0+deb13u1, curl 8.14.1-2+deb13u3 (upgrades libcurl* like v1),
jq 1.7.1-6+deb13u2, build-essential 12.12. `git config --global safe.directory '*'` as in v1.

## Diff vs published v1 (verified: dpkg list, full file tree with sha256/mode/owner, env, CMD, WORKDIR)
* Missing on purpose: `sudo` and its dependency `libapparmor1`; the `agent` user/group
  (/etc/passwd, group, shadow, gshadow, subuid, subgid, /home/agent).
* `/etc/apt/sources.list.d/debian.sources` is the stock upstream file (v1 pointed it at an
  internal mirror).
* Derived files differ accordingly: `/etc/ld.so.cache`, dpkg status, apt extended_states.
* Everything else is identical. Env, `CMD ["python3"]`, empty WORKDIR, user root: identical.
  Python 3.10.20, pip 23.0.1, gcc 14.2.0, git 2.47.3. Nothing under /tmp.
