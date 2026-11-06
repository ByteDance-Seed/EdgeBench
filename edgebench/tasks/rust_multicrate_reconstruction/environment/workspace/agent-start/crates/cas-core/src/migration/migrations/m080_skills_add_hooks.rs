//! Migration: skills_add_hooks

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 80,
    name: "skills_add_hooks",
    subsystem: Subsystem::Skills,
    description: "Add hooks column for Claude Code 2.1.0 skill-scoped hooks frontmatter",
    up: &["ALTER TABLE skills ADD COLUMN hooks TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('skills') WHERE name = 'hooks'"),
};
