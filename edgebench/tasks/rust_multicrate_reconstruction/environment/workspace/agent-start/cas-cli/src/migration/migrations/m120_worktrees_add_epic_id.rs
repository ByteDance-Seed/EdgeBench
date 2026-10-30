//! Migration: worktrees_add_epic_id

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 120,
    name: "worktrees_add_epic_id",
    subsystem: Subsystem::Worktrees,
    description: "Add epic_id column to worktrees table for epic-scoped worktrees",
    up: &["ALTER TABLE worktrees ADD COLUMN epic_id TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('worktrees') WHERE name='epic_id'"),
};
