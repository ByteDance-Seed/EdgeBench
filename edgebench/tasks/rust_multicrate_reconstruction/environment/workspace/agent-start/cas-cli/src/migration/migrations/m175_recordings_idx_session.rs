//! Migration: recordings_idx_session

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 175,
    name: "recordings_idx_session",
    subsystem: Subsystem::Recordings,
    description: "Add index on recordings.session_id for session lookups",
    up: &["CREATE INDEX IF NOT EXISTS idx_recordings_session ON recordings(session_id)"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_recordings_session'",
    ),
};
