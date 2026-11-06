//! Migration: rules_add_priority

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 53,
    name: "rules_add_priority",
    subsystem: Subsystem::Rules,
    description: "Add priority column (0=critical, 1=high, 2=normal, 3=low)",
    up: &["ALTER TABLE rules ADD COLUMN priority INTEGER NOT NULL DEFAULT 2"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('rules') WHERE name = 'priority'"),
};
