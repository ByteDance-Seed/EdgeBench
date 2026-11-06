//! Migration: entries_add_compressed

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 8,
    name: "entries_add_compressed",
    subsystem: Subsystem::Entries,
    description: "Add compressed column to track content compression status",
    up: &["ALTER TABLE entries ADD COLUMN compressed INTEGER NOT NULL DEFAULT 0"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('entries') WHERE name = 'compressed'"),
};
