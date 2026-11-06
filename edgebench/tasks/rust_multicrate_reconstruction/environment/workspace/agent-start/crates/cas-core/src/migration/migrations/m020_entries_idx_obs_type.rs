//! Migration: entries_idx_obs_type

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 20,
    name: "entries_idx_obs_type",
    subsystem: Subsystem::Entries,
    description: "Add index on observation_type for filtering by observation type",
    up: &["CREATE INDEX IF NOT EXISTS idx_entries_obs_type ON entries(observation_type)"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_entries_obs_type'",
    ),
};
