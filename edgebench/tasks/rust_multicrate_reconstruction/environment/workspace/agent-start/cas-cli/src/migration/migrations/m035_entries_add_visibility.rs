//! Migration: entries_add_visibility

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 35,
    name: "entries_add_visibility",
    subsystem: Subsystem::Entries,
    description: "Add visibility column for team sharing control",
    up: &["ALTER TABLE entries ADD COLUMN visibility TEXT NOT NULL DEFAULT 'private'"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('entries') WHERE name = 'visibility'"),
};
