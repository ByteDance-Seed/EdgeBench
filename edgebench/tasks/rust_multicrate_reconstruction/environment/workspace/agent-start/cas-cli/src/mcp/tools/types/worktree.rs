use rmcp::schemars::JsonSchema;
use serde::Deserialize;

use crate::mcp::tools::types::defaults::default_true;

#[derive(Debug, Deserialize, JsonSchema)]
pub struct WorktreeCreateRequest {
    /// Task ID to create worktree for
    #[schemars(description = "ID of the task to create a worktree for")]
    pub task_id: String,
}

#[derive(Debug, Deserialize, JsonSchema)]
pub struct WorktreeListRequest {
    /// Show all worktrees (including removed/merged)
    #[schemars(description = "Show all worktrees including removed/merged (default: false)")]
    #[serde(default)]
    pub all: bool,

    /// Filter by status
    #[schemars(
        description = "Filter by status: 'active', 'merged', 'abandoned', 'conflict', 'removed'"
    )]
    #[serde(default)]
    pub status: Option<String>,

    /// Show orphaned worktrees only
    #[schemars(description = "Show only orphaned worktrees (default: false)")]
    #[serde(default)]
    pub orphans: bool,
}

#[derive(Debug, Deserialize, JsonSchema)]
pub struct WorktreeShowRequest {
    /// Worktree ID or branch name
    #[schemars(description = "Worktree ID or branch name to show")]
    pub id: String,
}

#[derive(Debug, Deserialize, JsonSchema)]
pub struct WorktreeCleanupRequest {
    /// Dry run - show what would be cleaned without doing it
    #[schemars(description = "Preview cleanup without making changes (default: false)")]
    #[serde(default)]
    pub dry_run: bool,

    /// Force cleanup even with uncommitted changes
    #[schemars(
        description = "Force cleanup even if there are uncommitted changes (default: false)"
    )]
    #[serde(default)]
    pub force: bool,

    /// Only cleanup orphaned worktrees
    #[schemars(description = "Only cleanup orphaned worktrees (default: true)")]
    #[serde(default = "default_true")]
    pub orphans_only: bool,
}

#[derive(Debug, Deserialize, JsonSchema)]
pub struct WorktreeMergeRequest {
    /// Worktree ID to merge
    #[schemars(description = "ID of the worktree to merge back to parent branch")]
    pub id: String,

    /// Force merge even with uncommitted changes
    #[schemars(description = "Force merge even if there are uncommitted changes (default: false)")]
    #[serde(default)]
    pub force: bool,
}
