//! Migration: worktrees_idx_epic

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 121,
    name: "worktrees_idx_epic",
    subsystem: Subsystem::Worktrees,
    description: "Create index on worktrees.epic_id for efficient epic lookups",
    up: &["CREATE INDEX IF NOT EXISTS idx_worktrees_epic ON worktrees(epic_id)"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_worktrees_epic'",
    ),
};
