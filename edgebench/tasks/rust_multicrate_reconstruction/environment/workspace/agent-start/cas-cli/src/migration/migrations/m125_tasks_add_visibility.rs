//! Migration: tasks_add_visibility

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 125,
    name: "tasks_add_visibility",
    subsystem: Subsystem::Worktrees, // Tasks are in the Worktrees subsystem range
    description: "Add visibility column for team sharing control",
    up: &["ALTER TABLE tasks ADD COLUMN visibility TEXT NOT NULL DEFAULT 'private'"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('tasks') WHERE name = 'visibility'"),
};
