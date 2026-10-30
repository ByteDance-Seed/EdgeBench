//! Migration: entries_idx_stability

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 21,
    name: "entries_idx_stability",
    subsystem: Subsystem::Entries,
    description: "Add index on stability for filtering by stability level",
    up: &["CREATE INDEX IF NOT EXISTS idx_entries_stability ON entries(stability)"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_entries_stability'",
    ),
};
