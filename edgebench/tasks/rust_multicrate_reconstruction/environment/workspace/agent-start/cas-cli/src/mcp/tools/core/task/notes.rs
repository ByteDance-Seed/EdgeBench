use crate::mcp::tools::core::imports::*;

impl CasCore {
    pub async fn cas_task_notes(
        &self,
        Parameters(req): Parameters<TaskNotesRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }
}
