use std::collections::HashMap;

use rmcp::ErrorData as McpError;
use rmcp::model::{
    ErrorCode, GetPromptResult, Prompt, PromptArgument, PromptMessage, PromptMessageRole,
};

use crate::mcp::server::CasCore;
use crate::types::{RuleStatus, TaskStatus};

impl CasCore {
    /// Build list of available prompts
    pub(crate) fn build_prompts() -> Vec<Prompt> { todo!() }

    /// Get prompt content
    pub(crate) fn get_prompt_content(
        &self,
        name: &str,
        args: &HashMap<String, String>,
    ) -> Result<GetPromptResult, McpError> { todo!() }
}
