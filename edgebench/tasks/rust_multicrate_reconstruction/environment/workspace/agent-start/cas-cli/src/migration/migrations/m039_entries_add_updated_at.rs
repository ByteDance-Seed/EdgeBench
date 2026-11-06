//! Migration: entries_add_updated_at

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 39,
    name: "entries_add_updated_at",
    subsystem: Subsystem::Entries,
    description: "Add updated_at column to track when entries are modified for incremental indexing",
    up: &[
        // Add updated_at column with default of created date (existing entries)
        "ALTER TABLE entries ADD COLUMN updated_at TEXT",
        // Initialize updated_at to created date for all existing entries
        "UPDATE entries SET updated_at = created WHERE updated_at IS NULL",
    ],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('entries') WHERE name = 'updated_at'"),
};
