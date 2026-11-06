//! Migration: entries_add_observation_type

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 4,
    name: "entries_add_observation_type",
    subsystem: Subsystem::Entries,
    description: "Add observation_type column for categorizing observations",
    up: &["ALTER TABLE entries ADD COLUMN observation_type TEXT"],
    detect: Some(
        "SELECT COUNT(*) FROM pragma_table_info('entries') WHERE name = 'observation_type'",
    ),
};
