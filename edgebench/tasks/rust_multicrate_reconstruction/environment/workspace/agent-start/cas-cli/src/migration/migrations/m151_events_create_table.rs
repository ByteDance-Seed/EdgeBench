//! Migration: events_create_table

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 151,
    name: "events_create_table",
    subsystem: Subsystem::Events,
    description: "Create events table for sidecar activity feed",
    up: &[
        "CREATE TABLE IF NOT EXISTS events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            event_type TEXT NOT NULL,
            entity_type TEXT NOT NULL,
            entity_id TEXT NOT NULL,
            summary TEXT NOT NULL,
            metadata TEXT,
            created_at TEXT NOT NULL DEFAULT (datetime('now')),
            session_id TEXT
        )",
        "CREATE INDEX IF NOT EXISTS idx_events_created ON events(created_at DESC)",
        "CREATE INDEX IF NOT EXISTS idx_events_type ON events(event_type)",
        "CREATE INDEX IF NOT EXISTS idx_events_entity ON events(entity_type, entity_id)",
        "CREATE INDEX IF NOT EXISTS idx_events_session ON events(session_id)",
    ],
    detect: Some("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='events'"),
};
