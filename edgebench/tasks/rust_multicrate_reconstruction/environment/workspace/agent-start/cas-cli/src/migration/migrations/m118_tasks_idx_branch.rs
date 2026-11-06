//! Migration: tasks_idx_branch

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 118,
    name: "tasks_idx_branch",
    subsystem: Subsystem::Worktrees,
    description: "Add index on branch for tasks",
    up: &["CREATE INDEX IF NOT EXISTS idx_tasks_branch ON tasks(branch)"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_tasks_branch'",
    ),
};
