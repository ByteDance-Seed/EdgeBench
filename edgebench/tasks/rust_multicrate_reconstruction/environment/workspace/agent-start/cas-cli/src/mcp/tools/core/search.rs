use crate::mcp::tools::core::imports::*;

impl CasCore {
    // ========================================================================
    // Search Tools (1) - Use doc_type param for filtering
    // ========================================================================

    /// Unified search
    pub async fn cas_search(
        &self,
        Parameters(req): Parameters<SearchRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }
}
