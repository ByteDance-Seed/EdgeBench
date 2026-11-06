---
name: cas-codex-supervisor-checklist
description: Quick startup checklist for Codex-based factory supervisors. Use at the beginning of a factory session to load context, check EPICs, and confirm worker availability. Compensates for missing hooks in Codex.
managed_by: cas
---

# Codex Supervisor Checklist

## Session Start (No Hooks)

1. Identify yourself: `mcp__cs__coordination action=whoami`
2. Load EPIC/task context:
   ```
   mcp__cs__task action=list task_type=epic
   mcp__cs__task action=ready
   mcp__cs__task action=list status=blocked
   ```
3. Pull relevant memories and rules:
   ```
   mcp__cs__search action=search query="<keywords>" doc_type=entry limit=5
   ```
4. Check worker availability: `mcp__cs__coordination action=worker_status`

Do not use `/cas-start`, `/cas-context`, or `/cas-end` — they are not available in Codex.

## During Coordination

Record decisions as you go:
```
mcp__cs__memory action=remember title="..." content="..." tags="decision"
```

## Epic Planning Checklist

- Every subtask has a `demo_statement` (if not, it may be a horizontal slice — restructure)
- Investigation tasks use `task_type=spike` with question-based acceptance criteria
- When multiple approaches exist, a spike with a fit check comparison in `design_notes` precedes implementation tasks

## Before Closing an EPIC

- Verify all worker branches are merged into the epic branch
- Confirm task deliverables exist on the epic branch
- Run full test suite on epic branch

## Session End

Store a short summary memory tagged `summary`.
