//! Migration: skills_add_team_id

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 81,
    name: "skills_add_team_id",
    subsystem: Subsystem::Skills,
    description: "Add team_id column for team collaboration",
    up: &["ALTER TABLE skills ADD COLUMN team_id TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('skills') WHERE name = 'team_id'"),
};
