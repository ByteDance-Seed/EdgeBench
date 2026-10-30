//! Migration: recordings_fts_create

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 174,
    name: "recordings_fts_create",
    subsystem: Subsystem::Recordings,
    description: "Create FTS5 virtual table for searchable recording content",
    up: &[
        "CREATE VIRTUAL TABLE IF NOT EXISTS recordings_fts USING fts5(
            recording_id UNINDEXED,
            content,
            content_type UNINDEXED,
            timestamp_ms UNINDEXED
        )",
    ],
    detect: Some("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='recordings_fts'"),
};
