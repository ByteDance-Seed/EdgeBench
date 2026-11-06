use crate::mcp::tools::core::imports::*;

impl CasCore {
    pub async fn cas_task_dep_add(
        &self,
        Parameters(req): Parameters<DependencyRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// Remove a dependency between tasks
    pub async fn cas_task_dep_remove(
        &self,
        Parameters(req): Parameters<DependencyRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }
}
