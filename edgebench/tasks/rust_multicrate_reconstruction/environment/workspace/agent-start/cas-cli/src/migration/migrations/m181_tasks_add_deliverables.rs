//! Migration: tasks_add_deliverables

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 181,
    name: "tasks_add_deliverables",
    subsystem: Subsystem::Tasks,
    description: "Add deliverables JSON column to tasks",
    up: &["ALTER TABLE tasks ADD COLUMN deliverables TEXT NOT NULL DEFAULT '{}'"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('tasks') WHERE name = 'deliverables'"),
};
