//! Migration: recording_agents_idx_recording

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 178,
    name: "recording_agents_idx_recording",
    subsystem: Subsystem::Recordings,
    description: "Add index on recording_agents.recording_id for join lookups",
    up: &[
        "CREATE INDEX IF NOT EXISTS idx_recording_agents_recording ON recording_agents(recording_id)",
    ],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_recording_agents_recording'",
    ),
};
