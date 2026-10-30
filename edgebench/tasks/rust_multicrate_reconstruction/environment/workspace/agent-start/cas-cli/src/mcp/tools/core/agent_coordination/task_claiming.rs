use crate::harness_policy::is_worker_without_subagents_from_env;
use crate::mcp::tools::core::imports::*;

impl CasCore {
    pub async fn cas_task_claim(
        &self,
        Parameters(req): Parameters<TaskClaimRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// Release a claimed task
    pub async fn cas_task_release(
        &self,
        Parameters(req): Parameters<TaskReleaseRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// List tasks available for claiming
    pub async fn cas_tasks_available(
        &self,
        Parameters(req): Parameters<LimitRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// Transfer a task to another agent
    pub async fn cas_task_transfer(
        &self,
        Parameters(req): Parameters<TaskTransferRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// List tasks claimed by this agent
    pub async fn cas_tasks_mine(
        &self,
        Parameters(req): Parameters<LimitRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }
}
