//! Migration: Add index on file_path for line_attributions table
use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 161,
    name: "line_attributions_idx_file",
    subsystem: Subsystem::Code,
    description: "Add index on file_path for efficient file-based lookups",
    up: &["CREATE INDEX IF NOT EXISTS idx_line_attr_file ON line_attributions(file_path)"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_line_attr_file'",
    ),
};
