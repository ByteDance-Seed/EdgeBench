//! Migration: skills_add_agent_type

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 78,
    name: "skills_add_agent_type",
    subsystem: Subsystem::Skills,
    description: "Add agent_type column for Claude Code 'agent' frontmatter",
    up: &["ALTER TABLE skills ADD COLUMN agent_type TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('skills') WHERE name = 'agent_type'"),
};
