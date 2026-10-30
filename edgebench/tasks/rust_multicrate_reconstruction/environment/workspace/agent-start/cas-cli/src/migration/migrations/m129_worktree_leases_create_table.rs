//! Migration: worktree_leases_create_table

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 129,
    name: "worktree_leases_create_table",
    subsystem: Subsystem::Worktrees,
    description: "Create worktree_leases table for exclusive worktree locking",
    up: &[
        "CREATE TABLE IF NOT EXISTS worktree_leases (
            worktree_id TEXT PRIMARY KEY,
            agent_id TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'active',
            acquired_at TEXT NOT NULL,
            expires_at TEXT NOT NULL,
            renewed_at TEXT NOT NULL,
            renewal_count INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (worktree_id) REFERENCES worktrees(id) ON DELETE CASCADE,
            FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE
        )",
        "CREATE INDEX IF NOT EXISTS idx_worktree_leases_agent ON worktree_leases(agent_id)",
        "CREATE INDEX IF NOT EXISTS idx_worktree_leases_status ON worktree_leases(status)",
        "CREATE INDEX IF NOT EXISTS idx_worktree_leases_expires ON worktree_leases(expires_at)",
    ],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='worktree_leases'",
    ),
};
