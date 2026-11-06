//! Migration: entries_add_confidence

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 16,
    name: "entries_add_confidence",
    subsystem: Subsystem::Entries,
    description: "Add confidence column for belief certainty scoring",
    up: &["ALTER TABLE entries ADD COLUMN confidence REAL NOT NULL DEFAULT 1.0"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('entries') WHERE name = 'confidence'"),
};
