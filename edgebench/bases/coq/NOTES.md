# base: coq

Reproduces v1 `edgebench.base.coq` (BENCHMARK.yaml `coq`: `coqorg/coq:8.20` + git curl jq
build-essential gcc g++ python3 make procps; `USER root`; `PATH=/home/coq/.opam/${COMPILER}/bin:$PATH`;
`chmod -R a+rX /home/coq/.opam`; `ENTRYPOINT []`) minus `sudo` and the `agent` user.

## FROM provenance
`coqorg/coq:8.20@sha256:e50d77c4c5a9aa0d76ae1b343d79c5f922da3a75054b79c5dc635895438e4674`
(Coq 8.20.1, OCaml 4.13.1+flambda, opam 2.3.0, dune 3.17.2, Debian 12 bookworm, built
2026-03-30). All 7 rootfs diff_ids equal the first 7 layers of the published v1 image.

## Packages
Debian snapshot `20260617T120000Z` (v1 base built 2026-06-17 12:10 UTC), explicit versions:
git 1:2.39.5-0+deb12u3, curl 7.88.1-10+deb12u14, jq 1.6-2.1+deb12u1, build-essential 12.9,
gcc/g++ 4:12.2.0-3, python3 3.11.2-1+b1, make 4.3-4.1, procps 2:4.0.2-3. Stock
`debian.sources` restored afterwards. Like v1, the image's `coq` user is deleted
(`userdel coq`); /home/coq keeps numeric owner 1000:1000 (in v1 uid 1000 was `agent`).

## Diff vs published v1 (verified: dpkg list, full file tree with sha256/mode/owner, env,
## ENTRYPOINT/CMD, WORKDIR, toolchain versions)
* Missing on purpose: `sudo`. The upstream image already ships sudo (v1 upgraded it to
  1.9.13p3-1+deb12u4); here it is purged (`SUDO_FORCE_REMOVE=yes apt-get purge sudo`).
  The `sudo` group (gid 27) of the base system stays. No `agent` user, no /home/agent.
* `/tmp/opam-xxx-7` (three empty opam log files left by the upstream build, kept in v1) is
  removed: Verified images leave nothing under /tmp.
* Derived files: dpkg status, passwd/group/shadow backups.
* Everything else is identical. Env (PATH with the opam switch bin, OPAM_*/COQ_* vars, TZ),
  `ENTRYPOINT []`, no CMD, WORKDIR /home/coq, user root, SHELL bash --login: identical.
  coqc 8.20.1, OCaml 4.13.1, opam 2.3.0, Python 3.11.2, gcc 12.2.0, git 2.39.5.
