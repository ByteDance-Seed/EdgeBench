//! Migration: entries_idx_pending

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 19,
    name: "entries_idx_pending",
    subsystem: Subsystem::Entries,
    description: "Add index on pending_extraction for faster extraction queries",
    up: &["CREATE INDEX IF NOT EXISTS idx_entries_pending ON entries(pending_extraction)"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_entries_pending'",
    ),
};
