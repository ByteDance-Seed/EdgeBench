//! Migration: entries_add_owner_id

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 36,
    name: "entries_add_owner_id",
    subsystem: Subsystem::Entries,
    description: "Add owner_id column for team context",
    up: &["ALTER TABLE entries ADD COLUMN owner_id TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('entries') WHERE name = 'owner_id'"),
};
