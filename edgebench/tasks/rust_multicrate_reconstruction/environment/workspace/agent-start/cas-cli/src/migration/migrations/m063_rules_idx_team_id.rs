//! Migration: rules_idx_team_id

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 63,
    name: "rules_idx_team_id",
    subsystem: Subsystem::Rules,
    description: "Add index on team_id for team queries",
    up: &["CREATE INDEX IF NOT EXISTS idx_rules_team_id ON rules(team_id)"],
    detect: Some("SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_rules_team_id'"),
};
