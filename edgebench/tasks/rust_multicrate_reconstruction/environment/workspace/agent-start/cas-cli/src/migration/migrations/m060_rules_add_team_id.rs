//! Migration: rules_add_team_id

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 60,
    name: "rules_add_team_id",
    subsystem: Subsystem::Rules,
    description: "Add team_id column for team collaboration",
    up: &["ALTER TABLE rules ADD COLUMN team_id TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('rules') WHERE name = 'team_id'"),
};
