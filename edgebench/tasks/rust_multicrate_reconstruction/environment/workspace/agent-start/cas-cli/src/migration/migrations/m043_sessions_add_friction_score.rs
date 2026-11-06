//! Migration: sessions_add_friction_score

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 43,
    name: "sessions_add_friction_score",
    subsystem: Subsystem::Entries,
    description: "Add friction_score column to sessions table for tracking session friction",
    up: &["ALTER TABLE sessions ADD COLUMN friction_score REAL"],
    detect: Some(
        "SELECT COUNT(*) FROM pragma_table_info('sessions') WHERE name = 'friction_score'",
    ),
};
