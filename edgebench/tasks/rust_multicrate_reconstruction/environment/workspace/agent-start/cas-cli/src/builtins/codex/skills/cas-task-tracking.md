---
name: cas-task-tracking
description: How to track work using CAS tasks instead of built-in TodoWrite. Use for persistent task tracking with priorities, dependencies, structured notes, and cross-session continuity.
managed_by: cas
---

# CAS Task Tracking

Use `mcp__cs__task` instead of built-in TodoWrite. CAS tasks persist across sessions.

## Core Workflow

1. **Create**: `mcp__cs__task action=create title="..." description="..." priority=2`
2. **Start**: `mcp__cs__task action=start id=<task-id>`
3. **Progress**: `mcp__cs__task action=notes id=<task-id> notes="..." note_type=progress`
4. **Close**: `mcp__cs__task action=close id=<task-id> reason="..."`

## Useful Actions

- **Ready tasks**: `mcp__cs__task action=ready` — unblocked, actionable work
- **My tasks**: `mcp__cs__task action=mine` — tasks assigned to you
- **Blocked**: `mcp__cs__task action=list status=blocked`
- **Add dependency**: `mcp__cs__task action=dep_add id=<task> to_id=<blocker> dep_type=blocks`

## Note Types

`progress`, `blocker`, `decision`, `discovery` — use the right type so notes are meaningful in context.
