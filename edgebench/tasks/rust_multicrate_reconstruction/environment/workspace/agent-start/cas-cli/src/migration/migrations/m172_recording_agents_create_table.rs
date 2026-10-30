//! Migration: recording_agents_create_table

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 172,
    name: "recording_agents_create_table",
    subsystem: Subsystem::Recordings,
    description: "Create recording_agents table for agent-specific recording data",
    up: &["CREATE TABLE IF NOT EXISTS recording_agents (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            recording_id TEXT NOT NULL,
            agent_name TEXT NOT NULL,
            agent_type TEXT NOT NULL,
            file_path TEXT NOT NULL,
            created_at TEXT NOT NULL DEFAULT (datetime('now')),
            FOREIGN KEY (recording_id) REFERENCES recordings(id) ON DELETE CASCADE
        )"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='recording_agents'",
    ),
};
