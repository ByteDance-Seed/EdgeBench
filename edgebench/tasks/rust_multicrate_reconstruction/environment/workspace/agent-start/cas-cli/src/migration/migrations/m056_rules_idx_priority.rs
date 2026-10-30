//! Migration: rules_idx_priority

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 56,
    name: "rules_idx_priority",
    subsystem: Subsystem::Rules,
    description: "Add index on priority",
    up: &["CREATE INDEX IF NOT EXISTS idx_rules_priority ON rules(priority)"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_rules_priority'",
    ),
};
