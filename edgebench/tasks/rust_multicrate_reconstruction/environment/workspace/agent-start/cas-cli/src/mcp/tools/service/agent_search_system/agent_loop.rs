use crate::mcp::tools::service::imports::*;

impl CasService {
    pub(in crate::mcp::tools::service) async fn agent_register(
        &self,
        req: AgentRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    pub(in crate::mcp::tools::service) async fn agent_unregister(
        &self,
        req: AgentRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    pub(in crate::mcp::tools::service) async fn agent_whoami(
        &self,
        req: AgentRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    pub(in crate::mcp::tools::service) async fn agent_heartbeat(
        &self,
        req: AgentRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    pub(in crate::mcp::tools::service) async fn agent_list(
        &self,
        req: AgentRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    pub(in crate::mcp::tools::service) async fn agent_cleanup(
        &self,
        req: AgentRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    pub(in crate::mcp::tools::service) async fn agent_session_start(
        &self,
        req: AgentRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    pub(in crate::mcp::tools::service) async fn agent_session_end(
        &self,
        req: AgentRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    pub(in crate::mcp::tools::service) async fn loop_start(
        &self,
        req: AgentRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    pub(in crate::mcp::tools::service) async fn loop_cancel(
        &self,
        req: AgentRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    pub(in crate::mcp::tools::service) async fn loop_status(
        &self,
        req: AgentRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    pub(in crate::mcp::tools::service) async fn lease_history(
        &self,
        req: AgentRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }
}
