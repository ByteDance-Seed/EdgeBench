# CAS Rust Benchmark Starter

This is the solver-visible starter workspace for the CAS Rust multi-crate
reconstruction benchmark.

## Task

Replace the `todo!()` implementation bodies in Rust source files with working
code while preserving public interfaces, Cargo manifests, vendored dependencies,
and tests. Start from lower-level crates and work upward through the dependency
graph.

Recommended order:

`cas-types` -> `cas-code` -> protocol/diff crates -> terminal leaf crates ->
`cas-store` -> `cas-search` -> `cas-core` -> factory/mux -> MCP/TUI/CLI.

## Boundaries

- Edit implementation Rust source files only.
- Do not edit tests, scoring scripts, Cargo manifests/lockfiles, vendored
  dependencies, or benchmark metadata.
- Do not use network access or clone external repositories.
- Hidden evaluator tests are not present in this starter; the evaluator injects
  them in an isolated scoring workspace.

## Local progress

From the benchmark root, run:

```bash
bash score.sh
```

Within this workspace, Cargo commands are also useful:

```bash
cargo build --workspace --frozen
cargo test --frozen -p cas-types
```

See `TASK.md` for the compact task prompt and `SPEC.md` for crate-by-crate behavior expectations and test-helper boundaries.
