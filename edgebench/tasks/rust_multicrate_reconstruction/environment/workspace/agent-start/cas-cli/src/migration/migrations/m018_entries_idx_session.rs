//! Migration: entries_idx_session

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 18,
    name: "entries_idx_session",
    subsystem: Subsystem::Entries,
    description: "Add index on session_id for faster session lookups",
    up: &["CREATE INDEX IF NOT EXISTS idx_entries_session ON entries(session_id)"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_entries_session'",
    ),
};
