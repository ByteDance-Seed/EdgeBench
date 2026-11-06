//! Migration: entries_add_session_id

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 1,
    name: "entries_add_session_id",
    subsystem: Subsystem::Entries,
    description: "Add session_id column for session tracking",
    up: &["ALTER TABLE entries ADD COLUMN session_id TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('entries') WHERE name = 'session_id'"),
};
