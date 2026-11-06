//! Migration: skills_add_argument_hint

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 76,
    name: "skills_add_argument_hint",
    subsystem: Subsystem::Skills,
    description: "Add argument_hint column for skill invocation hints",
    up: &["ALTER TABLE skills ADD COLUMN argument_hint TEXT NOT NULL DEFAULT ''"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('skills') WHERE name = 'argument_hint'"),
};
