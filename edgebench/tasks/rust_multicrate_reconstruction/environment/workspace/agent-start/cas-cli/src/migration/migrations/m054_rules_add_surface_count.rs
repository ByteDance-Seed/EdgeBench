//! Migration: rules_add_surface_count

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 54,
    name: "rules_add_surface_count",
    subsystem: Subsystem::Rules,
    description: "Add surface_count column for tracking rule surfacing",
    up: &["ALTER TABLE rules ADD COLUMN surface_count INTEGER NOT NULL DEFAULT 0"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('rules') WHERE name = 'surface_count'"),
};
