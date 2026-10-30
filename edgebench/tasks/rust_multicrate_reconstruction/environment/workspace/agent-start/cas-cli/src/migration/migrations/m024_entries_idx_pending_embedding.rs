//! Migration: entries_idx_pending_embedding

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 24,
    name: "entries_idx_pending_embedding",
    subsystem: Subsystem::Entries,
    description: "Add partial index on pending_embedding for efficient embedding queue",
    up: &[
        "CREATE INDEX IF NOT EXISTS idx_entries_pending_embedding ON entries(pending_embedding) WHERE pending_embedding = 1",
    ],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_entries_pending_embedding'",
    ),
};
