use rmcp::schemars::JsonSchema;
use serde::Deserialize;

use crate::mcp::tools::types::defaults::{default_scope_all, default_search_limit};

#[derive(Debug, Deserialize, JsonSchema)]
pub struct SearchRequest {
    /// Search query
    #[schemars(description = "Search query to find relevant content")]
    pub query: String,

    /// Maximum results
    #[schemars(description = "Maximum results to return (default: 10)")]
    #[serde(default = "default_search_limit")]
    pub limit: usize,

    /// Document type filter
    #[schemars(
        description = "Filter by type: 'entry', 'task', 'rule', 'skill', or 'all' (default)"
    )]
    #[serde(default)]
    pub doc_type: Option<String>,

    /// Scope filter
    #[schemars(description = "Filter by scope: 'global', 'project', or 'all' (default)")]
    #[serde(default = "default_scope_all")]
    pub scope: String,

    /// Tags filter (comma-separated)
    #[schemars(description = "Filter results to entries with these tags (comma-separated)")]
    #[serde(default)]
    pub tags: Option<String>,
}

#[derive(Debug, Deserialize, JsonSchema)]
pub struct EntityListRequest {
    /// Filter by entity type
    #[schemars(
        description = "Filter by entity type: 'person', 'project', 'technology', 'file', 'concept', 'organization', 'domain'"
    )]
    #[serde(default)]
    pub entity_type: Option<String>,

    /// Search query to filter entities by name/description
    #[schemars(
        description = "Filter entities by name or description (case-insensitive substring match)"
    )]
    #[serde(default)]
    pub query: Option<String>,

    /// Tags filter (entities associated with entries having these tags)
    #[schemars(description = "Comma-separated tags to filter entities (via mentions)")]
    #[serde(default)]
    pub tags: Option<String>,

    /// Scope filter (entities from entries in this scope)
    #[schemars(description = "Scope: 'global', 'project', or 'all' (default: 'all')")]
    #[serde(default)]
    pub scope: Option<String>,

    /// Sort field
    #[schemars(
        description = "Sort by: 'name', 'created', 'updated', 'mentions' (default: 'updated')"
    )]
    #[serde(default)]
    pub sort: Option<String>,

    /// Sort order
    #[schemars(description = "Sort order: 'asc' or 'desc' (default: 'desc')")]
    #[serde(default)]
    pub sort_order: Option<String>,

    /// Maximum items to return
    #[schemars(description = "Maximum entities to return (default: 50)")]
    #[serde(default)]
    pub limit: Option<usize>,
}

#[derive(Debug, Deserialize, JsonSchema)]
pub struct EntityExtractRequest {
    /// Search query to filter entries by content
    #[schemars(description = "Filter entries by content (case-insensitive substring match)")]
    #[serde(default)]
    pub query: Option<String>,

    /// Scope filter for entries to process
    #[schemars(description = "Scope: 'global', 'project', or 'all' (default: 'all')")]
    #[serde(default)]
    pub scope: Option<String>,

    /// Tags filter for entries to process
    #[schemars(description = "Comma-separated tags to filter entries")]
    #[serde(default)]
    pub tags: Option<String>,

    /// Entity type to extract
    #[schemars(
        description = "Only extract entities of this type: 'person', 'project', 'technology', etc."
    )]
    #[serde(default)]
    pub entity_type: Option<String>,

    /// Maximum entries to process
    #[schemars(description = "Maximum entries to process for entity extraction (default: 100)")]
    #[serde(default)]
    pub limit: Option<usize>,
}
