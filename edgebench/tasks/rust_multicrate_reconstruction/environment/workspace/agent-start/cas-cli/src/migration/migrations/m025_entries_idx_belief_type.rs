//! Migration: entries_idx_belief_type

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 25,
    name: "entries_idx_belief_type",
    subsystem: Subsystem::Entries,
    description: "Add index on belief_type for filtering by belief type",
    up: &["CREATE INDEX IF NOT EXISTS idx_entries_belief_type ON entries(belief_type)"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_entries_belief_type'",
    ),
};
