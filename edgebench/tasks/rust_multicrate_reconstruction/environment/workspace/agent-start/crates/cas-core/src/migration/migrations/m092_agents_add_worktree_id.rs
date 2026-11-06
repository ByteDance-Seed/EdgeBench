//! Migration: agents_add_worktree_id

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 92,
    name: "agents_add_worktree_id",
    subsystem: Subsystem::Agents,
    description: "Add worktree_id column to agents",
    up: &["ALTER TABLE agents ADD COLUMN worktree_id TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('agents') WHERE name = 'worktree_id'"),
};
