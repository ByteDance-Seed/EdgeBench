//! Migration: task_leases_add_epoch

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 91,
    name: "task_leases_add_epoch",
    subsystem: Subsystem::Agents,
    description: "Add epoch column for fencing stale leases",
    up: &["ALTER TABLE task_leases ADD COLUMN epoch INTEGER NOT NULL DEFAULT 1"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('task_leases') WHERE name = 'epoch'"),
};
