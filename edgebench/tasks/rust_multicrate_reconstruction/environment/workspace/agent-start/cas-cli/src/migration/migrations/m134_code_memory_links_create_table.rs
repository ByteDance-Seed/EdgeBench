//! Migration: Create code_memory_links table for linking code to memories
use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 134,
    name: "code_memory_links_create_table",
    subsystem: Subsystem::Code,
    description: "Create code_memory_links table to associate code with CAS memory entries",
    up: &["CREATE TABLE IF NOT EXISTS code_memory_links (
            code_id TEXT NOT NULL,
            entry_id TEXT NOT NULL,
            link_type TEXT NOT NULL,
            confidence REAL NOT NULL DEFAULT 0.8,
            created TEXT NOT NULL,
            PRIMARY KEY (code_id, entry_id, link_type)
        )"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='code_memory_links'",
    ),
};
