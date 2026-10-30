//! Migration: skills_idx_team_id

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 84,
    name: "skills_idx_team_id",
    subsystem: Subsystem::Skills,
    description: "Add index on team_id for team queries",
    up: &["CREATE INDEX IF NOT EXISTS idx_skills_team_id ON skills(team_id)"],
    detect: Some("SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_skills_team_id'"),
};
