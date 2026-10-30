//! Migration: entries_add_belief_type

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 15,
    name: "entries_add_belief_type",
    subsystem: Subsystem::Entries,
    description: "Add belief_type column for epistemic categorization",
    up: &["ALTER TABLE entries ADD COLUMN belief_type TEXT NOT NULL DEFAULT 'fact'"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('entries') WHERE name = 'belief_type'"),
};
