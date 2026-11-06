# Task: Reconstruct CAS Rust implementations

You are in the starter workspace for the CAS Rust benchmark. Replace `todo!()`
implementation bodies in Rust source files with working code. Preserve public
interfaces and tests. Do not edit Cargo.lock, vendored dependencies, task
metadata, scoring scripts, or tests.

Recommended order: `cas-types` -> `cas-code` -> protocol/diff crates -> terminal
leaf crates -> `cas-store` -> `cas-search` -> `cas-core` -> factory/mux -> MCP,
TUI, and CLI integration.

Read `SPEC.md` for crate-by-crate behavior expectations and for the distinction between production TODOs and public test-helper TODOs.

From the task root, run `bash score.sh` for weighted progress.
