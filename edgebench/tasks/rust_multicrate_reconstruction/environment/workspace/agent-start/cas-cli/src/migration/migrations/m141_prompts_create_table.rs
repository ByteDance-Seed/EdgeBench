//! Migration: Create prompts table for tracking user prompts in AI sessions
use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 141,
    name: "prompts_create_table",
    subsystem: Subsystem::Code,
    description: "Create prompts table for tracking user prompts and enabling code attribution",
    up: &[
        "CREATE TABLE IF NOT EXISTS prompts (
            id TEXT PRIMARY KEY,
            session_id TEXT NOT NULL,
            agent_id TEXT NOT NULL,
            content TEXT NOT NULL,
            content_hash TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            response_started TEXT,
            task_id TEXT,
            scope TEXT NOT NULL DEFAULT 'project',
            UNIQUE(content_hash, session_id)
        )",
        "CREATE INDEX IF NOT EXISTS idx_prompts_session ON prompts(session_id)",
        "CREATE INDEX IF NOT EXISTS idx_prompts_timestamp ON prompts(timestamp DESC)",
        "CREATE INDEX IF NOT EXISTS idx_prompts_task ON prompts(task_id)",
        "CREATE INDEX IF NOT EXISTS idx_prompts_content_hash ON prompts(content_hash)",
    ],
    detect: Some("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='prompts'"),
};
