//! Migration: entries_add_pending_extraction

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 3,
    name: "entries_add_pending_extraction",
    subsystem: Subsystem::Entries,
    description: "Add pending_extraction column for entity extraction queue",
    up: &["ALTER TABLE entries ADD COLUMN pending_extraction INTEGER NOT NULL DEFAULT 0"],
    detect: Some(
        "SELECT COUNT(*) FROM pragma_table_info('entries') WHERE name = 'pending_extraction'",
    ),
};
