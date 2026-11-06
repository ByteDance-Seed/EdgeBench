//! Migration: entries_idx_importance

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 23,
    name: "entries_idx_importance",
    subsystem: Subsystem::Entries,
    description: "Add index on importance for sorting and filtering",
    up: &["CREATE INDEX IF NOT EXISTS idx_entries_importance ON entries(importance)"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_entries_importance'",
    ),
};
