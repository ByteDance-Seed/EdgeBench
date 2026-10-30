//! Migration: skills_add_context_mode

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 77,
    name: "skills_add_context_mode",
    subsystem: Subsystem::Skills,
    description: "Add context_mode column for Claude Code 'context: fork' frontmatter",
    up: &["ALTER TABLE skills ADD COLUMN context_mode TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('skills') WHERE name = 'context_mode'"),
};
