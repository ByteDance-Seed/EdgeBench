use std::path::Path;

pub(crate) const CAS_SECTION_BEGIN: &str =
    "<!-- CAS:BEGIN - This section is managed by CAS. Do not edit manually. -->";
pub(crate) const CAS_SECTION_END: &str = "<!-- CAS:END -->";

/// CAS directive content (MCP tools)
const CAS_DIRECTIVE_CONTENT: &str = r#"# IMPORTANT: USE CAS FOR TASK AND MEMORY MANAGEMENT

**DO NOT USE BUILT-IN TOOLS (TodoWrite, EnterPlanMode) FOR TASK TRACKING.**

Use CAS MCP tools instead:
- `mcp__cas__task` with action: create - Create tasks (NOT TodoWrite)
- `mcp__cas__task` with action: start/close - Manage task status
- `mcp__cas__task` with action: ready - See ready tasks
- `mcp__cas__memory` with action: remember - Store memories and learnings
- `mcp__cas__search` with action: search - Search all context

CAS provides persistent context across sessions. Built-in tools are ephemeral."#;

/// Build the full CAS section with markers
pub(crate) fn build_cas_section() -> String { todo!() }

/// Update or create CLAUDE.md with CAS directive section
/// Returns Ok(true) if file was modified, Ok(false) if no changes needed
pub fn update_claude_md(project_root: &Path) -> anyhow::Result<bool> { todo!() }

// ============================================================================
// CAS skill generation
// ============================================================================

pub(crate) const CAS_SKILL: &str = r#"---
name: cas
description: Coding Agent System - unified memory, tasks, rules, and skills. Use when you need to remember something, track work, search past context, or manage tasks. (project)
managed_by: cas
---

# CAS - Coding Agent System

**IMPORTANT: Use CAS MCP tools instead of built-in tools for task and memory management.**

CAS provides persistent memory and task management across sessions. Built-in tools like TodoWrite are ephemeral and don't persist.

## WHEN TO USE CAS (ALWAYS)

- **Task tracking**: Use `mcp__cas__task` with action: create instead of TodoWrite
- **Planning tasks**: Use `mcp__cas__task` with action: create and blocked_by for dependencies
- **Storing learnings**: Use `mcp__cas__memory` with action: remember to store context
- **Searching context**: Use `mcp__cas__search` with action: search to find past work

## Task Tools (USE INSTEAD OF TodoWrite)

### Creating Tasks

Use `mcp__cas__task` with action: create and parameters:
- `title` (required) - Task title
- `priority` - 0=critical, 1=high, 2=medium (default), 3=low, 4=backlog
- `start` - Set to true to start immediately (RECOMMENDED)
- `notes` - Initial working notes

### Managing Tasks

All task operations use `mcp__cas__task` with different actions:
- action: ready - Show tasks ready to work on
- action: blocked - Show blocked tasks
- action: list - List all tasks
- action: show - Show task details (requires id)
- action: update - Update notes as you work (requires id)
- action: close - Close with resolution (requires id)

### Task Dependencies

- action: dep_add - Add blocking dependency (requires id, to_id)
- action: dep_list - List dependencies (requires id)

## Memory Tools

All memory operations use `mcp__cas__memory` with different actions:
- action: remember - Store a memory entry (requires content)
- action: get - Get entry details (requires id)
- action: helpful - Mark as helpful (requires id)
- action: harmful - Mark as harmful (requires id)

## Search Tools

Use `mcp__cas__search` with different actions:
- action: search - Search memories (requires query)
- action: context - Get full session context

## Iteration Loops

Use loops for long-running repetitive tasks. The loop blocks session exit and re-injects your prompt until completion.

Use `mcp__cas__coordination` with different actions:
- action: loop_start - Start a loop (requires prompt, session_id, optional completion_promise and max_iterations)
- action: loop_status - Check current loop status (requires session_id)
- action: loop_cancel - Cancel active loop (requires session_id)

To complete a loop, output `<promise>DONE</promise>` (or your custom promise text).

## Rules & Skills

Use `mcp__cas__rule` and `mcp__cas__skill` with different actions:
- rule action: list - Show active rules
- rule action: helpful - Promote rule to proven (requires id)
- skill action: list - Show enabled skills
"#;

/// Check if a file is managed by CAS (has `managed_by: cas` in frontmatter)
pub(crate) fn is_skill_managed_by_cas(content: &str) -> bool { todo!() }

/// Check if a file is the old CAS skill (for migration)
pub(crate) fn is_old_cas_skill(content: &str) -> bool { todo!() }

/// Generate CAS skill file
pub fn generate_cas_skill(project_root: &Path) -> anyhow::Result<bool> { todo!() }

// ============================================================================
// Agent and command generation (using builtins)
// ============================================================================
