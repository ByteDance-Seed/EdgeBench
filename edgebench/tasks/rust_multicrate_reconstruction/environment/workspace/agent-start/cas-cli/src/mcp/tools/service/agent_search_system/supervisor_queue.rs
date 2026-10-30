use crate::mcp::tools::service::imports::*;

impl CasService {
    pub(in crate::mcp::tools::service) async fn queue_notify(
        &self,
        req: AgentRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    pub(in crate::mcp::tools::service) async fn queue_poll(
        &self,
        req: AgentRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    pub(in crate::mcp::tools::service) async fn queue_peek(
        &self,
        req: AgentRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    pub(in crate::mcp::tools::service) async fn queue_ack(
        &self,
        req: AgentRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }
}
