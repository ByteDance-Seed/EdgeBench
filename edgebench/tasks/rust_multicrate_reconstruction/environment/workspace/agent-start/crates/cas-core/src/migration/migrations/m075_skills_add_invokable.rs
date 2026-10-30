//! Migration: skills_add_invokable

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 75,
    name: "skills_add_invokable",
    subsystem: Subsystem::Skills,
    description: "Add invokable flag for user-invokable skills",
    up: &["ALTER TABLE skills ADD COLUMN invokable INTEGER NOT NULL DEFAULT 0"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('skills') WHERE name = 'invokable'"),
};
