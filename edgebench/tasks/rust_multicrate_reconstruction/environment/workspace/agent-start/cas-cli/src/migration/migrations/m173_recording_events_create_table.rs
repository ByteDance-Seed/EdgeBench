//! Migration: recording_events_create_table

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 173,
    name: "recording_events_create_table",
    subsystem: Subsystem::Recordings,
    description: "Create recording_events table for CAS entity correlation",
    up: &["CREATE TABLE IF NOT EXISTS recording_events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            recording_id TEXT NOT NULL,
            timestamp_ms INTEGER NOT NULL,
            event_type TEXT NOT NULL,
            entity_type TEXT,
            entity_id TEXT,
            metadata TEXT,
            FOREIGN KEY (recording_id) REFERENCES recordings(id) ON DELETE CASCADE
        )"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='recording_events'",
    ),
};
