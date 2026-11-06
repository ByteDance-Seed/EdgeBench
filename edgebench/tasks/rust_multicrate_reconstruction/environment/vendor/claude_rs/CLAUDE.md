# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## MANDATORY: Issue Tracking with bd

**ALL work MUST be tracked using cas.** No exceptions.

### Before ANY work:
```bash
bd ready                    # See what's unblocked and ready to work on
bd show <issue-id>          # Review the issue details before starting
bd update <issue-id> --status in_progress  # Claim the issue
```

### During work:
```bash
bd create "Discovered sub-task" --type task  # If you discover new work
bd dep add <new-issue> <parent-issue>        # Link dependencies
```

### After completing work:
```bash
bd close <issue-id>                          # Mark as done
bd ready                                     # Find next task
```

### TDD Workflow:
Tasks are structured as test-first. Implementation tasks are **blocked** by their test tasks.
1. Pick a test task from `bd ready` (e.g., "Write Parser tests")
2. Write the tests, run them (they should fail)
3. Close the test task: `bd close <test-issue>`
4. The implementation task becomes unblocked in `bd ready`
5. Implement until tests pass
6. Close the implementation task

### Key bd commands:
```bash
bd list                     # All issues
bd list --status open       # Open issues only
bd ready                    # Unblocked work ready to start
bd show <id>                # Issue details
bd dep tree <id>            # Visualize dependencies
bd create "title" -t task   # Create new task
bd update <id> --status in_progress
bd close <id>               # Complete an issue
```

**DO NOT** write code, fix bugs, add features, or make any changes without first having or creating a bd issue for it.

## Project Overview

claude_rs is a pure Rust SDK for the Claude Code CLI. It communicates with Claude via the CLI's JSON streaming output format, providing a native Rust experience with async streaming, tools, and hooks.

Ported from [ex_claude](../ex_claude) (Elixir).

## Repository Structure

```
claude_rs/
├── src/
│   ├── lib.rs              # Main library entry point
│   ├── cli/
│   │   ├── mod.rs          # CLI process management (PTY)
│   │   ├── command.rs      # CLI argument builder
│   │   ├── parser.rs       # JSON stream parser
│   │   └── executable.rs   # Executable detection
│   ├── message/
│   │   ├── mod.rs          # Message enum and parsing
│   │   ├── system.rs       # SystemMessage
│   │   ├── assistant.rs    # AssistantMessage
│   │   ├── user.rs         # UserMessage
│   │   ├── result.rs       # ResultMessage
│   │   └── ...             # Other message types
│   ├── tool/
│   │   ├── mod.rs          # Tool definition
│   │   ├── schema.rs       # JSON Schema helpers
│   │   └── handler.rs      # ToolHandler trait
│   ├── hook/
│   │   ├── mod.rs          # Hook definition
│   │   ├── input.rs        # Hook input types
│   │   ├── output.rs       # Hook output types
│   │   └── handler.rs      # HookHandler trait
│   ├── mcp/
│   │   ├── bridge.rs       # TCP server for tool execution
│   │   ├── config.rs       # MCP config generation
│   │   └── protocol.rs     # MCP protocol types
│   ├── query.rs            # Query struct and control
│   ├── session.rs          # Managed session
│   ├── options.rs          # QueryOptions builder
│   └── error.rs            # Error types
├── src/bin/
│   └── claude_rs_mcp.rs    # MCP stdio server binary
├── tests/
│   ├── cli_test.rs
│   ├── parser_test.rs
│   ├── message_test.rs
│   └── ...
├── examples/
│   ├── simple_query.rs
│   ├── multi_turn.rs
│   ├── with_tools.rs
│   └── with_hooks.rs
├── Cargo.toml
├── CLAUDE.md               # This file
└── PORTING_PLAN.md         # Detailed porting plan
```

## Architecture

```
Rust (claude_rs)
    │
    ├── query() / prompt() → streams messages back to caller
    ├── schemars → JSON Schema (for tool input validation)
    │
    └── Cli (tokio task)
            │
            │ PTY (stdin/stdout)
            ▼
    Claude CLI (--print --output-format stream-json)
            │
            └── Claude API
```

**Key design:** Pure Rust implementation using PTY to communicate with the Claude CLI. Messages are streamed as newline-delimited JSON and parsed into typed message structs.

## Commands

```bash
# Build
cargo build

# Run tests
cargo test                  # Unit tests (mock mode)
cargo test --features live  # Include live API tests

# Run example
cargo run --example simple_query

# Check formatting and lints
cargo fmt --check
cargo clippy
```

## Development Notes

- Messages stream via async Rust streams from CLI output
- CLI is spawned via PTY with `--print --output-format stream-json`
- Tool schemas: derive with `schemars`, validated before handler execution
- Mock mode available for testing without actual CLI
- No external runtime dependencies (no Node.js, no TypeScript)

## Key Dependencies

- `tokio` - async runtime
- `serde` / `serde_json` - JSON serialization
- `portable-pty` - PTY for CLI communication
- `schemars` - JSON Schema generation
- `async-stream` - async stream utilities
- `thiserror` - error handling
