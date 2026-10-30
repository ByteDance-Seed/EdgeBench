//! Migration: agents_add_cc_session_id

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 97,
    name: "agents_add_cc_session_id",
    subsystem: Subsystem::Agents,
    description: "Add cc_session_id column for backward compatibility and cloud sync correlation",
    up: &["ALTER TABLE agents ADD COLUMN cc_session_id TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('agents') WHERE name = 'cc_session_id'"),
};
