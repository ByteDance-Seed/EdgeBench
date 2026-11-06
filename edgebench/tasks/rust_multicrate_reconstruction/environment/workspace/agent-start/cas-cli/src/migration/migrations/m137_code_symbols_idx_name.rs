//! Migration: Add index on code_symbols name column
use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 137,
    name: "code_symbols_idx_name",
    subsystem: Subsystem::Code,
    description: "Add index on name for faster symbol name lookups",
    up: &["CREATE INDEX IF NOT EXISTS idx_code_symbols_name ON code_symbols(name)"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_code_symbols_name'",
    ),
};
