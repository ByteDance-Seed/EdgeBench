//! Migration: skills_add_summary

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 71,
    name: "skills_add_summary",
    subsystem: Subsystem::Skills,
    description: "Add summary column for skill descriptions",
    up: &["ALTER TABLE skills ADD COLUMN summary TEXT NOT NULL DEFAULT ''"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('skills') WHERE name = 'summary'"),
};
