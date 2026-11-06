//! Migration: agents_add_role

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 152,
    name: "agents_add_role",
    subsystem: Subsystem::Agents,
    description: "Add role column to agents for factory session roles (standard, director, supervisor, worker)",
    up: &["ALTER TABLE agents ADD COLUMN role TEXT NOT NULL DEFAULT 'standard'"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('agents') WHERE name = 'role'"),
};
