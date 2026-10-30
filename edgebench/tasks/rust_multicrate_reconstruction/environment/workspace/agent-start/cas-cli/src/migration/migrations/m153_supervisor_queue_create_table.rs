//! Migration: supervisor_queue_create_table

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 153,
    name: "supervisor_queue_create_table",
    subsystem: Subsystem::Agents,
    description: "Create supervisor_queue table for Director to batch notifications to Supervisor in factory sessions",
    up: &[
        r#"CREATE TABLE IF NOT EXISTS supervisor_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            supervisor_id TEXT NOT NULL,
            event_type TEXT NOT NULL,
            payload TEXT NOT NULL,
            priority INTEGER NOT NULL DEFAULT 2,
            created_at TEXT NOT NULL DEFAULT (datetime('now')),
            processed_at TEXT
        )"#,
        r#"CREATE INDEX IF NOT EXISTS idx_supervisor_queue_supervisor ON supervisor_queue(supervisor_id)"#,
        r#"CREATE INDEX IF NOT EXISTS idx_supervisor_queue_pending ON supervisor_queue(supervisor_id, priority) WHERE processed_at IS NULL"#,
    ],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='supervisor_queue'",
    ),
};
