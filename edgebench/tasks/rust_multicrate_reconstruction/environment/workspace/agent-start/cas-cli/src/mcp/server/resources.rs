use std::borrow::Cow;

use rmcp::ErrorData as McpError;
use rmcp::model::{AnnotateAble, ErrorCode, RawResource, Resource};

use crate::mcp::server::CasCore;
use crate::types::{RuleStatus, SkillStatus, TaskStatus};

impl CasCore {
    /// Build list of available resources
    pub(crate) fn build_resources(&self) -> Vec<Resource> { todo!() }

    /// Read a specific resource
    pub(crate) fn read_resource_content(&self, uri: &str) -> Result<String, McpError> { todo!() }
}
