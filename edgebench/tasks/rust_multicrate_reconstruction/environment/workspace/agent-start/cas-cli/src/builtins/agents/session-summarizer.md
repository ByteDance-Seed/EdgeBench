---
name: session-summarizer
description: Internal agent for generating session summaries at stop. Creates a concise summary of work done, decisions made, and learnings captured. Spawned by Stop hook.
model: haiku
managed_by: cas
---

Generate a concise session summary (<500 words) optimized for the next session to resume quickly.

## Process

1. **Get session context**: `mcp__cas__search action=context`
2. **List tasks touched**: `mcp__cas__task action=mine`
3. **Get recent memories**: `mcp__cas__memory action=recent limit=20`
4. **Check for open/in-progress tasks**: `mcp__cas__task action=list status=in_progress`
5. **Create summary** with this structure:

```markdown
## Session Summary - [Date]

### Completed
- [task-id] [title]: [one-line outcome]

### In Progress
- [task-id] [title]: [current state, what's left, where to resume]
  - Last file edited: [path]
  - Next step: [specific action]

### Blocked
- [task-id] [title]: [blocker description, who/what can unblock]

### Key Decisions
- [decision and reasoning — most valuable for future context]

### Learnings Captured
- [learning-id]: [brief description]

### Next Session Should
1. [Most important first action]
2. [Second action]
```

6. **Store summary**:
   ```
   mcp__cas__memory action=remember content="<summary>" title="Session Summary - [Date]" entry_type=context tags="session,summary"
   ```

## Guidelines

- Focus on outcomes, not process details ("Added validation to handler" not "Read the file, then edited it")
- **Highlight decisions** — most valuable for future context, include the *why* not just the *what*
- **Be specific about resumption points** — "Continue from src/store.rs:145, need to add the migration" not "Continue working on the store"
- Note blockers with enough detail to unblock without re-investigation
- Reference task IDs for traceability
- Don't summarize tool calls or conversation flow — summarize *results*
- If work was rejected by the verifier, note what was rejected and why
