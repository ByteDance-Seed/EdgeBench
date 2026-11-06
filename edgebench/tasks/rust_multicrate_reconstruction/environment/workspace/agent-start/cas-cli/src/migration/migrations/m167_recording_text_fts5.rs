//! Migration: recording_text_fts5
//!
//! Creates FTS5 virtual table for full-text search of recording content.

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 167,
    name: "recording_text_fts5",
    subsystem: Subsystem::Recording,
    description: "Create FTS5 table for recording text search",
    up: &[
        // Content table - stores the actual text with metadata
        "CREATE TABLE IF NOT EXISTS recording_text (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            recording_id TEXT NOT NULL,
            agent_name TEXT NOT NULL,
            timestamp_ms INTEGER NOT NULL,
            text_content TEXT NOT NULL,
            created_at TEXT NOT NULL DEFAULT (datetime('now'))
        )",
        // FTS5 virtual table for full-text search
        "CREATE VIRTUAL TABLE IF NOT EXISTS recording_text_fts USING fts5(
            text_content,
            content='recording_text',
            content_rowid='id'
        )",
        // Triggers to keep FTS in sync
        "CREATE TRIGGER IF NOT EXISTS recording_text_ai AFTER INSERT ON recording_text BEGIN
            INSERT INTO recording_text_fts(rowid, text_content) VALUES (new.id, new.text_content);
        END",
        "CREATE TRIGGER IF NOT EXISTS recording_text_ad AFTER DELETE ON recording_text BEGIN
            INSERT INTO recording_text_fts(recording_text_fts, rowid, text_content) VALUES ('delete', old.id, old.text_content);
        END",
        "CREATE TRIGGER IF NOT EXISTS recording_text_au AFTER UPDATE ON recording_text BEGIN
            INSERT INTO recording_text_fts(recording_text_fts, rowid, text_content) VALUES ('delete', old.id, old.text_content);
            INSERT INTO recording_text_fts(rowid, text_content) VALUES (new.id, new.text_content);
        END",
        // Index for filtering by recording
        "CREATE INDEX IF NOT EXISTS idx_recording_text_recording ON recording_text(recording_id)",
        "CREATE INDEX IF NOT EXISTS idx_recording_text_agent ON recording_text(agent_name)",
        "CREATE INDEX IF NOT EXISTS idx_recording_text_timestamp ON recording_text(timestamp_ms)",
    ],
    detect: Some("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='recording_text_fts'"),
};
