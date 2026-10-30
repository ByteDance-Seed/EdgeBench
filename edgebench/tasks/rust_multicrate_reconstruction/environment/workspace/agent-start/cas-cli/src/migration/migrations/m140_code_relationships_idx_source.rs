//! Migration: Add index on code_relationships source_id column
use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 140,
    name: "code_relationships_idx_source",
    subsystem: Subsystem::Code,
    description: "Add index on source_id for faster relationship lookups",
    up: &[
        "CREATE INDEX IF NOT EXISTS idx_code_relationships_source ON code_relationships(source_id)",
    ],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_code_relationships_source'",
    ),
};
