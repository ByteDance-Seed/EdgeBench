//! Migration: recordings_idx_started

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 176,
    name: "recordings_idx_started",
    subsystem: Subsystem::Recordings,
    description: "Add index on recordings.started_at for date range queries",
    up: &["CREATE INDEX IF NOT EXISTS idx_recordings_started ON recordings(started_at DESC)"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_recordings_started'",
    ),
};
