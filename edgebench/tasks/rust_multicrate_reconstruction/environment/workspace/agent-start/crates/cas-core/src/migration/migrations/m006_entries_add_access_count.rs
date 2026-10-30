//! Migration: entries_add_access_count

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 6,
    name: "entries_add_access_count",
    subsystem: Subsystem::Entries,
    description: "Add access_count column for tracking entry usage frequency",
    up: &["ALTER TABLE entries ADD COLUMN access_count INTEGER NOT NULL DEFAULT 0"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('entries') WHERE name = 'access_count'"),
};
