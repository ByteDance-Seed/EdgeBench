//! Migration: tasks_add_collaborators

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 127,
    name: "tasks_add_collaborators",
    subsystem: Subsystem::Worktrees, // Tasks are in the Worktrees subsystem range
    description: "Add collaborators column for team editing permissions",
    up: &["ALTER TABLE tasks ADD COLUMN collaborators TEXT NOT NULL DEFAULT '[]'"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('tasks') WHERE name = 'collaborators'"),
};
