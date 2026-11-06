//! Migration: tasks_add_branch

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 116,
    name: "tasks_add_branch",
    subsystem: Subsystem::Worktrees,
    description: "Add branch column to tasks for worktree scoping",
    up: &["ALTER TABLE tasks ADD COLUMN branch TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('tasks') WHERE name = 'branch'"),
};
