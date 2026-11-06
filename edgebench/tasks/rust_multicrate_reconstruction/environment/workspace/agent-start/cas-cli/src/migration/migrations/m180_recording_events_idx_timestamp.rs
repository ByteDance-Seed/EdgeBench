//! Migration: recording_events_idx_timestamp

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 180,
    name: "recording_events_idx_timestamp",
    subsystem: Subsystem::Recordings,
    description: "Add index on recording_events.timestamp_ms for time-based queries",
    up: &[
        "CREATE INDEX IF NOT EXISTS idx_recording_events_timestamp ON recording_events(timestamp_ms)",
    ],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_recording_events_timestamp'",
    ),
};
