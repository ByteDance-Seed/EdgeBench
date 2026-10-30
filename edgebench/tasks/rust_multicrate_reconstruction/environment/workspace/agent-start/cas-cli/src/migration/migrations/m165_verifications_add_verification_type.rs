//! Migration: Add verification_type column to verifications table
//!
//! This column distinguishes between task-level verification (individual subtask)
//! and epic-level verification (merged code on master).

use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 165,
    name: "verifications_add_verification_type",
    subsystem: Subsystem::Verification,
    description: "Add verification_type column to verifications for epic vs task verification",
    up: &["ALTER TABLE verifications ADD COLUMN verification_type TEXT NOT NULL DEFAULT 'task'"],
    detect: Some(
        // Return 1 (already applied) if the table doesn't exist (base schema will create it
        // with the column) OR if the column already exists
        "SELECT CASE WHEN (SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='verifications') = 0 THEN 1 ELSE (SELECT COUNT(*) FROM pragma_table_info('verifications') WHERE name = 'verification_type') END",
    ),
};
