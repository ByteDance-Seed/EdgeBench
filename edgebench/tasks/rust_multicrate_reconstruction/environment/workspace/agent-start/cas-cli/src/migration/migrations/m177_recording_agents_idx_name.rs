//! Migration: recording_agents_idx_name

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 177,
    name: "recording_agents_idx_name",
    subsystem: Subsystem::Recordings,
    description: "Add index on recording_agents.agent_name for agent lookups",
    up: &["CREATE INDEX IF NOT EXISTS idx_recording_agents_name ON recording_agents(agent_name)"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_recording_agents_name'",
    ),
};
