//! Migration: Add model column to prompts for tracking which Claude model wrote code
use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 155,
    name: "prompts_add_model",
    subsystem: Subsystem::Code,
    description: "Add model column to track which Claude model generated the code",
    up: &["ALTER TABLE prompts ADD COLUMN model TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('prompts') WHERE name = 'model'"),
};
