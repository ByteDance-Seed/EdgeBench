//! Migration: rules_add_visibility

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 61,
    name: "rules_add_visibility",
    subsystem: Subsystem::Rules,
    description: "Add visibility column for team sharing control",
    up: &["ALTER TABLE rules ADD COLUMN visibility TEXT NOT NULL DEFAULT 'private'"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('rules') WHERE name = 'visibility'"),
};
