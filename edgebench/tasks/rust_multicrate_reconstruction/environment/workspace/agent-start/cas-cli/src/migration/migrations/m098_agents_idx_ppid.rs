//! Migration: agents_idx_ppid

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 98,
    name: "agents_idx_ppid",
    subsystem: Subsystem::Agents,
    description: "Add index on agents.ppid for efficient lookups by Claude Code PID",
    up: &["CREATE INDEX IF NOT EXISTS idx_agents_ppid ON agents(ppid)"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type = 'index' AND name = 'idx_agents_ppid'",
    ),
};
