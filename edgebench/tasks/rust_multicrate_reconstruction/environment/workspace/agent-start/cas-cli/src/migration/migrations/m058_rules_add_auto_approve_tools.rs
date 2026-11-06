//! Migration: rules_add_auto_approve_tools

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 58,
    name: "rules_add_auto_approve_tools",
    subsystem: Subsystem::Rules,
    description: "Add auto_approve_tools column for PreToolUse auto-approval",
    up: &["ALTER TABLE rules ADD COLUMN auto_approve_tools TEXT"],
    detect: Some(
        "SELECT COUNT(*) FROM pragma_table_info('rules') WHERE name = 'auto_approve_tools'",
    ),
};
