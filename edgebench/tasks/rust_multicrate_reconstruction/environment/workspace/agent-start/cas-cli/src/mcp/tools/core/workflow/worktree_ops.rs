use crate::mcp::tools::core::imports::*;

impl CasCore {
    pub async fn worktree_create(&self, epic_id: &str) -> Result<CallToolResult, McpError> { todo!() }

    /// List worktrees
    pub async fn worktree_list(
        &self,
        all: bool,
        status_filter: Option<&str>,
        orphans_only: bool,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// Show worktree details
    pub async fn worktree_show(&self, id: &str) -> Result<CallToolResult, McpError> { todo!() }

    /// Cleanup orphaned worktrees
    pub async fn worktree_cleanup(
        &self,
        dry_run: bool,
        force: bool,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// Merge worktree back to parent
    pub async fn worktree_merge(&self, id: &str, force: bool) -> Result<CallToolResult, McpError> { todo!() }

    /// Get current worktree status
    pub async fn worktree_status(&self) -> Result<CallToolResult, McpError> { todo!() }
}
