//! Migration: Add index on code_files path column
use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 135,
    name: "code_files_idx_path",
    subsystem: Subsystem::Code,
    description: "Add index on path for faster file lookups",
    up: &["CREATE INDEX IF NOT EXISTS idx_code_files_path ON code_files(path)"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_code_files_path'",
    ),
};
