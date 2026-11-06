//! Migration: Add epic_verification_owner column to tasks table
//!
//! This column tracks which agent (usually the supervisor) is responsible
//! for epic-level verification. When set, that agent gets jailed for
//! verification instead of the task closer.

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 166,
    name: "tasks_add_epic_verification_owner",
    subsystem: Subsystem::Tasks,
    description: "Add epic_verification_owner column to tasks for supervisor jail in factory mode",
    up: &["ALTER TABLE tasks ADD COLUMN epic_verification_owner TEXT"],
    detect: Some(
        "SELECT COUNT(*) FROM pragma_table_info('tasks') WHERE name = 'epic_verification_owner'",
    ),
};
