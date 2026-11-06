//! Migration: rules_idx_category

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 55,
    name: "rules_idx_category",
    subsystem: Subsystem::Rules,
    description: "Add index on category",
    up: &["CREATE INDEX IF NOT EXISTS idx_rules_category ON rules(category)"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_rules_category'",
    ),
};
