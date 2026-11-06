//! Migration: Create file_changes table for tracking AI-generated code changes
use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 142,
    name: "file_changes_create_table",
    subsystem: Subsystem::Code,
    description: "Create file_changes table for tracking file modifications with diffs for code attribution",
    up: &[
        "CREATE TABLE IF NOT EXISTS file_changes (
            id TEXT PRIMARY KEY,
            session_id TEXT NOT NULL,
            agent_id TEXT NOT NULL,
            prompt_id TEXT,
            repository TEXT NOT NULL,
            file_path TEXT NOT NULL,
            file_id TEXT,
            change_type TEXT NOT NULL,
            tool_name TEXT NOT NULL,
            old_content_hash TEXT,
            new_content_hash TEXT NOT NULL,
            diff TEXT NOT NULL,
            hunks_json TEXT NOT NULL,
            commit_hash TEXT,
            committed_at TEXT,
            created_at TEXT NOT NULL,
            scope TEXT NOT NULL DEFAULT 'project',
            FOREIGN KEY (prompt_id) REFERENCES prompts(id) ON DELETE SET NULL
        )",
        "CREATE INDEX IF NOT EXISTS idx_file_changes_session ON file_changes(session_id)",
        "CREATE INDEX IF NOT EXISTS idx_file_changes_file ON file_changes(repository, file_path)",
        "CREATE INDEX IF NOT EXISTS idx_file_changes_commit ON file_changes(commit_hash)",
        "CREATE INDEX IF NOT EXISTS idx_file_changes_prompt ON file_changes(prompt_id)",
        "CREATE INDEX IF NOT EXISTS idx_file_changes_created ON file_changes(created_at DESC)",
    ],
    detect: Some("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='file_changes'"),
};
