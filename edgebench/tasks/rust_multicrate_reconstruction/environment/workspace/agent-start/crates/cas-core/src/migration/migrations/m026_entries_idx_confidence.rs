//! Migration: entries_idx_confidence

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 26,
    name: "entries_idx_confidence",
    subsystem: Subsystem::Entries,
    description: "Add index on confidence for sorting and filtering",
    up: &["CREATE INDEX IF NOT EXISTS idx_entries_confidence ON entries(confidence)"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_entries_confidence'",
    ),
};
