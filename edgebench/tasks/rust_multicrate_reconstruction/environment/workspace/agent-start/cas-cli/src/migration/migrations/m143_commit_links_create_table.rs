//! Migration: Create commit_links table for tracking git commits from AI sessions
use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 143,
    name: "commit_links_create_table",
    subsystem: Subsystem::Code,
    description: "Create commit_links table for associating git commits with AI sessions and prompts",
    up: &[
        "CREATE TABLE IF NOT EXISTS commit_links (
            commit_hash TEXT PRIMARY KEY,
            session_id TEXT NOT NULL,
            agent_id TEXT NOT NULL,
            branch TEXT NOT NULL,
            message TEXT NOT NULL,
            files_changed TEXT NOT NULL,
            prompt_ids TEXT NOT NULL,
            committed_at TEXT NOT NULL,
            author TEXT NOT NULL,
            scope TEXT NOT NULL DEFAULT 'project'
        )",
        "CREATE INDEX IF NOT EXISTS idx_commit_links_session ON commit_links(session_id)",
        "CREATE INDEX IF NOT EXISTS idx_commit_links_branch ON commit_links(branch)",
        "CREATE INDEX IF NOT EXISTS idx_commit_links_committed ON commit_links(committed_at DESC)",
    ],
    detect: Some("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='commit_links'"),
};
