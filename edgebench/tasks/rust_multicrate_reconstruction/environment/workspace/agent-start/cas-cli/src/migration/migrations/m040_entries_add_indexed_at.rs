//! Migration: entries_add_indexed_at

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 40,
    name: "entries_add_indexed_at",
    subsystem: Subsystem::Entries,
    description: "Add indexed_at column to track when entries were last indexed",
    up: &["ALTER TABLE entries ADD COLUMN indexed_at TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('entries') WHERE name = 'indexed_at'"),
};
