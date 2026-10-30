//! Migration: skills_add_visibility

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 82,
    name: "skills_add_visibility",
    subsystem: Subsystem::Skills,
    description: "Add visibility column for team sharing control",
    up: &["ALTER TABLE skills ADD COLUMN visibility TEXT NOT NULL DEFAULT 'private'"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('skills') WHERE name = 'visibility'"),
};
