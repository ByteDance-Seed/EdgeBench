//! Migration: entries_idx_pending_index

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 36,
    name: "entries_idx_pending_index",
    subsystem: Subsystem::Entries,
    description: "Add partial index for entries needing reindexing (indexed_at IS NULL OR updated_at > indexed_at)",
    up: &[
        // Partial index for efficient pending index queries
        "CREATE INDEX IF NOT EXISTS idx_entries_pending_index ON entries(updated_at) WHERE indexed_at IS NULL OR updated_at > indexed_at",
    ],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type = 'index' AND name = 'idx_entries_pending_index'",
    ),
};
