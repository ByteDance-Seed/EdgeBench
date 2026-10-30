use rmcp::schemars::JsonSchema;
use serde::Deserialize;

use crate::mcp::tools::types::defaults::{
    default_entry_type, default_importance, default_recent, default_scope_project,
};

#[derive(Debug, Deserialize, JsonSchema)]
pub struct RememberRequest {
    /// The content to remember
    #[schemars(
        description = "The content to remember. Can be a fact, preference, context, or observation."
    )]
    pub content: String,

    /// Entry type
    #[schemars(
        description = "Type of memory: 'learning' (default), 'preference', 'context', or 'observation'"
    )]
    #[serde(default = "default_entry_type")]
    pub entry_type: String,

    /// Optional tags for categorization
    #[schemars(
        description = "Comma-separated tags for categorization (e.g., 'rust,cli,important')"
    )]
    #[serde(default)]
    pub tags: Option<String>,

    /// Optional title
    #[schemars(description = "Optional short title for the entry")]
    #[serde(default)]
    pub title: Option<String>,

    /// Importance score
    #[schemars(description = "Importance score from 0.0 to 1.0 (default: 0.5)")]
    #[serde(default = "default_importance")]
    pub importance: f32,

    /// Storage scope
    #[schemars(
        description = "Scope: 'global' (user prefs, general learnings) or 'project' (default, project-specific context)"
    )]
    #[serde(default = "default_scope_project")]
    pub scope: String,

    /// Valid from timestamp (RFC3339)
    #[schemars(description = "When this fact becomes valid (RFC3339 format)")]
    #[serde(default)]
    pub valid_from: Option<String>,

    /// Valid until timestamp (RFC3339)
    #[schemars(description = "When this fact expires (RFC3339 format)")]
    #[serde(default)]
    pub valid_until: Option<String>,

    /// Team ID for team-scoped entries
    #[schemars(description = "Team ID to share this entry with a team")]
    #[serde(default)]
    pub team_id: Option<String>,
}

#[derive(Debug, Deserialize, JsonSchema)]
pub struct RecentRequest {
    /// Number of entries
    #[schemars(description = "Number of recent entries to return (default: 10)")]
    #[serde(default = "default_recent")]
    pub n: usize,
}

#[derive(Debug, Deserialize, JsonSchema)]
pub struct MemoryTierRequest {
    /// Entry ID
    #[schemars(description = "ID of the entry")]
    pub id: String,

    /// Memory tier
    #[schemars(description = "Memory tier: 'working', 'cold', or 'archive'")]
    pub tier: String,
}
