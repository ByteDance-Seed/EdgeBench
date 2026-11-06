//! Migration: Add index on code_symbols kind column
use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 139,
    name: "code_symbols_idx_kind",
    subsystem: Subsystem::Code,
    description: "Add index on kind for faster symbol type filtering",
    up: &["CREATE INDEX IF NOT EXISTS idx_code_symbols_kind ON code_symbols(kind)"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_code_symbols_kind'",
    ),
};
