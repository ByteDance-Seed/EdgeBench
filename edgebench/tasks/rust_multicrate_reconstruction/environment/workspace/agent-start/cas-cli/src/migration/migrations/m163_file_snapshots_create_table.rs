//! Migration: Create file_snapshots table for tracking file state after AI changes
use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 163,
    name: "file_snapshots_create_table",
    subsystem: Subsystem::Code,
    description: "Create file_snapshots table for detecting human modifications to AI code",
    up: &["CREATE TABLE IF NOT EXISTS file_snapshots (
            file_path TEXT NOT NULL,
            session_id TEXT NOT NULL,
            content_hash TEXT NOT NULL,
            line_hashes_json TEXT NOT NULL,
            prompt_id TEXT NOT NULL,
            created_at TEXT NOT NULL,
            PRIMARY KEY (file_path, session_id)
        )"],
    detect: Some("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='file_snapshots'"),
};
