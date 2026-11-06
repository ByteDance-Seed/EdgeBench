use crate::mcp::tools::service::imports::*;

impl CasService {
    fn format_agent_message(message: &str, _from: &str, respond_to: &str) -> String { todo!() }

    pub(in crate::mcp::tools::service) async fn message_send(
        &self,
        req: AgentRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }
}
