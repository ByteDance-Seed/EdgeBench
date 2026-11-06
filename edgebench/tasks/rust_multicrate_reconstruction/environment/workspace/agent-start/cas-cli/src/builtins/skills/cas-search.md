---
name: cas-search
description: Search across CAS content (memories, tasks, rules, skills, code). Use when needing to find information, understand codebase, or locate specific patterns. Supports hybrid BM25+semantic search, code symbol search, grep, context, and entity operations.
managed_by: cas
---

# CAS Search

Use `mcp__cas__search` to find information across CAS content and code. Choose the right action for the job:

## Which Action to Use

**`search`** — Conceptual queries across memories, tasks, rules, skills:
```
mcp__cas__search action=search query="authentication flow" doc_type=entry
```
Filter with `doc_type` (entry, task, rule, skill, code_symbol, code_file) for better relevance.

**`code_search`** — Find code symbols by what they do, not exact names:
```
mcp__cas__search action=code_search query="user authentication" kind=function language=rust
```
Use `include_source=true` to get source code inline.

**`grep`** — Exact regex pattern matching in files:
```
mcp__cas__search action=grep pattern="TODO:" glob="*.rs"
```
Prefer the built-in Grep tool for simple patterns where you already know file paths.

## Decision Guide

| Need | Action |
|------|--------|
| "How does X work?" | `search` or `code_search` |
| Find exact string or regex | `grep` |
| Find past learnings | `search` with `doc_type=entry` |
| Find function by concept | `code_search` |
| Find related tasks | `search` with `doc_type=task` |

## Other Actions

- **`context`** — Session context summary: recent activity, active tasks, relevant memories
- **`context_for_subagent`** — Task-focused context for spawning subagents (pass `task_id` and `max_tokens`)
- **`observe`** — Record discoveries/decisions during work (`observation_type`: general, decision, bugfix, feature, refactor, discovery)
- **`entity_list`** / **`entity_show`** — Browse extracted entities (person, project, technology, etc.)
- **`code_show`** — Full details for a specific code symbol by ID
- **`blame`** — Git blame with optional AI-line filtering (`file_path`, `line_start`, `line_end`)
