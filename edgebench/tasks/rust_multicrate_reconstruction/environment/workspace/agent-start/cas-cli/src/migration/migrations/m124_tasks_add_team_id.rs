//! Migration: tasks_add_team_id

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 124,
    name: "tasks_add_team_id",
    subsystem: Subsystem::Tasks,
    description: "Add team_id column for team collaboration",
    up: &["ALTER TABLE tasks ADD COLUMN team_id TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('tasks') WHERE name = 'team_id'"),
};
