//! Migration: entries_add_raw_content

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 7,
    name: "entries_add_raw_content",
    subsystem: Subsystem::Entries,
    description: "Add raw_content column for storing original unprocessed content",
    up: &["ALTER TABLE entries ADD COLUMN raw_content TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('entries') WHERE name = 'raw_content'"),
};
