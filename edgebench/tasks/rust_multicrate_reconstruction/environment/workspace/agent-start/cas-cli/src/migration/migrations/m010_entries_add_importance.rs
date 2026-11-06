//! Migration: entries_add_importance

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 10,
    name: "entries_add_importance",
    subsystem: Subsystem::Entries,
    description: "Add importance column for memory prioritization scoring",
    up: &["ALTER TABLE entries ADD COLUMN importance REAL NOT NULL DEFAULT 0.5"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('entries') WHERE name = 'importance'"),
};
