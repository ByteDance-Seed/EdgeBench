//! Migration: rules_add_scope

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 57,
    name: "rules_add_scope",
    subsystem: Subsystem::Rules,
    description: "Add scope column for global vs project rules",
    up: &["ALTER TABLE rules ADD COLUMN scope TEXT NOT NULL DEFAULT 'project'"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('rules') WHERE name = 'scope'"),
};
