//! Migration: tasks_add_demo_statement

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 182,
    name: "tasks_add_demo_statement",
    subsystem: Subsystem::Tasks,
    description: "Add demo_statement column to tasks for vertical slice enforcement",
    up: &["ALTER TABLE tasks ADD COLUMN demo_statement TEXT NOT NULL DEFAULT ''"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('tasks') WHERE name = 'demo_statement'"),
};
