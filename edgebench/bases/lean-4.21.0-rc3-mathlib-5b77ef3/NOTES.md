# base: lean-4.21.0-rc3-mathlib-5b77ef3

Lean v4.21.0-rc3 + Mathlib `5b77ef3c3fcca1da8ca4f54da448f092cc629f8d` (+ doc-gen4
`86d735ecf420e0dbaaf84e2fc2221969f9fca097` and its dependencies), made for
`tasks/new_foundations_consistency` (the con-nf project). v1 had no matching base: that task
ran on `edgebench.base.lean_4` (elan only) and each of its work and judge images fetched its
own ~5.3 GB `.lake/packages` with `lake exe cache get`. Here the packages exist once, in
`/home/workspace/baseline/.lake/packages`, and the task links its `.lake/packages` there.

## Contents
* `ubuntu@sha256:4f838adc...` (ubuntu:jammy-20260509), apt from snapshot `20260617T120000Z`,
  the same package set and versions as `bases/lean-4` (= v1 `lean_4` minus `sudo`). No `agent` user.
* elan v4.2.2 release tarball (sha256 pinned). Its binary is byte-identical to
  `/opt/elan/bin/elan` in v1's con-nf images (dee1f289...). Those images sit on an earlier build
  of the v1 `lean_4` base (elan 4.2.2); the published `edgebench.base.lean_4` and `bases/lean-4`
  have elan 4.2.3 (840179e7...).
* Lean v4.21.0-rc3 release tarball (sha256 pinned). Unpacked, it matches v1's
  `/opt/elan/toolchains/leanprover--lean4---v4.21.0-rc3` file for file (5698 files).
* `/home/workspace/baseline`: `lean-toolchain`, `lakefile.toml` (con-nf's two `[[require]]`s) and
  `lake-manifest.json` = con-nf's manifest from the original task repo with only the root `name`
  changed to `baseline` (sha256 pinned). `lake exe cache get` clones every package at its
  manifest rev and downloads the Mathlib oleans. Checks in the Dockerfile: the manifest is
  unchanged afterwards, every package HEAD equals its manifest rev, `lake build --no-build Mathlib`
  succeeds, and the combined sha256 of all 6860 `.olean` files under `.lake/packages`
  (`find -name '*.olean' | sort | xargs sha256sum | sha256sum`) is
  `3e35c756...b984`, the same value computed in both published v1 con-nf images.
* `/root/.cache/mathlib`: the 6852 cache ltars, identical (path + sha256) to v1's judge image.

## Diff vs v1 con-nf images (packages)
Package trees without `.git` (55934 files): identical except 11 Lake `.trace` files of Mathlib's
`cache` executable and `proofwidgets/.lake/ProofWidgets4.tar.gz.trace` (they also differ between
v1's own work and judge images). Package `.git` directories are real upstream clones here; v1's
had been re-initialised by an undocumented post-processing step (synthetic revs; doc-gen4 even
lost its `origin` and its manifest rev, which made v1's judge re-clone it from GitHub at judge
time; see the task's NOTES.md).

## Build
Needs network (GitHub, Mathlib cache server, snapshot.ubuntu.com). Behind a proxy, set
`SFORGE_HTTP_PROXY`/`SFORGE_HTTPS_PROXY` (and `SFORGE_NO_PROXY` for hosts the proxy cannot reach).
Size: 11.9 GB uncompressed / 3.16 GB compressed (packages layer 6.5 GB incl. 556 MB of `.git`
and the 287 MB cache; toolchain 1.8 GB).
