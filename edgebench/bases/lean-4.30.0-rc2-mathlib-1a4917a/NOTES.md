# base: lean-4.30.0-rc2-mathlib-1a4917a

Lean `v4.30.0-rc2` + Mathlib commit `1a4917a18b30ea1333c195e597067fe044ac9176` with its
dependencies at the revs that commit pins, and prebuilt oleans from Mathlib's cache.
No v1 base corresponds to it: v1 tasks on the `lean_4` base (elan only) cloned and
downloaded their own Mathlib inside each task image. This base holds that Mathlib once
so task layers only add their own project. First user: `carleson_formalization`.

## Layout
* System layer = `bases/lean-4` (same `ubuntu@sha256:4f838adc...` FROM, same snapshot
  `20260617T120000Z`, same exact apt versions; no sudo, no agent user), except elan:
  elan **v4.2.2** release tarball (sha256 40ec2087...de79), because that is what the
  published v1 task images carry (`/opt/elan/bin/elan` sha256 dee1f289...a557,
  `elan 4.2.2 (35628cce1 2026-05-28)`), not the 4.2.3 of `bases/lean-4`.
* Toolchain: Lean v4.30.0-rc2 release tarball (sha256 5b51625f...be86), unpacked into
  `/opt/elan/toolchains/leanprover--lean4---v4.30.0-rc2`. Identical to the v1 task
  images' toolchain, file for file (13904 files, same sha256; same symlinks).
* Mathlib project: `/opt/mathlib` (`lakefile.toml` requiring mathlib at the pinned rev,
  `lean-toolchain`; both committed here). It is outside `/home/workspace` so the agent's
  workspace looks as in v1. `lake update` clones the packages (git checks every commit
  hash) and Mathlib's post-update hook runs `lake exe cache get`. The cache ltars stay in
  `/root/.cache/mathlib` (lets `lake exe cache get` restore oleans offline).
* Packages: mathlib, plausible, LeanSearchClient, importGraph, proofwidgets, aesop, Qq,
  batteries, Cli. Not included: project-level extras such as `checkdecls` (tasks add them).

## Pins / integrity checks at build time
* generated `lake-manifest.json` sha256 = `26ed4e11...35b0`;
* every package HEAD equals its manifest rev and has no tracked changes;
* `lake build --no-build Mathlib`: "All targets up-to-date (8372 jobs)";
* combined sha256 of all 8365 `.olean` files under `.lake/packages`
  (`find -name '*.olean' | LC_ALL=C sort | xargs sha256sum | sha256sum`) = `a1706815...7a85`.

## How tasks use it
A task project with the same toolchain and the same package revs in its own manifest
gets `.lake/packages/<pkg> -> /opt/mathlib/.lake/packages/<pkg>` symlinks (one per
package, so the task can add packages the base lacks next to them) and `lake build`
only builds the task's modules. Never copy the packages into a task layer.

## Build notes
* Needs network (GitHub, Mathlib cache, snapshot.ubuntu.com). Behind a proxy, set
  `SFORGE_HTTP_PROXY`/`SFORGE_HTTPS_PROXY` (and `SFORGE_NO_PROXY` for hosts the proxy cannot reach).
* This Mathlib's cache tool unpacks in parallel and hits "No file descriptors available"
  under Docker's default soft `nofile` limit of 1024, so the `lake update` step raises
  the soft limit (`ulimit -n 65536`, below the 524288 hard limit).

Size: 15.0 GB uncompressed / 3.82 GB content.
