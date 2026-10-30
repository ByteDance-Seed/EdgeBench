use crate::mcp::tools::core::imports::*;

impl CasCore {
    // ========================================================================
    // Additional Task Tools
    // ========================================================================

    /// Delete a task
    pub async fn cas_task_delete(
        &self,
        Parameters(req): Parameters<IdRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// List dependencies for a task (both outgoing and incoming)
    pub async fn cas_task_dep_list(
        &self,
        Parameters(req): Parameters<IdRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }
}
