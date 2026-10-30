//! Migration: sessions_add_branch

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 31,
    name: "sessions_add_branch",
    subsystem: Subsystem::Entries,
    description: "Add branch column to sessions table for git branch tracking",
    up: &["ALTER TABLE sessions ADD COLUMN branch TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('sessions') WHERE name = 'branch'"),
};
