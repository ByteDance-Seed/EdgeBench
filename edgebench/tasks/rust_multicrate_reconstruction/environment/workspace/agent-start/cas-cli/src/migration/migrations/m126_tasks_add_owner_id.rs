//! Migration: tasks_add_owner_id

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 126,
    name: "tasks_add_owner_id",
    subsystem: Subsystem::Worktrees, // Tasks are in the Worktrees subsystem range
    description: "Add owner_id column for team context",
    up: &["ALTER TABLE tasks ADD COLUMN owner_id TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('tasks') WHERE name = 'owner_id'"),
};
