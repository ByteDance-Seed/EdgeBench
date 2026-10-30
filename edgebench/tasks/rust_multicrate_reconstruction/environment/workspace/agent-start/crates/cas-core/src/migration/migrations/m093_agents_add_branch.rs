//! Migration: agents_add_branch

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 93,
    name: "agents_add_branch",
    subsystem: Subsystem::Agents,
    description: "Add branch column to agents",
    up: &["ALTER TABLE agents ADD COLUMN branch TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('agents') WHERE name = 'branch'"),
};
