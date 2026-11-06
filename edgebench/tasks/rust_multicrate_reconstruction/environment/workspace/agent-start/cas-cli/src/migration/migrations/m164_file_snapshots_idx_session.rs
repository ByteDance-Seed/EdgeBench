//! Migration: Add index on session_id for file_snapshots table
use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 164,
    name: "file_snapshots_idx_session",
    subsystem: Subsystem::Code,
    description: "Add index on session_id for efficient session-based lookups",
    up: &["CREATE INDEX IF NOT EXISTS idx_snapshots_session ON file_snapshots(session_id)"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_snapshots_session'",
    ),
};
