# base: lean-4

Reproduces v1 `edgebench.base.lean_4` (BENCHMARK.yaml `lean_4`: `ubuntu:22.04` + git curl
jq build-essential gcc g++ python3 make procps ca-certificates; elan in /opt/elan with
`--default-toolchain none`; WORKDIR /home/workspace; ENTRYPOINT []) minus `sudo` and the
`agent` user. No Lean toolchain and no Mathlib are installed (as in v1); tasks that need
Mathlib use or create their own base.

## FROM provenance
`ubuntu@sha256:4f838adc7181d9039ac795a7d0aba05a9bd9ecd480d294483169c5def983b64d`
(ubuntu:jammy-20260509), whose rootfs diff_id sha256:8bba68e7...938d is the first layer of
the published v1 image (same FROM as bases/cpp and bases/lean-4.28.0-mathlib-8f9d9cf).

## Packages
Ubuntu archive snapshot `20260617T120000Z` (v1 base built 2026-06-17 12:14 UTC); same exact
versions as bases/lean-4.28.0-mathlib-8f9d9cf (the two v1 bases have identical dpkg lists).
As in the other Ubuntu-22.04 bases, /etc/apt/sources.list keeps pointing at the snapshot.

## elan
v1 ran the then-current `elan-init.sh`, which installed elan 4.2.3 (b6cec7e10, 2026-06-08).
Here the v4.2.3 release tarball is fetched and checked by sha256 (df0b2b3a...a8b2); its
`elan-init` binary is byte-identical to v1's /opt/elan/bin/elan (840179e7...6385), and the
resulting /opt/elan tree (bin/ with 7 hard links, env) equals v1 file for file.
No settings.toml, no toolchains (`elan toolchain list`: none).

## Diff vs published v1 (verified: dpkg list, full file tree with sha256/mode/owner, env,
## ENTRYPOINT/CMD, WORKDIR, USER)
* Missing on purpose: `sudo`; the `agent` user/group. `/opt/elan` is owned by root
  (v1: agent, uid 1000).
* `/etc/apt/sources.list` points at the dated snapshot (v1: stock archive.ubuntu.com lists).
* `/var/lib/systemd/deb-systemd-helper-masked` absent (created by sudo's postinst in v1).
* Derived files: dpkg status, apt extended_states.
* Everything else is identical. Env (PATH with /opt/elan/bin, ELAN_HOME, TZ), USER root,
  WORKDIR /home/workspace, ENTRYPOINT [] with no CMD. Nothing under /tmp.
