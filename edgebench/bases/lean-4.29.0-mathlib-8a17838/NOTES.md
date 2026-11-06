# base: lean-4.29.0-mathlib-8a17838

Mathlib v4.29.0 (`8a178386ffc0f5fef0b77738bb5449d50efeea95`) on Lean v4.29.0, built with the
same recipe as `bases/lean-4.28.0-mathlib-8f9d9cf` (see `tasks/lean_analysis_proofs/NOTES.md`):
ubuntu:22.04 by digest, apt from the dated snapshot (same package versions as v1 `lean_4` and
`lean_4_28_0_main`), elan, the Lean toolchain, and `/home/workspace/baseline` made by
`lake +leanprover/lean4:v4.29.0 new baseline math` (oleans from `lake exe cache get`).
Root, no `sudo`, no `agent` user. Created for `pfr_formalization`, whose v1 base was the
elan-only `lean_4` and which ran `lake exe cache get` inside its own project; any task on
Mathlib v4.29.0 can share it (link its project's `.lake/packages/<pkg>` into
`/home/workspace/baseline/.lake/packages`).

## Pins
* elan v4.2.2 release tarball (sha256 40ec2087...). Its binary equals v1 pfr's
  `/opt/elan/bin/elan` (dee1f289...); `elan --version` = `elan 4.2.2 (35628cce1 2026-05-28)`.
  (bases/lean-4 uses elan 4.2.3, which is what v1's `lean_4` base layer has; the v1 pfr images
  carry 4.2.2 in /opt, so this base follows the task image.)
* Lean v4.29.0 release tarball (sha256 089f7e51...). Unpacked it equals v1 pfr's
  `/opt/elan/toolchains/leanprover--lean4---v4.29.0` file for file (13340 files, combined
  sha256 f44bd557...).
* `lake-manifest.json` sha256 88e2a097... (mathlib + plausible, LeanSearchClient, importGraph,
  proofwidgets, aesop, Qq, batteries, Cli); every package HEAD equals its manifest rev, and
  these nine revs equal those in pfr's manifest. `lake build --no-build Mathlib` passes.
* Oleans: combined sha256 57a12188... over the 8239 `*.olean` files under `.lake/packages`,
  excluding the two Lake config caches `.lake/config/*/lakefile.olean` (mathlib, proofwidgets),
  which Lake writes per workspace path and which therefore differ from v1. The same command
  over the same nine packages in v1's pfr workspace gives the same value.
* `/root/.cache/mathlib`: 8234 cache files (408 MB), same file names as v1 pfr's.

## Build
Needs network (GitHub, Mathlib cache); behind a proxy, set `SFORGE_HTTP_PROXY`/`SFORGE_HTTPS_PROXY`
(and `SFORGE_NO_PROXY` for hosts the proxy cannot reach). `lake new` is retried up to 3 times because GitHub
clones through the build proxy failed intermittently (twice on LeanSearchClient).
