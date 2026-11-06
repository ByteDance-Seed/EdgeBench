//! Migration: entries_add_branch

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 29,
    name: "entries_add_branch",
    subsystem: Subsystem::Entries,
    description: "Add branch column to entries table for git branch tracking",
    up: &["ALTER TABLE entries ADD COLUMN branch TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('entries') WHERE name = 'branch'"),
};
