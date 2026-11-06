//! Migration: entries_add_pending_embedding

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 14,
    name: "entries_add_pending_embedding",
    subsystem: Subsystem::Entries,
    description: "Add pending_embedding column for embedding generation queue",
    up: &["ALTER TABLE entries ADD COLUMN pending_embedding INTEGER NOT NULL DEFAULT 1"],
    detect: Some(
        "SELECT COUNT(*) FROM pragma_table_info('entries') WHERE name = 'pending_embedding'",
    ),
};
