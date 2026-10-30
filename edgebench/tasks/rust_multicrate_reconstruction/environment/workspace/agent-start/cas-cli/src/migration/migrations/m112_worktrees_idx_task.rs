//! Migration: worktrees_idx_task

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 112,
    name: "worktrees_idx_task",
    subsystem: Subsystem::Worktrees,
    description: "Add index on task_id for worktrees",
    up: &["CREATE INDEX IF NOT EXISTS idx_worktrees_task ON worktrees(task_id)"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_worktrees_task'",
    ),
};
