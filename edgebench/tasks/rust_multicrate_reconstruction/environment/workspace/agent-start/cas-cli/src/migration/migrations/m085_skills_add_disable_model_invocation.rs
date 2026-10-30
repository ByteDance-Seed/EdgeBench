//! Migration: skills_add_disable_model_invocation

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 85,
    name: "skills_add_disable_model_invocation",
    subsystem: Subsystem::Skills,
    description: "Add disable_model_invocation column for blocking model from invoking skill",
    up: &["ALTER TABLE skills ADD COLUMN disable_model_invocation INTEGER NOT NULL DEFAULT 0"],
    detect: Some(
        "SELECT COUNT(*) FROM pragma_table_info('skills') WHERE name = 'disable_model_invocation'",
    ),
};
