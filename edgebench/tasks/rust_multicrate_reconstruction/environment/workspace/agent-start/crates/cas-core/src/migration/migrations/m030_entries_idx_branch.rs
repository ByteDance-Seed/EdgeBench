//! Migration: entries_idx_branch

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 30,
    name: "entries_idx_branch",
    subsystem: Subsystem::Entries,
    description: "Add index on branch for filtering entries by git branch",
    up: &["CREATE INDEX IF NOT EXISTS idx_entries_branch ON entries(branch)"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_entries_branch'",
    ),
};
