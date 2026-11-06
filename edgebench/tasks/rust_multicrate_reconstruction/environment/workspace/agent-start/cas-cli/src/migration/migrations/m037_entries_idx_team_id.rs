//! Migration: entries_idx_team_id

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 37,
    name: "entries_idx_team_id",
    subsystem: Subsystem::Entries,
    description: "Add index on team_id for team queries",
    up: &["CREATE INDEX IF NOT EXISTS idx_entries_team_id ON entries(team_id)"],
    detect: Some("SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_entries_team_id'"),
};
