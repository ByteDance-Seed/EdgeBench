//! Migration: worktrees_create_table

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 111,
    name: "worktrees_create_table",
    subsystem: Subsystem::Worktrees,
    description: "Create worktrees table for tracking git worktrees",
    up: &["CREATE TABLE IF NOT EXISTS worktrees (
            id TEXT PRIMARY KEY,
            task_id TEXT,
            branch TEXT NOT NULL,
            parent_branch TEXT NOT NULL,
            path TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'active',
            created_at TEXT NOT NULL,
            merged_at TEXT,
            removed_at TEXT,
            created_by_agent TEXT,
            merge_commit TEXT
        )"],
    detect: Some("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='worktrees'"),
};
