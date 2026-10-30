//! Migration: working_epics_create_table
//!
//! Tracks which epics an agent is actively working on.
//! When an agent claims a subtask of an epic, the epic is recorded here.
//! Used by exit blocker to check if epic has remaining open subtasks.

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 95,
    name: "working_epics_create_table",
    subsystem: Subsystem::Agents,
    description: "Create working_epics table for exit blocker epic tracking",
    up: &[
        r#"CREATE TABLE IF NOT EXISTS working_epics (
            agent_id TEXT NOT NULL,
            epic_id TEXT NOT NULL,
            started_at TEXT NOT NULL,
            PRIMARY KEY (agent_id, epic_id)
        )"#,
        "CREATE INDEX IF NOT EXISTS idx_working_epics_agent ON working_epics(agent_id)",
    ],
    detect: Some("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='working_epics'"),
};
