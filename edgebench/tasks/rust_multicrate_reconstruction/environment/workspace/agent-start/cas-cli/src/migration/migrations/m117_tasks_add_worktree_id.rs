//! Migration: tasks_add_worktree_id

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 117,
    name: "tasks_add_worktree_id",
    subsystem: Subsystem::Worktrees,
    description: "Add worktree_id column to tasks",
    up: &["ALTER TABLE tasks ADD COLUMN worktree_id TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('tasks') WHERE name = 'worktree_id'"),
};
