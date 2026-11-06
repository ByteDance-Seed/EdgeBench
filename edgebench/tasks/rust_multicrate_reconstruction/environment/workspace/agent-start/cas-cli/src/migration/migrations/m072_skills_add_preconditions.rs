//! Migration: skills_add_preconditions

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 72,
    name: "skills_add_preconditions",
    subsystem: Subsystem::Skills,
    description: "Add preconditions column for skill requirements",
    up: &["ALTER TABLE skills ADD COLUMN preconditions TEXT NOT NULL DEFAULT '[]'"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('skills') WHERE name = 'preconditions'"),
};
