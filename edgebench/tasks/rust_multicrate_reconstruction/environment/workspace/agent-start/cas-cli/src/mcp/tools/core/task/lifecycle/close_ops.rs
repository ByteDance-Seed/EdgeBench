use crate::harness_policy::{
    is_supervisor_from_env, is_worker_without_subagents_from_env, supervisor_harness_from_env,
    verification_policy, worker_harness_from_env,
};
use crate::mcp::tools::core::imports::*;

impl CasCore {
    pub async fn cas_task_close(
        &self,
        Parameters(req): Parameters<TaskCloseRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// Reopen a closed task
    pub async fn cas_task_reopen(
        &self,
        Parameters(req): Parameters<IdRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }
}
