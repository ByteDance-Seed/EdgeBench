# CAS Rust Multi-Crate Reconstruction

You are working in `agent-start/`, a skeletonized Rust Cargo workspace for CAS
(Coding Agent System). CAS is a 16-crate system for persistent coding-agent
context: typed domain records, code chunking, SQLite-backed storage, search,
core orchestration, protocol serialization, terminal multiplexing, MCP adapters,
and a top-level CLI.

The workspace intentionally keeps the public shape of the real system while
removing implementation bodies. Structs, enums, traits, type aliases, module
boundaries, Cargo files, public tests, build scripts, macro definitions, and the
Ghostty VT stub infrastructure are present. Most non-test functions and methods
have bodies such as `todo!()`. Your task is to replace those placeholders with
working Rust implementations so as many tests as possible pass.

A detailed solver-visible specification is provided in `agent-start/SPEC.md`; it summarizes the expected behavior of each crate and clarifies that public test-helper TODOs are local validation scaffolding, while hidden scoring injects additional tests into a clean workspace.

Work from the bottom of the dependency graph upward. A practical order is:
`cas-types`, `cas-code`, protocol/diff crates, terminal leaf crates,
`cas-store`, `cas-search`, `cas-core`, `cas-mux`/`cas-factory`, integration
crates, then `cas-cli`. Lower-layer behavior unlocks many downstream tests.

You may edit implementation source files under `agent-start/`. Do not modify
scoring scripts, task metadata, Dockerfile, vendored dependencies, Cargo.lock,
public tests, or any files outside the starter workspace. Do not use network
access, clone external repositories, fetch dependencies, or rely on hidden test
contents. The package is designed to build offline with `cargo --frozen`.

Run the local progress scorer from the task root:

```bash
bash score.sh
```

The scorer runs `cargo test --frozen` per crate, injects private evaluator tests
when available, and reports `RAW_PASSED`, `RAW_TOTAL`, `WEIGHTED_PASSED`,
`WEIGHTED_TOTAL`, `SCORE`, and `SCORE_STATUS`. A valid run ends with
`SCORE_STATUS=OK`. The current fixed scoring denominator is `RAW_TOTAL=2611`
and `WEIGHTED_TOTAL=100.0`; source-level public/hidden split counts are
informational and may be larger than the fixed executable-test denominator.
