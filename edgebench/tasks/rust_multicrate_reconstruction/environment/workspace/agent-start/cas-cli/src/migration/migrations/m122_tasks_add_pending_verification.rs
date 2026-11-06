//! Migration: tasks_add_pending_verification

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 122,
    name: "tasks_add_pending_verification",
    subsystem: Subsystem::Tasks,
    description: "Add pending_verification column to tasks for verification jail enforcement",
    up: &["ALTER TABLE tasks ADD COLUMN pending_verification INTEGER NOT NULL DEFAULT 0"],
    detect: Some(
        "SELECT COUNT(*) FROM pragma_table_info('tasks') WHERE name = 'pending_verification'",
    ),
};
