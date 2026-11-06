//! Migration: entries_idx_memory_tier

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 22,
    name: "entries_idx_memory_tier",
    subsystem: Subsystem::Entries,
    description: "Add index on memory_tier for filtering by tier",
    up: &["CREATE INDEX IF NOT EXISTS idx_entries_memory_tier ON entries(memory_tier)"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_entries_memory_tier'",
    ),
};
