# CAS Rust Benchmark Specification

This workspace is a skeletonized Rust implementation of CAS (Coding Agent System). Your goal is to replace missing implementation bodies in the CAS source crates so the public APIs behave consistently with the types, existing tests, and the behavior described below. Hidden tests exercise the same public contracts with additional edge cases.

## What to edit

- Implement missing logic in production Rust source files under `crates/*/src/` and `cas-cli/src/`.
- Keep public type names, function signatures, traits, module boundaries, Cargo manifests, vendored dependencies, and scoring scripts unchanged.
- Do not edit files under `vendor-deps/`, `target/`, `.cargo/registry`, `.cargo/git`, or benchmark metadata.

## Test files and helpers

Some public test files and test-only helper modules in this skeleton also contain `todo!()` placeholders. These are part of the public test harness, not hidden answer data. They exist so local tests can be made executable as the production crates become complete. You may implement test helpers when needed for local validation, but the hidden scorer evaluates production behavior by injecting additional tests into a clean scoring workspace. Do not delete, weaken, or bypass tests.

## Scoring and feedback

Run `bash score.sh` from the benchmark root for weighted progress. The scorer runs each package with `cargo test --frozen`, injects hidden test snippets when available, and reports raw/weighted pass counts. Scores are grouped by dependency-aware layers; lower layers unlock many downstream crates.

## Crate behavior overview

### `cas-types` — domain model and validation

Implement the serializable CAS domain records and helpers: entries, rules, tasks, sessions, agents, leases, dependencies, file changes, commit links, prompts, skills, events, scopes, and sorting. Expected behavior includes deterministic ID/string handling, status/type conversions, validation of required fields, timestamp/version helpers, archived/helpful/harmful state transitions, dependency direction/type semantics, and stable ordering/filtering helpers. Constructors should populate sensible defaults while preserving explicit input values.

### `cas-code` — source parsing and code chunking

Implement language detection, code-file/code-symbol data structures, parser dispatch, and chunking utilities. The Python, Go, and Elixir parsers should extract useful top-level symbols such as functions, methods, structs/classes/modules, imports, and line ranges without panicking on partial or invalid source. Chunkers should produce deterministic, non-overlapping chunks with stable IDs and metadata suitable for search and storage.

### `cas-factory-protocol` — factory wire protocol

Implement protocol message types, JSON serialization/deserialization, framing, compression helpers, and transport utilities. Message encoding should be deterministic and round-trip safe. Decoders should reject malformed envelopes with clear errors instead of panicking. Compression should preserve payload bytes and report unsupported or invalid data cleanly.

### `cas-diffs` — text and file diffs

Implement line/inline diff generation, file diff parsing, highlighting, iterators, and display widgets. Diff output should preserve order, line numbers, insert/delete/equal classifications, and Unicode text. Parsers should tolerate common unified-diff forms and report invalid input as errors.

### `cas-pty` — pseudo-terminal process wrapper

Implement PTY configuration, process spawning, resizing, I/O, environment handling, and error mapping. Defaults should be deterministic. Operations should clean up child processes and file descriptors, handle timeouts or closed streams gracefully, and avoid platform-specific panics in the Linux evaluation environment.

### `cas-recording` — session recording format

Implement recording event formats, readers, writers, export helpers, and validation. Writers should append events in order and flush valid JSON/JSONL or the crate-defined format. Readers should round-trip recordings, reject corrupt data with typed errors, and preserve timestamps, stream names, terminal dimensions, and payload text.

### `cas-store` — SQLite-backed persistence

Implement SQLite stores for entries, tasks, agents, rules, specs, prompts, skills, loops, sessions, events, file changes, commit links, code entities, and relationships. Required behavior includes schema initialization/migration, deterministic ID generation helpers, CRUD operations, batch operations, filtering, pagination, status transitions, lease/worktree coordination, Markdown import/export, and correct serialization of structured metadata. Missing records should return the crate's not-found error or `None` according to the existing API contract.

### `cas-search` — BM25/vector/hybrid search

Implement document abstraction, BM25 indexing/scoring, vector store traits and LMDB-backed storage, grep/code search, hybrid ranking, metrics, and parallel helpers. Search should tokenize consistently, rank deterministically, support filters/tags/types, handle empty queries and empty indexes, and combine lexical/vector scores without NaN or unstable ordering.

### `cas-core` — orchestration facade

Implement the high-level CAS core API over stores and search: config get/set, memory/rule/task/spec/skill operations, deduplication, hooks, transcript parsing, entity extraction, migration detection, cloud/sync-facing data transforms, and verification helpers. Public methods should validate inputs, call lower-level stores consistently, return typed errors, and avoid network dependence in offline tests.

### `cas-mux` — terminal multiplexer model

Implement pane state, snapshots, rendering, PTY harness glue, mux commands, styles, and error handling. Behavior should be deterministic for snapshot tests: preserve pane order, dimensions, scrollback/text content, focus state, and style attributes. Native Ghostty bindings are stubbed for this benchmark; use the provided stub infrastructure rather than external libraries.

### `cas-factory` — multi-agent factory runtime

Implement factory configuration, session lifecycle/resume/state, director decisions, recording integration, change summaries, notifications, and core coordination. Runtime code should manage task/agent state through the stores, serialize session state, recover from missing optional data, and keep async flows deterministic enough for tests.

### `cas-mcp` — MCP service adapter

Implement MCP request/response types, daemon/service wiring, tool handlers, and error conversion. Tools should expose CAS memory, task, rule, skill, spec, search, and system operations through stable JSON-compatible responses. Invalid tool arguments should return structured errors rather than panics.

### `cas-tui-test` — terminal UI test utilities

Implement PTY runners, screen buffers/cells/parsers, wait/assert helpers, artifact collection, and snapshot utilities used by TUI and CLI tests. Parsers should handle ANSI escape sequences, cursor movement, clearing, wrapping, and Unicode width consistently enough for deterministic assertions.

### `cas-cli` package `cas` — command-line integration

Implement the top-level CLI, subcommands, config UI, hooks, cloud/auth/device flows, daemon/worktree/factory commands, MCP commands, logging, telemetry no-op/offline behavior, notifications, migration, UI rendering, hybrid-search commands, and built-in workflows. Commands should read/write the CAS directory consistently, print stable human-readable output expected by tests, return nonzero exit codes for invalid usage, and avoid requiring network access unless a command explicitly models an unavailable cloud operation.

### `ghostty_vt` and `ghostty_vt_sys`

These crates are benchmark stubs for native terminal parsing support. Keep them compatible with the provided C stub and Rust callers. Do not replace them with downloaded native dependencies.

## Practical implementation order

1. `cas-types`
2. `cas-code`
3. `cas-factory-protocol` and `cas-diffs`
4. `cas-pty` and `cas-recording`
5. `cas-store`
6. `cas-search`
7. `cas-core`
8. `cas-mux` and `cas-factory`
9. `cas-mcp` and `cas-tui-test`
10. `cas-cli`

Prefer small, idiomatic, deterministic implementations over large rewrites. Passing lower-layer tests usually improves many higher-layer scores.
