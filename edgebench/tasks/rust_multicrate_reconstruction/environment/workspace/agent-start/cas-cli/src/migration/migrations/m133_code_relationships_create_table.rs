//! Migration: Create code_relationships table for symbol relationships
use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 133,
    name: "code_relationships_create_table",
    subsystem: Subsystem::Code,
    description: "Create code_relationships table for imports, calls, extends, etc.",
    up: &["CREATE TABLE IF NOT EXISTS code_relationships (
            id TEXT PRIMARY KEY,
            source_id TEXT NOT NULL,
            target_id TEXT NOT NULL,
            relation_type TEXT NOT NULL,
            weight REAL NOT NULL DEFAULT 1.0,
            created TEXT NOT NULL,
            FOREIGN KEY (source_id) REFERENCES code_symbols(id) ON DELETE CASCADE,
            FOREIGN KEY (target_id) REFERENCES code_symbols(id) ON DELETE CASCADE,
            UNIQUE(source_id, target_id, relation_type)
        )"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='code_relationships'",
    ),
};
