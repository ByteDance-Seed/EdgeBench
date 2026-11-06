//! Migration: worktrees_idx_status

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 114,
    name: "worktrees_idx_status",
    subsystem: Subsystem::Worktrees,
    description: "Add index on status for worktrees",
    up: &["CREATE INDEX IF NOT EXISTS idx_worktrees_status ON worktrees(status)"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_worktrees_status'",
    ),
};
