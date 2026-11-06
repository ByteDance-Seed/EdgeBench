//! Migration: tasks_idx_team_id

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 128,
    name: "tasks_idx_team_id",
    subsystem: Subsystem::Worktrees, // Tasks are in the Worktrees subsystem range
    description: "Add index on team_id for team queries",
    up: &["CREATE INDEX IF NOT EXISTS idx_tasks_team_id ON tasks(team_id)"],
    detect: Some("SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_tasks_team_id'"),
};
