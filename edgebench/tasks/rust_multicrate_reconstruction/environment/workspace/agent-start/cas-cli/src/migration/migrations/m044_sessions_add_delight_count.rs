//! Migration: sessions_add_delight_count

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 44,
    name: "sessions_add_delight_count",
    subsystem: Subsystem::Entries,
    description: "Add delight_count column to sessions table for tracking positive signals",
    up: &["ALTER TABLE sessions ADD COLUMN delight_count INTEGER DEFAULT 0"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('sessions') WHERE name = 'delight_count'"),
};
