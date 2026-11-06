//! Migration: skills_add_postconditions

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 73,
    name: "skills_add_postconditions",
    subsystem: Subsystem::Skills,
    description: "Add postconditions column for skill outcomes",
    up: &["ALTER TABLE skills ADD COLUMN postconditions TEXT NOT NULL DEFAULT '[]'"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('skills') WHERE name = 'postconditions'"),
};
