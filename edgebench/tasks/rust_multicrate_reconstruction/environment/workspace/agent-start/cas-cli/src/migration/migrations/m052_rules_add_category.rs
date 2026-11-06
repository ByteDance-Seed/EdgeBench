//! Migration: rules_add_category

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 52,
    name: "rules_add_category",
    subsystem: Subsystem::Rules,
    description: "Add category column for rule categorization",
    up: &["ALTER TABLE rules ADD COLUMN category TEXT NOT NULL DEFAULT 'general'"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('rules') WHERE name = 'category'"),
};
