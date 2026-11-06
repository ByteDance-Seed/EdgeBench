//! Migration: recordings_create_table

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 171,
    name: "recordings_create_table",
    subsystem: Subsystem::Recordings,
    description: "Create recordings table for terminal recording metadata",
    up: &["CREATE TABLE IF NOT EXISTS recordings (
            id TEXT PRIMARY KEY,
            session_id TEXT,
            started_at TEXT NOT NULL,
            ended_at TEXT,
            duration_ms INTEGER,
            file_path TEXT NOT NULL,
            file_size INTEGER,
            title TEXT,
            description TEXT,
            created_at TEXT NOT NULL DEFAULT (datetime('now'))
        )"],
    detect: Some("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='recordings'"),
};
