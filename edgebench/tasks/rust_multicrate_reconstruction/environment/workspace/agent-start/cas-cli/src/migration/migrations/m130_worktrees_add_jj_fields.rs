//! Migration: Add jj (Jujutsu) fields to worktrees table
//!
//! Adds change_id, workspace_name, and has_conflicts columns to support
//! jj workspace tracking alongside git worktree tracking.

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 130,
    name: "worktrees_add_jj_fields",
    subsystem: Subsystem::Worktrees,
    description: "Add change_id, workspace_name, has_conflicts columns for jj workspace support",
    up: &[
        "ALTER TABLE worktrees ADD COLUMN change_id TEXT",
        "ALTER TABLE worktrees ADD COLUMN workspace_name TEXT",
        "ALTER TABLE worktrees ADD COLUMN has_conflicts INTEGER NOT NULL DEFAULT 0",
    ],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('worktrees') WHERE name = 'change_id'"),
};
