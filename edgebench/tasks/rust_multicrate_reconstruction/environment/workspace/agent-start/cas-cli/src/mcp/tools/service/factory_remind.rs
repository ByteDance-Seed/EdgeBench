use crate::mcp::tools::service::imports::*;

impl CasService {
    /// Resolve the `target` parameter to an agent ID.
    /// If `target` is a name (e.g. "swift-fox"), look it up in the agent store.
    /// If `target` is already a UUID, return it directly.
    /// Returns `(agent_id, display_name)`.
    fn resolve_reminder_target(
        &self,
        target: &str,
    ) -> std::result::Result<(String, String), McpError> { todo!() }

    /// Create a time-based or event-based reminder
    pub(super) async fn factory_remind(
        &self,
        req: FactoryRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// List pending reminders relevant to the calling agent.
    /// Shows reminders the agent owns AND reminders targeting this agent.
    pub(super) async fn factory_remind_list(
        &self,
        _req: FactoryRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// Cancel a pending reminder
    pub(super) async fn factory_remind_cancel(
        &self,
        req: FactoryRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }
}
