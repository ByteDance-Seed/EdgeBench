use crate::mcp::tools::service::imports::*;

impl CasService {
    pub(crate) async fn spec_supersede(
        &self,
        req: SpecRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    pub(crate) async fn spec_link(&self, req: SpecRequest) -> Result<CallToolResult, McpError> { todo!() }

    pub(crate) async fn spec_unlink(&self, req: SpecRequest) -> Result<CallToolResult, McpError> { todo!() }

    pub(crate) async fn spec_sync(&self, _req: SpecRequest) -> Result<CallToolResult, McpError> { todo!() }

    pub(crate) async fn spec_get_for_task(
        &self,
        req: SpecRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// Parse comma-separated string or JSON array into Vec<String>.
    /// Handles both `"Goal 1, Goal 2"` and `'["Goal 1", "Goal 2"]'` formats.
    pub(super) fn parse_comma_list(opt: &Option<String>) -> Vec<String> { todo!() }
}
