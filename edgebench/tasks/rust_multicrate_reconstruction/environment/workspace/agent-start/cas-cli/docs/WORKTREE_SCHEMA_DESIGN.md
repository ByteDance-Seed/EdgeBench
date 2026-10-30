# Worktree Schema Design (Option C: Branch Scope)

## Overview

This document describes the schema changes for automatic git worktree management in CAS.
We use **Option C: Virtual Isolation** - a single database with branch-scoped visibility.

## Design Principles

1. **Single source of truth**: All data in one `.cas/cas.db`
2. **Branch as scope dimension**: Add `branch` column to key tables
3. **Null = global**: Entries/tasks with `branch = NULL` are visible from all branches
4. **Inheritance**: Worktree can see parent branch content + its own
5. **Promotion on merge**: When worktree merges, option to promote learnings to parent scope

---

## New Table: `worktrees`

Tracks active worktrees and their lifecycle.

```sql
CREATE TABLE IF NOT EXISTS worktrees (
    id TEXT PRIMARY KEY,                    -- wt-{short_hash}
    task_id TEXT,                           -- Task that triggered creation (nullable for manual)
    branch TEXT NOT NULL,                   -- Git branch name (e.g., "cas/cas-1234")
    parent_branch TEXT NOT NULL,            -- Branch worktree was created from (e.g., "main")
    path TEXT NOT NULL,                     -- Absolute path to worktree directory
    status TEXT NOT NULL DEFAULT 'active',  -- active, merged, abandoned, removed
    created_at TEXT NOT NULL,
    merged_at TEXT,                         -- When branch was merged back
    removed_at TEXT,                        -- When worktree was removed
    created_by_agent TEXT,                  -- Agent that created this worktree
    merge_commit TEXT,                      -- Commit hash after merge (for audit)
    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_worktrees_task ON worktrees(task_id);
CREATE INDEX IF NOT EXISTS idx_worktrees_branch ON worktrees(branch);
CREATE INDEX IF NOT EXISTS idx_worktrees_status ON worktrees(status);
CREATE INDEX IF NOT EXISTS idx_worktrees_path ON worktrees(path);
```

### Worktree Status Flow

```
active → merged → removed
   ↓
abandoned → removed
```

- **active**: Worktree exists and is usable
- **merged**: Branch was merged back to parent
- **abandoned**: Task closed without merge (work discarded)
- **removed**: Worktree directory deleted, record kept for audit

---

## Schema Changes: Tasks Table

Add branch scoping to tasks.

```sql
-- Migration: tasks_add_branch
ALTER TABLE tasks ADD COLUMN branch TEXT;

-- Migration: tasks_add_worktree_id
ALTER TABLE tasks ADD COLUMN worktree_id TEXT REFERENCES worktrees(id);

-- Index for branch queries
CREATE INDEX IF NOT EXISTS idx_tasks_branch ON tasks(branch);
CREATE INDEX IF NOT EXISTS idx_tasks_worktree ON tasks(worktree_id);
```

### Task Visibility Rules

| Agent's Branch | Task's Branch | Visible? |
|----------------|---------------|----------|
| feature-a      | NULL          | Yes (global task) |
| feature-a      | feature-a     | Yes (same branch) |
| feature-a      | feature-b     | No (different branch) |
| main           | feature-a     | No (child branch) |
| feature-a      | main          | Yes (parent branch) |

Query pattern:
```sql
SELECT * FROM tasks
WHERE branch IS NULL
   OR branch = :current_branch
   OR branch = :parent_branch
ORDER BY priority, created_at DESC
```

---

## Schema Changes: Entries Table

Add branch scoping to memories/learnings.

```sql
-- Migration: entries_add_branch
ALTER TABLE entries ADD COLUMN branch TEXT;

-- Index for branch queries
CREATE INDEX IF NOT EXISTS idx_entries_branch ON entries(branch);
```

### Entry Visibility Rules

Same as tasks - entries with `branch = NULL` are visible everywhere.

**On worktree merge**: Option to promote branch-scoped entries to `branch = NULL`:
- Entries with positive feedback → auto-promote
- Entries with negative feedback → delete
- Neutral entries → keep scoped (won't pollute main)

---

## Schema Changes: Sessions Table

Track which branch/worktree a session is in.

```sql
-- Migration: sessions_add_branch
ALTER TABLE sessions ADD COLUMN branch TEXT;

-- Migration: sessions_add_worktree_id
ALTER TABLE sessions ADD COLUMN worktree_id TEXT REFERENCES worktrees(id);
```

---

## Schema Changes: Agents Table

Track which worktree an agent is operating in.

```sql
-- Migration: agents_add_worktree_id
ALTER TABLE agents ADD COLUMN worktree_id TEXT REFERENCES worktrees(id);

-- Migration: agents_add_branch
ALTER TABLE agents ADD COLUMN branch TEXT;
```

---

## Migration Plan

Following CAS migration conventions (see MIGRATIONS.md):

### Entries Subsystem (IDs 29-35)

```rust
Migration {
    id: 29,
    name: "entries_add_branch",
    subsystem: Subsystem::Entries,
    description: "Add branch column for worktree scoping",
    up: &["ALTER TABLE entries ADD COLUMN branch TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('entries') WHERE name = 'branch'"),
},
Migration {
    id: 30,
    name: "entries_idx_branch",
    subsystem: Subsystem::Entries,
    description: "Add index on branch for worktree queries",
    up: &["CREATE INDEX IF NOT EXISTS idx_entries_branch ON entries(branch)"],
    detect: Some("SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_entries_branch'"),
},
Migration {
    id: 31,
    name: "sessions_add_branch",
    subsystem: Subsystem::Entries,
    description: "Add branch column to sessions for worktree tracking",
    up: &["ALTER TABLE sessions ADD COLUMN branch TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('sessions') WHERE name = 'branch'"),
},
Migration {
    id: 32,
    name: "sessions_add_worktree_id",
    subsystem: Subsystem::Entries,
    description: "Add worktree_id foreign key to sessions",
    up: &["ALTER TABLE sessions ADD COLUMN worktree_id TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('sessions') WHERE name = 'worktree_id'"),
},
```

### Tasks Subsystem (new range: 41-50)

```rust
Migration {
    id: 41,
    name: "tasks_add_branch",
    subsystem: Subsystem::Tasks,
    description: "Add branch column for worktree scoping",
    up: &["ALTER TABLE tasks ADD COLUMN branch TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('tasks') WHERE name = 'branch'"),
},
Migration {
    id: 42,
    name: "tasks_add_worktree_id",
    subsystem: Subsystem::Tasks,
    description: "Add worktree_id foreign key",
    up: &["ALTER TABLE tasks ADD COLUMN worktree_id TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('tasks') WHERE name = 'worktree_id'"),
},
Migration {
    id: 43,
    name: "tasks_idx_branch",
    subsystem: Subsystem::Tasks,
    description: "Add index on branch for worktree queries",
    up: &["CREATE INDEX IF NOT EXISTS idx_tasks_branch ON tasks(branch)"],
    detect: Some("SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_tasks_branch'"),
},
Migration {
    id: 44,
    name: "tasks_idx_worktree",
    subsystem: Subsystem::Tasks,
    description: "Add index on worktree_id",
    up: &["CREATE INDEX IF NOT EXISTS idx_tasks_worktree ON tasks(worktree_id)"],
    detect: Some("SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_tasks_worktree'"),
},
```

### Agents Subsystem (IDs 92-95)

```rust
Migration {
    id: 92,
    name: "agents_add_worktree_id",
    subsystem: Subsystem::Agents,
    description: "Add worktree_id to track agent's current worktree",
    up: &["ALTER TABLE agents ADD COLUMN worktree_id TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('agents') WHERE name = 'worktree_id'"),
},
Migration {
    id: 93,
    name: "agents_add_branch",
    subsystem: Subsystem::Agents,
    description: "Add branch to track agent's current git branch",
    up: &["ALTER TABLE agents ADD COLUMN branch TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('agents') WHERE name = 'branch'"),
},
```

### Worktrees Subsystem (new: IDs 111-120)

```rust
Migration {
    id: 111,
    name: "worktrees_create_table",
    subsystem: Subsystem::Worktrees,
    description: "Create worktrees table for tracking git worktrees",
    up: &[
        "CREATE TABLE IF NOT EXISTS worktrees (
            id TEXT PRIMARY KEY,
            task_id TEXT,
            branch TEXT NOT NULL,
            parent_branch TEXT NOT NULL,
            path TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'active',
            created_at TEXT NOT NULL,
            merged_at TEXT,
            removed_at TEXT,
            created_by_agent TEXT,
            merge_commit TEXT
        )"
    ],
    detect: Some("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='worktrees'"),
},
Migration {
    id: 112,
    name: "worktrees_idx_task",
    subsystem: Subsystem::Worktrees,
    description: "Add index on task_id",
    up: &["CREATE INDEX IF NOT EXISTS idx_worktrees_task ON worktrees(task_id)"],
    detect: Some("SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_worktrees_task'"),
},
Migration {
    id: 113,
    name: "worktrees_idx_branch",
    subsystem: Subsystem::Worktrees,
    description: "Add index on branch",
    up: &["CREATE INDEX IF NOT EXISTS idx_worktrees_branch ON worktrees(branch)"],
    detect: Some("SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_worktrees_branch'"),
},
Migration {
    id: 114,
    name: "worktrees_idx_status",
    subsystem: Subsystem::Worktrees,
    description: "Add index on status",
    up: &["CREATE INDEX IF NOT EXISTS idx_worktrees_idx_status ON worktrees(status)"],
    detect: Some("SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_worktrees_idx_status'"),
},
Migration {
    id: 115,
    name: "worktrees_idx_path",
    subsystem: Subsystem::Worktrees,
    description: "Add index on path for lookup",
    up: &["CREATE INDEX IF NOT EXISTS idx_worktrees_path ON worktrees(path)"],
    detect: Some("SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_worktrees_path'"),
},
```

---

## Rust Types

### Worktree Type

```rust
// cas-cli/src/types/worktree.rs

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
#[serde(rename_all = "lowercase")]
pub enum WorktreeStatus {
    #[default]
    Active,
    Merged,
    Abandoned,
    Removed,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Worktree {
    pub id: String,
    pub task_id: Option<String>,
    pub branch: String,
    pub parent_branch: String,
    pub path: PathBuf,
    pub status: WorktreeStatus,
    pub created_at: DateTime<Utc>,
    pub merged_at: Option<DateTime<Utc>>,
    pub removed_at: Option<DateTime<Utc>>,
    pub created_by_agent: Option<String>,
    pub merge_commit: Option<String>,
}
```

### Updated Task Type

```rust
// Add to cas-cli/src/types/task.rs

pub struct Task {
    // ... existing fields ...

    /// Git branch this task is scoped to (None = visible from all branches)
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub branch: Option<String>,

    /// Worktree this task was created in (for auto-cleanup)
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub worktree_id: Option<String>,
}
```

### Updated Entry Type

```rust
// Add to cas-cli/src/types/entry.rs

pub struct Entry {
    // ... existing fields ...

    /// Git branch this entry is scoped to (None = visible from all branches)
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub branch: Option<String>,
}
```

---

## Query Patterns

### List Tasks for Current Branch

```sql
-- Get tasks visible from current worktree
-- Includes: global tasks (branch IS NULL), current branch, parent branch
SELECT * FROM tasks
WHERE status != 'closed'
  AND (branch IS NULL OR branch = ?1 OR branch = ?2)
ORDER BY priority, created_at DESC

-- Parameters: current_branch, parent_branch
```

### Create Task in Worktree

```sql
INSERT INTO tasks (id, title, branch, worktree_id, ...)
VALUES (?1, ?2, ?3, ?4, ...)

-- If in worktree: branch = current_branch, worktree_id = current_worktree
-- If not in worktree: branch = NULL, worktree_id = NULL
```

### Promote Entries on Merge

```sql
-- Promote entries with positive feedback to global scope
UPDATE entries
SET branch = NULL
WHERE branch = ?1
  AND (helpful_count - harmful_count) > 0;

-- Delete entries with negative feedback
DELETE FROM entries
WHERE branch = ?1
  AND (helpful_count - harmful_count) < 0;
```

### List Active Worktrees

```sql
SELECT w.*, t.title as task_title
FROM worktrees w
LEFT JOIN tasks t ON w.task_id = t.id
WHERE w.status = 'active'
ORDER BY w.created_at DESC
```

---

## Configuration

Add to `.cas/config.yaml`:

```yaml
worktrees:
  # Enable automatic worktree creation on task start
  enabled: true

  # Base directory for worktrees (relative to repo root's parent)
  base_path: "../{project}-worktrees"

  # Branch prefix for worktree branches
  branch_prefix: "cas/"

  # Auto-merge on task close (if no conflicts)
  auto_merge: false

  # Auto-cleanup worktree directory on task close
  cleanup_on_close: true

  # Promote entries with positive feedback on merge
  promote_entries_on_merge: true
```

---

## MCP Tool Changes

### `cas_task` with worktree support

Request additions:
```json
{
  "action": "start",
  "id": "cas-1234",
  "worktree": true,       // Create worktree for this task
  "worktree_path": null   // Optional: custom path (default: auto)
}
```

Response additions:
```json
{
  "task": { ... },
  "worktree": {
    "id": "wt-a1b2c3",
    "path": "/path/to/worktree",
    "branch": "cas/cas-1234"
  }
}
```

### New `cas_worktree` tool

```json
{
  "action": "list" | "show" | "merge" | "abandon" | "cleanup"
}
```

---

## Implementation Order

1. **Schema migrations** - Add columns and tables
2. **Rust types** - Add `Worktree` struct, update `Task`, `Entry`
3. **WorktreeStore trait** - CRUD for worktrees table
4. **GitWorktreeManager** - Git operations wrapper (separate from CAS)
5. **Integration in task_start** - Wire worktree creation into task lifecycle
6. **Integration in task_close** - Wire merge/cleanup into task close
7. **MCP tool updates** - Add worktree parameters to `cas_task`
8. **Tests** - Unit + integration tests

---

## Edge Cases

### What if git is not available?
- Fall back to non-worktree mode
- Log warning, continue with shared context

### What if worktree creation fails?
- Task start succeeds, worktree creation logged as warning
- Agent continues in current directory

### What about merge conflicts?
- Don't auto-merge if conflicts detected
- Set worktree status to 'conflict'
- Agent/user must resolve manually

### Orphaned worktrees (agent crash)?
- Daemon detects stale worktrees (no active lease + old heartbeat)
- `cas worktree cleanup` command for manual cleanup
- Auto-cleanup optional in config

### Nested worktrees?
- Not supported - error if trying to create worktree inside worktree
- Detect by checking if cwd is already in a worktree path
