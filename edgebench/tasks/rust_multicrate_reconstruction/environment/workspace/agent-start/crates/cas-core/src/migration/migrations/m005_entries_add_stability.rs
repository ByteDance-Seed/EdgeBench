//! Migration: entries_add_stability

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 5,
    name: "entries_add_stability",
    subsystem: Subsystem::Entries,
    description: "Add stability column for memory consolidation scoring",
    up: &["ALTER TABLE entries ADD COLUMN stability REAL NOT NULL DEFAULT 0.5"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('entries') WHERE name = 'stability'"),
};
