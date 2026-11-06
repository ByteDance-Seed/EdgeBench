//! Migration: agents_add_ppid

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 96,
    name: "agents_add_ppid",
    subsystem: Subsystem::Agents,
    description: "Add ppid column for Claude Code parent PID tracking",
    up: &["ALTER TABLE agents ADD COLUMN ppid INTEGER"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('agents') WHERE name = 'ppid'"),
};
