//! Migration: entries_add_review_after

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 13,
    name: "entries_add_review_after",
    subsystem: Subsystem::Entries,
    description: "Add review_after column for scheduled memory review",
    up: &["ALTER TABLE entries ADD COLUMN review_after TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('entries') WHERE name = 'review_after'"),
};
