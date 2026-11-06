use rmcp::schemars::JsonSchema;
use serde::Deserialize;

use crate::mcp::tools::types::defaults::default_scope_all;

#[derive(Debug, Deserialize, JsonSchema)]
pub struct IdRequest {
    /// Entity ID
    #[schemars(
        description = "ID of the entity (e.g., '2024-01-15-001' for entry, 'cas-a1b2' for task)"
    )]
    pub id: String,
}

#[derive(Debug, Deserialize, JsonSchema)]
pub struct LimitRequest {
    /// Maximum number of items
    #[schemars(description = "Maximum items to return")]
    #[serde(default)]
    pub limit: Option<usize>,

    /// Scope filter
    #[schemars(description = "Filter by scope: 'global', 'project', or 'all' (default)")]
    #[serde(default = "default_scope_all")]
    pub scope: String,

    /// Sort field
    #[schemars(description = "Sort by: 'created', 'updated', 'importance', 'title'")]
    #[serde(default)]
    pub sort: Option<String>,

    /// Sort order
    #[schemars(description = "Sort order: 'asc' or 'desc' (default: desc)")]
    #[serde(default)]
    pub sort_order: Option<String>,

    /// Team ID filter
    #[schemars(description = "Filter to entries shared with a specific team")]
    #[serde(default)]
    pub team_id: Option<String>,
}

/// Request type for task ready/blocked operations with epic filtering
#[derive(Debug, Deserialize, JsonSchema)]
pub struct TaskReadyBlockedRequest {
    /// Maximum number of items
    #[schemars(description = "Maximum items to return")]
    #[serde(default)]
    pub limit: Option<usize>,

    /// Scope filter
    #[schemars(description = "Filter by scope: 'global', 'project', or 'all' (default)")]
    #[serde(default = "default_scope_all")]
    pub scope: String,

    /// Sort field
    #[schemars(description = "Sort by: 'created', 'updated', 'priority', 'title'")]
    #[serde(default)]
    pub sort: Option<String>,

    /// Sort order
    #[schemars(
        description = "Sort order: 'asc' or 'desc' (default: desc for dates, asc for priority)"
    )]
    #[serde(default)]
    pub sort_order: Option<String>,

    /// Epic filter - return only subtasks of the specified epic
    #[schemars(description = "Filter to subtasks of this epic ID")]
    #[serde(default)]
    pub epic: Option<String>,
}

#[derive(Debug, Deserialize, JsonSchema)]
pub struct TaskListRequest {
    /// Maximum number of items
    #[schemars(description = "Maximum items to return")]
    #[serde(default)]
    pub limit: Option<usize>,

    /// Scope filter
    #[schemars(description = "Filter by scope: 'global', 'project', or 'all' (default)")]
    #[serde(default = "default_scope_all")]
    pub scope: String,

    /// Status filter
    #[schemars(description = "Filter by status: 'open', 'in_progress', 'closed', 'blocked'")]
    #[serde(default)]
    pub status: Option<String>,

    /// Task type filter
    #[schemars(
        description = "Filter by task type: 'task', 'bug', 'feature', 'epic', 'chore', 'spike'"
    )]
    #[serde(default)]
    pub task_type: Option<String>,

    /// Label filter
    #[schemars(description = "Filter by label")]
    #[serde(default)]
    pub label: Option<String>,

    /// Assignee filter
    #[schemars(description = "Filter by assignee")]
    #[serde(default)]
    pub assignee: Option<String>,

    /// Epic filter - return only subtasks of the specified epic
    #[schemars(description = "Filter by epic ID - returns only subtasks of this epic")]
    #[serde(default)]
    pub epic: Option<String>,

    /// Sort field
    #[schemars(description = "Sort by: 'created', 'updated', 'priority', 'title'")]
    #[serde(default)]
    pub sort: Option<String>,

    /// Sort order
    #[schemars(
        description = "Sort order: 'asc' or 'desc' (default: desc for dates, asc for priority)"
    )]
    #[serde(default)]
    pub sort_order: Option<String>,
}
