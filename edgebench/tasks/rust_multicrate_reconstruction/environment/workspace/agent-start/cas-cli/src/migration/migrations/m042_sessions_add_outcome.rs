//! Migration: sessions_add_outcome

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 42,
    name: "sessions_add_outcome",
    subsystem: Subsystem::Entries,
    description: "Add outcome column to sessions table for tracking session productivity",
    up: &["ALTER TABLE sessions ADD COLUMN outcome TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('sessions') WHERE name = 'outcome'"),
};
