//! Migration: Create code_files table for tracking source code files
use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 131,
    name: "code_files_create_table",
    subsystem: Subsystem::Code,
    description: "Create code_files table for tracking indexed source code files",
    up: &["CREATE TABLE IF NOT EXISTS code_files (
            id TEXT PRIMARY KEY,
            path TEXT NOT NULL,
            repository TEXT NOT NULL,
            language TEXT NOT NULL,
            size INTEGER NOT NULL DEFAULT 0,
            line_count INTEGER NOT NULL DEFAULT 0,
            commit_hash TEXT,
            content_hash TEXT NOT NULL,
            created TEXT NOT NULL,
            updated TEXT NOT NULL,
            scope TEXT NOT NULL DEFAULT 'project',
            UNIQUE(repository, path)
        )"],
    detect: Some("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='code_files'"),
};
