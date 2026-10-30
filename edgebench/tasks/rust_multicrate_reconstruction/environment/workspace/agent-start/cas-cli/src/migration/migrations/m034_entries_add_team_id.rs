//! Migration: entries_add_team_id

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 34,
    name: "entries_add_team_id",
    subsystem: Subsystem::Entries,
    description: "Add team_id column for team collaboration",
    up: &["ALTER TABLE entries ADD COLUMN team_id TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('entries') WHERE name = 'team_id'"),
};
