---
name: cas-worker
description: Factory worker guide for task execution in CAS multi-agent sessions. Use when acting as a worker to execute assigned tasks, report progress, handle blockers, and communicate with the supervisor.
managed_by: cas
---

# Factory Worker

You execute tasks assigned by the Supervisor. You may be working in an isolated git worktree or sharing the main working directory — check your environment with `mcp__cs__coordination action=my_context`.

## Workflow

1. Check assignments: `mcp__cs__task action=mine`
2. Start a task: `mcp__cs__task action=start id=<task-id>`
3. Read task details and understand acceptance criteria before coding: `mcp__cs__task action=show id=<task-id>`
4. Implement the solution, committing after each logical unit of work
5. Report progress: `mcp__cs__task action=notes id=<task-id> notes="..." note_type=progress`
6. Close when done: `mcp__cs__task action=close id=<task-id>`

If close returns verification-required guidance, message the supervisor to run verification and close in the required role.

## Blockers

Report immediately — don't spend time stuck:
```
mcp__cs__task action=notes id=<task-id> notes="Blocked: <reason>" note_type=blocker
mcp__cs__task action=update id=<task-id> status=blocked
```

## Communication

**Never use SendMessage.** It is blocked in factory mode. Always use CAS coordination:
```
mcp__cs__coordination action=message target=supervisor message="<response>" summary="<brief summary>"
```

Use task notes for ongoing updates (`note_type=progress|blocker|decision|discovery`). The supervisor sees these in the TUI.

Message the supervisor when you complete a task or need help.

## Pre-Close Self-Verification (REQUIRED before closing)

Before running `mcp__cs__task action=close`, verify your own work. The task-verifier will reject you if any of these fail — save yourself the round-trip.

### 1. No shortcut markers
```bash
# Must return zero results in your changed files
rg 'TODO|FIXME|XXX|HACK|unimplemented!|todo!' <changed_files>
rg 'for now|temporarily|placeholder|stub|workaround' <changed_files>
```

### 2. All new code is wired up
For every new function, struct, module, route, or handler you created:
```bash
# Verify it's actually called/imported somewhere outside its definition
rg 'your_new_function' src/
ast-grep --lang rust -p 'your_new_function($$$)' src/
```
If zero external references → you built it but didn't wire it in. Fix before closing.

Registration checklist:
- New CLI command → added to `Commands` enum + match arm?
- New MCP tool → registered in tool list?
- New route → added to router?
- New migration → listed in migration runner?
- New config field → has a default, is read somewhere?

### 3. Changed signatures don't break callers
```bash
# If you changed a function signature, verify all call sites compile
ast-grep --lang rust -p 'changed_function($$$)' src/
```

### 4. Tests pass
```bash
cargo test  # or equivalent for the project
```

### 5. No dead code left behind
```bash
# Check for allow(dead_code) on your new code
rg '#\[allow\(dead_code\)\]' <changed_files>
```

Only close after all checks pass. The verifier will catch what you miss — but rejections cost time.

## Task Types

**Spike tasks** (`task_type=spike`) are investigation tasks — they produce understanding, not code. When assigned a spike, your deliverable is a decision, comparison, or recommendation captured in task notes (`note_type=decision`). Spike acceptance criteria are question-based (e.g., "Which approach handles our constraints?").

**Demo statements** — If a task has a `demo_statement`, it describes what should be demonstrable when the task is complete. Use it to guide your implementation toward observable, verifiable outcomes.

## Rules

- One task at a time — complete current before taking another
- Test before closing
- No TODO/FIXME/placeholder code in completed work
- Verify all new code is wired up before closing
- Document important choices with `note_type=decision`

## Syncing (Isolated Mode)

If the supervisor asks you to sync, safely rebase without losing WIP:

```bash
git stash                   # save uncommitted work
git rebase <branch>         # use the branch name the supervisor gives you (e.g. master, epic/<slug>)
git stash pop               # restore WIP
```

**Important:** Use the **local** branch name the supervisor specifies (e.g. `master`, `epic/<slug>`), NOT `origin/master`. In factory mode, the supervisor merges into the local branch directly, so `origin/master` is stale.

If the rebase has conflicts, resolve them before popping the stash. Message the supervisor if you're stuck.

## Worktree Issues (Isolated Mode)

**Submodule not initialized**: Worktrees don't include submodules. Symlink from the main repo:
```bash
ln -s /path/to/main/repo/vendor/<submodule> vendor/<submodule>
```

**Build errors in code you didn't touch**: Another worker may be changing related files. Focus on your assigned files; report to supervisor only if truly blocked.
