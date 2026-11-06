//! Migration: entries_add_domain

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 17,
    name: "entries_add_domain",
    subsystem: Subsystem::Entries,
    description: "Add domain column for knowledge domain classification",
    up: &["ALTER TABLE entries ADD COLUMN domain TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('entries') WHERE name = 'domain'"),
};
