---
name: cas-memory-management
description: How to store and retrieve persistent memories using CAS. Use for facts, preferences, learnings, and context that should persist across sessions. Trigger when discovering patterns, fixing bugs, resolving config issues, or learning how unfamiliar code works.
managed_by: cas
---

# CAS Memory Management

Store memories proactively — don't wait to be asked.

## When to Remember

- After discovering project-specific patterns or conventions
- After fixing non-trivial bugs (capture root cause + solution)
- After learning how unfamiliar code works
- When finding important architectural decisions
- After resolving configuration or setup issues

## Actions

- **Store**: `mcp__cs__memory action=remember title="..." content="..." entry_type=learning` (types: learning, preference, context, observation)
- **Find**: `mcp__cs__search action=search query="..." doc_type=entry`
- **Promote**: `mcp__cs__memory action=helpful id=<id>` — increases priority for future retrieval
