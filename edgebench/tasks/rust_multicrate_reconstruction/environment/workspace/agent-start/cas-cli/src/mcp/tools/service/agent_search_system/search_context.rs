use crate::mcp::tools::service::imports::*;

impl CasService {
    pub(in crate::mcp::tools::service) async fn search_impl(
        &self,
        req: SearchContextRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    pub(in crate::mcp::tools::service) async fn context_impl(
        &self,
        req: SearchContextRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    pub(in crate::mcp::tools::service) async fn context_for_subagent_impl(
        &self,
        req: SearchContextRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    pub(in crate::mcp::tools::service) async fn observe_impl(
        &self,
        req: SearchContextRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    pub(in crate::mcp::tools::service) async fn entity_list_impl(
        &self,
        req: SearchContextRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    pub(in crate::mcp::tools::service) async fn entity_show_impl(
        &self,
        req: SearchContextRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }

    pub(in crate::mcp::tools::service) async fn entity_extract_impl(
        &self,
        req: SearchContextRequest,
    ) -> Result<CallToolResult, McpError> { todo!() }
}
