//! Migration: skills_add_owner_id

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 83,
    name: "skills_add_owner_id",
    subsystem: Subsystem::Skills,
    description: "Add owner_id column for team context",
    up: &["ALTER TABLE skills ADD COLUMN owner_id TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('skills') WHERE name = 'owner_id'"),
};
