//! Migration: rules_add_owner_id

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 62,
    name: "rules_add_owner_id",
    subsystem: Subsystem::Rules,
    description: "Add owner_id column for team context",
    up: &["ALTER TABLE rules ADD COLUMN owner_id TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('rules') WHERE name = 'owner_id'"),
};
