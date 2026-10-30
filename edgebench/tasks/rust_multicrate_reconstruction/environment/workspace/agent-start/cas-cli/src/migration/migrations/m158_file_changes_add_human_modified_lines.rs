//! Migration: Add human_modified_lines column to file_changes for tracking human overrides
use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 158,
    name: "file_changes_add_human_modified_lines",
    subsystem: Subsystem::Code,
    description: "Add human_modified_lines to track which lines were modified by humans after AI",
    up: &["ALTER TABLE file_changes ADD COLUMN human_modified_lines TEXT"],
    detect: Some(
        "SELECT COUNT(*) FROM pragma_table_info('file_changes') WHERE name = 'human_modified_lines'",
    ),
};
