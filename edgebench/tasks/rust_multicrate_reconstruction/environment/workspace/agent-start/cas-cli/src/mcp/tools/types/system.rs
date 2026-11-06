use rmcp::schemars::JsonSchema;
use serde::Deserialize;

use crate::mcp::tools::types::defaults::{default_observation_type, default_scope_project};

#[derive(Debug, Deserialize, JsonSchema)]
pub struct ObserveRequest {
    /// Observation content
    #[schemars(description = "Content of the observation")]
    pub content: String,

    /// Observation type
    #[schemars(
        description = "Type: 'general' (default), 'decision', 'bugfix', 'feature', 'refactor', 'discovery'"
    )]
    #[serde(default = "default_observation_type")]
    pub observation_type: String,

    /// Source tool
    #[schemars(description = "Tool that made the observation (e.g., 'Write', 'Edit', 'Bash')")]
    #[serde(default)]
    pub source_tool: Option<String>,

    /// Tags
    #[schemars(description = "Comma-separated tags for categorization")]
    #[serde(default)]
    pub tags: Option<String>,

    /// Storage scope
    #[schemars(description = "Scope: 'global' or 'project' (default)")]
    #[serde(default = "default_scope_project")]
    pub scope: String,
}

#[derive(Debug, Deserialize, JsonSchema)]
pub struct ReindexRequest {
    /// Rebuild BM25 index
    #[schemars(description = "Rebuild the BM25 full-text search index")]
    #[serde(default)]
    pub bm25: bool,

    /// Regenerate embeddings (deprecated - semantic search via cloud only)
    #[schemars(
        description = "Deprecated: embeddings are now cloud-only. This parameter is ignored."
    )]
    #[serde(default)]
    pub embeddings: bool,

    /// Only missing embeddings (deprecated)
    #[schemars(
        description = "Deprecated: embeddings are now cloud-only. This parameter is ignored."
    )]
    #[serde(default)]
    pub missing_only: bool,
}

#[derive(Debug, Deserialize, JsonSchema)]
pub struct MaintenanceRunRequest {
    /// Force run even if not idle
    #[schemars(description = "Force maintenance run even if not idle (default: false)")]
    #[serde(default)]
    pub force: bool,
}

// ============================================================================
// Opinion Reinforcement Request Types
// ============================================================================

#[derive(Debug, Deserialize, JsonSchema)]
pub struct OpinionReinforceRequest {
    /// Opinion entry ID
    #[schemars(description = "ID of the opinion/hypothesis entry to reinforce")]
    pub id: String,

    /// Evidence content
    #[schemars(description = "Supporting evidence text that reinforces this opinion")]
    pub evidence: String,
}

#[derive(Debug, Deserialize, JsonSchema)]
pub struct OpinionWeakenRequest {
    /// Opinion entry ID
    #[schemars(description = "ID of the opinion/hypothesis entry to weaken")]
    pub id: String,

    /// Evidence content
    #[schemars(description = "Contradicting evidence text that weakens this opinion")]
    pub evidence: String,
}

#[derive(Debug, Deserialize, JsonSchema)]
pub struct OpinionContradictRequest {
    /// Opinion entry ID
    #[schemars(description = "ID of the opinion/hypothesis entry to strongly contradict")]
    pub id: String,

    /// Evidence content
    #[schemars(description = "Strong contradicting evidence text")]
    pub evidence: String,
}
