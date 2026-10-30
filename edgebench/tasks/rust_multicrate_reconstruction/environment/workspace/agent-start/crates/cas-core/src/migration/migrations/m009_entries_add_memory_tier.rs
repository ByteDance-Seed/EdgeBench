//! Migration: entries_add_memory_tier

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 9,
    name: "entries_add_memory_tier",
    subsystem: Subsystem::Entries,
    description: "Add memory_tier column for hierarchical memory management",
    up: &["ALTER TABLE entries ADD COLUMN memory_tier TEXT NOT NULL DEFAULT 'working'"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('entries') WHERE name = 'memory_tier'"),
};
