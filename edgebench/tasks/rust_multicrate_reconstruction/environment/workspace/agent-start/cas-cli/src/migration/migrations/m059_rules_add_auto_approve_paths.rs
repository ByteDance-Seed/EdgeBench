//! Migration: rules_add_auto_approve_paths

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 59,
    name: "rules_add_auto_approve_paths",
    subsystem: Subsystem::Rules,
    description: "Add auto_approve_paths column for path-based auto-approval",
    up: &["ALTER TABLE rules ADD COLUMN auto_approve_paths TEXT"],
    detect: Some(
        "SELECT COUNT(*) FROM pragma_table_info('rules') WHERE name = 'auto_approve_paths'",
    ),
};
