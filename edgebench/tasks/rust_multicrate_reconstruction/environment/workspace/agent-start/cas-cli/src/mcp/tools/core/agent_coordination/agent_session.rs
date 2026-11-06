use crate::mcp::tools::core::imports::*;

impl CasCore {
    pub async fn cas_agent_register(
        &self,
        Parameters(req): Parameters<AgentRegisterRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// Start a session without Claude hooks (Codex-friendly)
    pub async fn cas_agent_session_start(
        &self,
        Parameters(req): Parameters<SessionStartRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// End a session without Claude hooks (Codex-friendly)
    pub async fn cas_agent_session_end(
        &self,
        Parameters(req): Parameters<SessionEndRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }
}
