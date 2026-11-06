//! Migration: Add messages_json column to prompts for full conversation capture
use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 154,
    name: "prompts_add_messages_json",
    subsystem: Subsystem::Code,
    description: "Add messages_json column to capture full conversation transcript",
    up: &["ALTER TABLE prompts ADD COLUMN messages_json TEXT"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('prompts') WHERE name = 'messages_json'"),
};
