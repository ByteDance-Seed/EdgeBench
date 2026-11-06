//! Migration: tasks_add_pending_worktree_merge

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 123,
    name: "tasks_add_pending_worktree_merge",
    subsystem: Subsystem::Tasks,
    description: "Add pending_worktree_merge column to tasks for worktree merge jail enforcement",
    up: &["ALTER TABLE tasks ADD COLUMN pending_worktree_merge INTEGER NOT NULL DEFAULT 0"],
    detect: Some(
        "SELECT COUNT(*) FROM pragma_table_info('tasks') WHERE name = 'pending_worktree_merge'",
    ),
};
