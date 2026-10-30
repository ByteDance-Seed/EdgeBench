//! Migration: Add tool_version column to prompts for tracking Claude Code version
use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 156,
    name: "prompts_add_tool_version",
    subsystem: Subsystem::Code,
    description: "Add tool_version column to track Claude Code version used",
    up: &["ALTER TABLE prompts ADD COLUMN tool_version TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('prompts') WHERE name = 'tool_version'"),
};
