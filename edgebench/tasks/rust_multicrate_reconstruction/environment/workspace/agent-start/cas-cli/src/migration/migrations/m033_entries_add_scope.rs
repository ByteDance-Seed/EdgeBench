//! Migration: entries_add_scope

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 33,
    name: "entries_add_scope",
    subsystem: Subsystem::Entries,
    description: "Add scope column for global vs project entries",
    up: &["ALTER TABLE entries ADD COLUMN scope TEXT NOT NULL DEFAULT 'project'"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('entries') WHERE name = 'scope'"),
};
