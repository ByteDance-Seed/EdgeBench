//! Migration: Add index on code_symbols file_id column
use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 138,
    name: "code_symbols_idx_file",
    subsystem: Subsystem::Code,
    description: "Add index on file_id for faster file-to-symbols lookups",
    up: &["CREATE INDEX IF NOT EXISTS idx_code_symbols_file ON code_symbols(file_id)"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_code_symbols_file'",
    ),
};
