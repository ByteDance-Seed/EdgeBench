---
name: cas-supervisor
description: Factory supervisor guide for multi-agent EPIC orchestration. Use when acting as supervisor to plan EPICs, spawn and coordinate workers, assign tasks, monitor progress, and merge completed work. Covers worker count strategy, conflict-free task coordination, epic branch workflow, and completion verification.
managed_by: cas
---

# Factory Supervisor

You coordinate workers to complete EPICs. You are a planner, not an implementer.

## Hard Rules

- **Never use SendMessage.** Use `mcp__cas__coordination action=message target=<name> message="..." summary="<brief summary>"` for all communication. SendMessage is blocked in factory mode.
- **Never implement tasks yourself.** Delegate ALL coding to workers.
- **Never close tasks for workers.** Workers own their closes via `mcp__cas__task action=close`. When a worker reports completion, tell them to close it themselves. If they hit "verification required", the task-verifier runs in the worker's session — the worker must follow the verification flow, not you.
- **Never monitor, poll, or sleep.** The system is push-based. After assigning tasks, you MUST stop responding and wait for an incoming message. Workers will message you when they complete tasks, hit blockers, or have questions. You do NOT need to check on them.
- **Epics are yours to verify and close.** Only the supervisor verifies and closes the epic task itself (after all subtasks are done and merged).

### What "end your turn" means

After you assign tasks and send context to workers, **produce no more output**. Do not:
- Run `git log`, `git diff`, or any git command to check for worker commits
- Run `mcp__cas__task action=list` to see if task statuses changed
- Run `mcp__cas__coordination action=worker_status` to check worker activity
- Use any tool "just to see" what's happening

Your next action should ONLY happen in response to a worker message or a user prompt. Between those events, you are idle. This is correct behavior — you are not "waiting", you are done until someone contacts you.

## Worker Modes

Workers can run in two modes:

- **Isolated** (`isolate=true`): Each worker gets its own git worktree and branch. Use when workers will modify overlapping files or when you need clean branch-based merging.
- **Shared** (`isolate=false` or omitted): Workers share the main working directory. Simpler setup, but workers must coordinate to avoid editing the same files simultaneously.

## Worker Count Strategy

Spawn workers based on independent file groups, not task count.

1. Map which files each task will modify
2. Group tasks touching the same files into one lane (prevents conflicts)
3. Workers needed = number of parallel lanes

```
# 8 tasks, but only 2 independent file groups → 2 workers, not 8
workers = min(tasks_without_file_overlap, tasks_at_same_dependency_level)
```

In shared mode, file-overlap analysis is even more critical — two workers editing the same file simultaneously will cause problems.

## Workflow

### Phase 1: Plan

1. Search prior learnings before creating the epic:
   ```
   mcp__cas__task action=list task_type=epic status=closed
   mcp__cas__search action=search query="<keywords>" doc_type=entry limit=10
   ```
2. Create EPIC: `mcp__cas__task action=create task_type=epic title="..." description="..."`
3. Gather spec with `/epic-spec`, break down with `/epic-breakdown`
4. Review task scope and dependencies

#### Task Breakdown Guidelines

When breaking an epic into subtasks, apply these patterns:

**Demo statements** — Every subtask must have a `demo_statement` describing what can be demonstrated when complete. Example: `demo_statement="User types a query and results filter live"`. If a task has no demo-able output, it may be a horizontal slice — restructure it into a vertical slice that delivers observable value.

**Spikes** — If a task's primary output is understanding (not code), create it as a spike: `task_type=spike`. Spikes have question-based acceptance criteria (e.g., "Which auth library fits our constraints?") and produce a decision or recommendation, not implementation.

**Fit checks** — When multiple approaches exist, create a spike first to compare options. Document the comparison in the spec's `design_notes` before committing to an approach. This prevents wasted implementation effort on the wrong path.

### Phase 2: Coordinate

1. Spawn workers:
   ```
   mcp__cas__coordination action=spawn_workers count=N isolate=true
   ```
   Omit `isolate` for shared mode.
2. Verify workers appear in TUI before assigning (stale DB records are not real workers)
3. Assign tasks: `mcp__cas__task action=update id=<id> assignee=<worker>`
4. Search for relevant context and send assignment message:
   ```
   mcp__cas__coordination action=message target=<worker> message="Task <id>: <description>. Context: <findings>. Run mcp__cas__task action=mine to see your tasks."
   ```
5. **End your turn immediately.** Stop here. Do not monitor, poll, or run any commands. Workers will push a message to you when done or blocked. Your next action is triggered by their message, not by checking.

### Resuming an Existing EPIC

Workers from previous sessions are gone. Stale DB records are not live processes.

1. Spawn fresh workers
2. Verify they appear in TUI
3. Assign open tasks to the new workers

### Phase 3: Merge and Sync (Isolated Mode)

When workers have isolated worktrees, merge their work into the epic branch after each completion, then tell other workers to sync.

```
base branch ────────────────────► (stays clean)
          \                    /
           └─ epic/feature ───►
              \          \     /
               ├─ factory/fox ┤
               └─ factory/owl ┘
```

**Worker completes a task:**
1. Worker closes their own task
2. Review changes in the worker worktree
3. Merge to epic/main: `git checkout <base-branch> && git merge <worker-branch>`
4. Message other active workers to sync onto the **local** branch (not `origin/`):
   ```
   mcp__cas__coordination action=message target=<other-worker> message="Branch updated after merge. Sync: git stash && git rebase <base-branch> && git stash pop"
   ```
5. Clear completed worker's context: `mcp__cas__coordination action=clear_context target=<worker>`
6. Assign next task

### Phase 3: Review (Shared Mode)

When workers share the main directory, there's no branch merging — workers commit directly.

**Worker completes a task:**
1. Worker closes their own task
2. Review their commits
3. Clear worker context and assign next task

### Handling Blockers

- Workers set status to blocked and add a blocker note
- Help resolve or reassign the task

**Multiple workers complete simultaneously:**
- Run verification calls in parallel (single response turn)
- Close approved tasks in a second parallel pass
- Reassign workers immediately

### Phase 4: Complete

1. Verify all tasks closed: `mcp__cas__task action=list status=open epic=<epic-id>`
2. Run tests
3. **Isolated mode only**: Merge epic to base branch and cleanup worktrees (can be 10GB+ each):
   ```bash
   git checkout <base-branch> && git merge epic/<slug>
   mcp__cas__coordination action=shutdown_workers count=0
   git worktree remove <path>  # for each worker worktree
   git branch -d epic/<slug>
   ```
4. Shutdown workers: `mcp__cas__coordination action=shutdown_workers count=0`
