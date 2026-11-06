//! Migration: sessions_add_title

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 28,
    name: "sessions_add_title",
    subsystem: Subsystem::Entries,
    description: "Add title column to sessions table",
    up: &["ALTER TABLE sessions ADD COLUMN title TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('sessions') WHERE name = 'title'"),
};
