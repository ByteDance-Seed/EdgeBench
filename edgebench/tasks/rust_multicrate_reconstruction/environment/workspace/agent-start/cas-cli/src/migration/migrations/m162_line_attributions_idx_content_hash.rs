//! Migration: Add index on content_hash for line_attributions table
use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 162,
    name: "line_attributions_idx_content_hash",
    subsystem: Subsystem::Code,
    description: "Add index on content_hash for efficient content-based lookups",
    up: &["CREATE INDEX IF NOT EXISTS idx_line_attr_content ON line_attributions(content_hash)"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_line_attr_content'",
    ),
};
