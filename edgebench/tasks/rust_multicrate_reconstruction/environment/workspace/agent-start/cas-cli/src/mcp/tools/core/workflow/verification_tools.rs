use crate::harness_policy::worker_harness_from_env;
use crate::mcp::tools::core::imports::*;

impl CasCore {
    pub async fn cas_verification_add(
        &self,
        Parameters(req): Parameters<VerificationAddRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// Show verification details
    pub async fn cas_verification_show(
        &self,
        Parameters(req): Parameters<VerificationShowRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// List verifications for a task
    pub async fn cas_verification_list(
        &self,
        Parameters(req): Parameters<VerificationListRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// Get latest verification for a task
    pub async fn cas_verification_latest(
        &self,
        Parameters(req): Parameters<VerificationListRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    // ========================================================================
    // Worktree Operations
    // ========================================================================
}
