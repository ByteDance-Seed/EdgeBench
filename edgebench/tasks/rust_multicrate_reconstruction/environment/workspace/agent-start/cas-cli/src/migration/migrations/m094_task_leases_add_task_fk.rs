//! Migration: task_leases_add_task_fk
//!
//! Adds foreign key constraint on task_id to ensure task_leases are cleaned up
//! when tasks are deleted. SQLite requires table recreation for FK changes.

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 94,
    name: "task_leases_add_task_fk",
    subsystem: Subsystem::Agents,
    description: "Add foreign key on task_id to cascade deletes",
    up: &[
        // Create new table with both FKs
        "CREATE TABLE task_leases_new (
            task_id TEXT PRIMARY KEY,
            agent_id TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'active',
            acquired_at TEXT NOT NULL,
            expires_at TEXT NOT NULL,
            renewed_at TEXT NOT NULL,
            renewal_count INTEGER NOT NULL DEFAULT 0,
            claim_reason TEXT,
            epoch INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
            FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE
        )",
        // Copy existing data (only for leases with valid tasks)
        "INSERT OR IGNORE INTO task_leases_new
            SELECT l.task_id, l.agent_id, l.status, l.acquired_at, l.expires_at,
                   l.renewed_at, l.renewal_count, l.claim_reason, l.epoch
            FROM task_leases l
            INNER JOIN tasks t ON l.task_id = t.id",
        // Drop old table
        "DROP TABLE task_leases",
        // Rename new table
        "ALTER TABLE task_leases_new RENAME TO task_leases",
        // Recreate indexes
        "CREATE INDEX IF NOT EXISTS idx_leases_agent ON task_leases(agent_id)",
        "CREATE INDEX IF NOT EXISTS idx_leases_status ON task_leases(status)",
        "CREATE INDEX IF NOT EXISTS idx_leases_expires ON task_leases(expires_at)",
    ],
    // Detect by checking if the FK on task_id exists
    // SQLite stores FK info in sqlite_master - we check for the new table structure
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='task_leases' AND sql LIKE '%REFERENCES tasks(id)%'",
    ),
};
