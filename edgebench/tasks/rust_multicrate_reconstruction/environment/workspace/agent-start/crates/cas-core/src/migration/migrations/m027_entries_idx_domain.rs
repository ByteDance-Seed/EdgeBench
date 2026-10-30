//! Migration: entries_idx_domain

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 27,
    name: "entries_idx_domain",
    subsystem: Subsystem::Entries,
    description: "Add index on domain for filtering by domain",
    up: &["CREATE INDEX IF NOT EXISTS idx_entries_domain ON entries(domain)"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_entries_domain'",
    ),
};
