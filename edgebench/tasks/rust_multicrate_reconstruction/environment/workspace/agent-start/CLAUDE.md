<!-- CAS:BEGIN - This section is managed by CAS. Do not edit manually. -->
# IMPORTANT: USE CAS FOR TASK AND MEMORY MANAGEMENT

**DO NOT USE BUILT-IN TOOLS (TodoWrite, EnterPlanMode) FOR TASK TRACKING.**

Use CAS MCP tools instead:
- `mcp__cas__task` with action: create - Create tasks (NOT TodoWrite)
- `mcp__cas__task` with action: start/close - Manage task status
- `mcp__cas__task` with action: ready - See ready tasks
- `mcp__cas__memory` with action: remember - Store memories and learnings
- `mcp__cas__search` with action: search - Search all context

CAS provides persistent context across sessions. Built-in tools are ephemeral.
<!-- CAS:END -->

# CAS - Coding Agent System

Unified context system for AI agents: persistent memory, tasks, rules, and skills across sessions.

**Design Philosophy**: CAS is built for AI agents as the primary users. Humans are observers who review agent activity, provide feedback, and guide direction - but the tools and workflows are optimized for agent consumption and production.

## Use CAS for Task & Memory Management

**Agents use CAS MCP tools instead of built-in TodoWrite:**

```
mcp__cas__task action=create     - Create/track tasks
mcp__cas__task action=start      - Start working on a task (sets status to in_progress)
mcp__cas__task action=notes      - Add progress notes (progress, blocker, decision, discovery)
mcp__cas__task action=close      - Complete tasks
mcp__cas__memory action=remember - Store learnings and context
mcp__cas__search action=search   - Find relevant context (filter with doc_type: entry/task/rule/skill)
```

**Human CLI:**
```bash
cas init           # Initialize CAS in a project
cas serve          # Start MCP server
cas config list    # View configuration
cas doctor         # Run diagnostics
cas update         # Self-update
```

## Project Structure

```
cas-cli/           # Rust CLI & MCP server (primary)
crates/            # Workspace crates (cas-core, cas-store, cas-search, etc.)
```

### cas-cli Architecture

| Directory | Purpose |
|-----------|---------|
| `src/types/` | Core data: Entry, Task, Rule, Skill |
| `src/store/` | Storage abstraction (SqliteStore primary) |
| `src/search/` | Full-text search (BM25 via Tantivy) |
| `src/cli/` | Command handlers |
| `src/hooks/` | Claude Code integration |

## Key Patterns

**Store Trait** (`cas-cli/src/store/mod.rs`): All storage ops go through trait abstractions. SqliteStore is primary.

**Rule Auto-Promotion**: Use `mcp__cas__rule action=helpful id=<id>` to promote Draft/Stale rules to Proven, auto-syncs to `.claude/rules/`.

**MCP Server**: `cas serve` exposes all functionality as MCP tools for Claude Code integration.

## Skill Frontmatter Fields (Claude Code 2.1.3+)

CAS skills sync to `.claude/skills/` as SKILL.md files with YAML frontmatter.

**Note:** In Claude Code 2.1.3, skills and commands were unified into a single system.

The following fields are supported:

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Skill name (prefixed with `cas-`) |
| `description` | string | 1-2 line description |

### Optional Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `user-invocable` | bool | Hide from slash menu (model can still invoke) | `false` |
| `argument-hint` | string | Hint shown when invoked (must be quoted) | `"[query]"` |
| `context` | string | Execution context mode | `fork` |
| `agent` | string | Specialized agent to use | `Explore`, `code-reviewer` |
| `allowed-tools` | list | Restrict tools the skill can use | `- Read`<br>`- Grep` |
| `disable-model-invocation` | bool | Block model from invoking (command-only) | `true` |
| `hooks` | object | Skill-scoped hooks (Claude Code 2.1.0+) | See below |

**Note:** `user-invocable: false` only hides the skill from the user's slash menu. The model can still invoke the skill unless `disable-model-invocation: true` is also set.

### Hooks Structure (Claude Code 2.1.0+)

```yaml
hooks:
  PreToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: cas hook PreToolUse
          timeout: 3000
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: cas hook PostToolUse
          timeout: 3000
  Stop:
    - hooks:
        - type: command
          command: cas hook Stop
```

### Example SKILL.md

```yaml
---
name: cas-deep-search
description: Comprehensive codebase search using forked context
argument-hint: "[query]"
context: fork
agent: Explore
allowed-tools:
  - Read
  - Grep
  - Glob
---

# Deep Search

Instructions for the skill...
```

### Creating Skills

**Via MCP (for agents):**
```
mcp__cas__skill action=create name="My Skill" invokable=true argument_hint="[args]"
```

**Via CLI (for humans):**
```bash
cas skill create "My Skill" --invokable --argument-hint "[args]"
```

Skills are automatically synced to `.claude/skills/` when enabled.

## Hook Configuration (Claude Code 2.1.0+)

### once: true Support

Claude Code 2.1.0 adds `once: true` for hooks that should only execute once per session (even on resume). CAS hooks intentionally do NOT use this because:

- **SessionStart**: Should inject context on every start/resume
- **PostToolUse/Stop**: Should run on every matching event

To add `once: true` to a specific hook, manually edit `.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "cas hook SessionStart",
        "timeout": 5000,
        "once": true
      }]
    }]
  }
}
```

### Bash Wildcard Permissions

Claude Code 2.1.0 supports wildcard patterns for Bash permissions. Add to `.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(cas :*)",
      "Bash(cas task:*)",
      "Bash(cas search:*)"
    ]
  }
}
```

Patterns:
- `Bash(cas :*)` - Allow all CAS commands
- `Bash(cas task:*)` - Allow task operations only
- `Bash(:* --help)` - Allow help for any command

## Code Search with ast-grep

Use `ast-grep` for syntax-aware structural matching instead of text-only tools like `rg` or `grep`. This is especially useful for finding code patterns, refactoring, and understanding structure.

```bash
# Rust: Find all function definitions
ast-grep --lang rust -p 'fn $NAME($$$) { $$$ }'

# Rust: Find impl blocks for a trait
ast-grep --lang rust -p 'impl $TRAIT for $TYPE { $$$ }'

# Rust: Find unwrap() calls (potential error handling issues)
ast-grep --lang rust -p '$EXPR.unwrap()'

# Elixir: Find function definitions
ast-grep --lang elixir -p 'def $NAME($$$) do $$$ end'

# Elixir: Find pipe chains
ast-grep --lang elixir -p '$EXPR |> $FUNC($$$)'

# TypeScript: Find React component definitions
ast-grep --lang typescript -p 'function $NAME($$$): JSX.Element { $$$ }'

# TypeScript: Find useState hooks
ast-grep --lang typescript -p 'const [$STATE, $SETTER] = useState($$$)'
```

Only fall back to `rg` or `grep` for plain-text searches (comments, strings, config files) or when explicitly requested.

## Build & Test

```bash
# cas-cli (Rust)
cd cas-cli && cargo build --release
cargo test

```

## Adding Features

**New CLI command**: Add to `cas-cli/src/cli/mod.rs` Commands enum, create handler file, add integration test in `tests/cli_test.rs`.

**New MCP tool**: Add handler in `cas-cli/src/mcp/`, register in tool list.

## Schema Migrations

CAS uses a versioned migration system for database schema changes. See `cas-cli/docs/MIGRATIONS.md` for full documentation.

### Quick Reference

**Adding a new column:**
1. Add column to base schema in `src/store/sqlite.rs` or `src/store/skill_store.rs`
2. Add migration in `src/migration/migrations.rs` with detection query
3. Run `cargo test migration`

**Migration ID ranges:**
| Subsystem | Range | Tables |
|-----------|-------|--------|
| Entries | 1-50 | entries, sessions |
| Rules | 51-70 | rules |
| Skills | 71-90 | skills |
| Agents | 91-110 | agents, task_leases |

**Human CLI commands:**
```bash
cas update --check        # Check for pending migrations
cas update --dry-run      # Preview migrations
cas update --schema-only  # Apply migrations
cas doctor                # Shows schema version
```
