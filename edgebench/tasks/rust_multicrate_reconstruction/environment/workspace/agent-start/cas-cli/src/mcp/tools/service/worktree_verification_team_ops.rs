use crate::mcp::tools::service::imports::*;

impl CasService {
    pub(super) async fn worktree_create(
        &self,
        req: WorktreeRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    pub(super) async fn worktree_list(
        &self,
        req: WorktreeRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    pub(super) async fn worktree_show(
        &self,
        req: WorktreeRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    pub(super) async fn worktree_cleanup(
        &self,
        req: WorktreeRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    pub(super) async fn worktree_merge(
        &self,
        req: WorktreeRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    pub(super) async fn worktree_status(
        &self,
        _req: WorktreeRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    // Verification implementations
    pub(super) async fn verification_add(
        &self,
        req: VerificationRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    pub(super) async fn verification_show(
        &self,
        req: VerificationRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    pub(super) async fn verification_list(
        &self,
        req: VerificationRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    pub(super) async fn verification_latest(
        &self,
        req: VerificationRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    // Team implementations
    pub(super) async fn team_list(&self, _req: TeamRequest) -> Result<CallToolResult, McpError> { todo!() }

    pub(super) async fn team_show(&self, req: TeamRequest) -> Result<CallToolResult, McpError> { todo!() }

    pub(super) async fn team_members(&self, req: TeamRequest) -> Result<CallToolResult, McpError> { todo!() }

    pub(super) async fn team_sync(&self, req: TeamRequest) -> Result<CallToolResult, McpError> { todo!() }
}
