//! Migration: skills_add_validation_script

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 74,
    name: "skills_add_validation_script",
    subsystem: Subsystem::Skills,
    description: "Add validation_script column for skill validation",
    up: &["ALTER TABLE skills ADD COLUMN validation_script TEXT NOT NULL DEFAULT ''"],
    detect: Some(
        "SELECT COUNT(*) FROM pragma_table_info('skills') WHERE name = 'validation_script'",
    ),
};
