//! Migration: tasks_idx_worktree

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 119,
    name: "tasks_idx_worktree",
    subsystem: Subsystem::Worktrees,
    description: "Add index on worktree_id for tasks",
    up: &["CREATE INDEX IF NOT EXISTS idx_tasks_worktree ON tasks(worktree_id)"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_tasks_worktree'",
    ),
};
