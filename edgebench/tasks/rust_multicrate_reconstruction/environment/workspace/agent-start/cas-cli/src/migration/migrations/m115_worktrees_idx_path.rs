//! Migration: worktrees_idx_path

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 115,
    name: "worktrees_idx_path",
    subsystem: Subsystem::Worktrees,
    description: "Add index on path for lookup",
    up: &["CREATE INDEX IF NOT EXISTS idx_worktrees_path ON worktrees(path)"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_worktrees_path'",
    ),
};
