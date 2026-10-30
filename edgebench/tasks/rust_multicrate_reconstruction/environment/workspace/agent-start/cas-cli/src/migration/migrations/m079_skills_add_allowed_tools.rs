//! Migration: skills_add_allowed_tools

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 79,
    name: "skills_add_allowed_tools",
    subsystem: Subsystem::Skills,
    description: "Add allowed_tools column for Claude Code 'allowed-tools' frontmatter",
    up: &["ALTER TABLE skills ADD COLUMN allowed_tools TEXT NOT NULL DEFAULT '[]'"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('skills') WHERE name = 'allowed_tools'"),
};
