//! Migration: sessions_add_worktree_id

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 32,
    name: "sessions_add_worktree_id",
    subsystem: Subsystem::Entries,
    description: "Add worktree_id column to sessions table for git worktree tracking",
    up: &["ALTER TABLE sessions ADD COLUMN worktree_id TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('sessions') WHERE name = 'worktree_id'"),
};
