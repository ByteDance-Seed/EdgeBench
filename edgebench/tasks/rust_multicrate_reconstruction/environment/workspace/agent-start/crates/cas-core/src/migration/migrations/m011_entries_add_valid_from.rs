//! Migration: entries_add_valid_from

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 11,
    name: "entries_add_valid_from",
    subsystem: Subsystem::Entries,
    description: "Add valid_from column for temporal validity tracking",
    up: &["ALTER TABLE entries ADD COLUMN valid_from TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('entries') WHERE name = 'valid_from'"),
};
