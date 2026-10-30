//! Migration: entries_add_source_tool

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 2,
    name: "entries_add_source_tool",
    subsystem: Subsystem::Entries,
    description: "Add source_tool column for tracking entry origin",
    up: &["ALTER TABLE entries ADD COLUMN source_tool TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('entries') WHERE name = 'source_tool'"),
};
