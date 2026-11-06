//! Migration: entries_add_last_reviewed

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 38,
    name: "entries_add_last_reviewed",
    subsystem: Subsystem::Entries,
    description: "Add last_reviewed column for tracking learning review hook analysis",
    up: &["ALTER TABLE entries ADD COLUMN last_reviewed TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('entries') WHERE name = 'last_reviewed'"),
};
