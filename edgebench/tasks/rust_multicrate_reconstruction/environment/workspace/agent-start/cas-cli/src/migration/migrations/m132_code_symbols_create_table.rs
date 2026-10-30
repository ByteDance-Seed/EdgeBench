//! Migration: Create code_symbols table for indexed code symbols
use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 132,
    name: "code_symbols_create_table",
    subsystem: Subsystem::Code,
    description: "Create code_symbols table for indexed functions, structs, etc.",
    up: &["CREATE TABLE IF NOT EXISTS code_symbols (
            id TEXT PRIMARY KEY,
            qualified_name TEXT NOT NULL,
            name TEXT NOT NULL,
            kind TEXT NOT NULL,
            language TEXT NOT NULL,
            file_path TEXT NOT NULL,
            file_id TEXT NOT NULL,
            line_start INTEGER NOT NULL,
            line_end INTEGER NOT NULL,
            source TEXT NOT NULL,
            documentation TEXT,
            signature TEXT,
            parent_id TEXT,
            repository TEXT NOT NULL,
            commit_hash TEXT,
            created TEXT NOT NULL,
            updated TEXT NOT NULL,
            content_hash TEXT NOT NULL,
            scope TEXT NOT NULL DEFAULT 'project',
            FOREIGN KEY (file_id) REFERENCES code_files(id) ON DELETE CASCADE,
            FOREIGN KEY (parent_id) REFERENCES code_symbols(id) ON DELETE SET NULL
        )"],
    detect: Some("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='code_symbols'"),
};
