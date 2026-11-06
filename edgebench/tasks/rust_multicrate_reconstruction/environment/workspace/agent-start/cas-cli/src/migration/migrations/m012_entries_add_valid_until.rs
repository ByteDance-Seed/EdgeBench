//! Migration: entries_add_valid_until

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 12,
    name: "entries_add_valid_until",
    subsystem: Subsystem::Entries,
    description: "Add valid_until column for temporal validity expiration",
    up: &["ALTER TABLE entries ADD COLUMN valid_until TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('entries') WHERE name = 'valid_until'"),
};
