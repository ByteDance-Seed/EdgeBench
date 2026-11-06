//! Migration: Create line_attributions table for content-hash based rebase-resilient attribution
use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 159,
    name: "line_attributions_create_table",
    subsystem: Subsystem::Code,
    description: "Create line_attributions table for content-hash based attribution that survives rebases",
    up: &["CREATE TABLE IF NOT EXISTS line_attributions (
            content_hash TEXT NOT NULL,
            context_hash TEXT,
            prompt_id TEXT NOT NULL,
            file_path TEXT NOT NULL,
            line_content TEXT NOT NULL,
            created_at TEXT NOT NULL,
            PRIMARY KEY (content_hash, context_hash, file_path)
        )"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='line_attributions'",
    ),
};
