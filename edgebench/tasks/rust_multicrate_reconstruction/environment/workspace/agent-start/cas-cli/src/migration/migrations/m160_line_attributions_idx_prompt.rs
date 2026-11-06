//! Migration: Add index on prompt_id for line_attributions table
use crate::migration::{Migration, Subsystem};

pub const MIGRATION: Migration = Migration {
    id: 160,
    name: "line_attributions_idx_prompt",
    subsystem: Subsystem::Code,
    description: "Add index on prompt_id for efficient prompt-based lookups",
    up: &["CREATE INDEX IF NOT EXISTS idx_line_attr_prompt ON line_attributions(prompt_id)"],
    detect: Some(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_line_attr_prompt'",
    ),
};
