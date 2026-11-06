use crate::harness_policy::is_worker_without_subagents_from_env;
use crate::mcp::tools::core::imports::*;

mod close_ops;

impl CasCore {
    pub async fn cas_task_create(
        &self,
        Parameters(req): Parameters<TaskCreateRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// List ready tasks
    pub async fn cas_task_ready(
        &self,
        Parameters(req): Parameters<TaskReadyBlockedRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// Start a task
    pub async fn cas_task_start(
        &self,
        Parameters(req): Parameters<IdRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }
}
