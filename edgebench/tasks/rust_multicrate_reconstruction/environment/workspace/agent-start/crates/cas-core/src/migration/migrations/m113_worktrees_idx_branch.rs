//! Migration: worktrees_idx_branch

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 113,
    name: "worktrees_idx_branch",
    subsystem: Subsystem::Worktrees,
    description: "Add index on branch for worktrees",
    up: &["CREATE INDEX IF NOT EXISTS idx_worktrees_branch ON worktrees(branch)"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_worktrees_branch'",
    ),
};
