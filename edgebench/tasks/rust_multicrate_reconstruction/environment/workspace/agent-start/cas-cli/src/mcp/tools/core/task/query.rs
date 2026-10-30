use crate::mcp::tools::core::imports::*;

impl CasCore {
    pub async fn cas_task_show(
        &self,
        Parameters(req): Parameters<TaskShowRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// List blocked tasks
    pub async fn cas_task_blocked(
        &self,
        Parameters(req): Parameters<TaskReadyBlockedRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// Update a task
    pub async fn cas_task_list(
        &self,
        Parameters(req): Parameters<TaskListRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }
}
