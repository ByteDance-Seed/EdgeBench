//! Migration: Add index on code_files language column
use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 136,
    name: "code_files_idx_language",
    subsystem: Subsystem::Code,
    description: "Add index on language for faster language filtering",
    up: &["CREATE INDEX IF NOT EXISTS idx_code_files_language ON code_files(language)"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_code_files_language'",
    ),
};
