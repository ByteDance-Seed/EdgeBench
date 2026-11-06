//! Migration: Add line_attributions_json column to file_changes for per-line prompt tracking
use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 157,
    name: "file_changes_add_line_attributions",
    subsystem: Subsystem::Code,
    description: "Add line_attributions_json for per-line prompt attribution mapping",
    up: &["ALTER TABLE file_changes ADD COLUMN line_attributions_json TEXT"],
    detect: Some(
        "SELECT COUNT(*) FROM pragma_table_info('file_changes') WHERE name = 'line_attributions_json'",
    ),
};
