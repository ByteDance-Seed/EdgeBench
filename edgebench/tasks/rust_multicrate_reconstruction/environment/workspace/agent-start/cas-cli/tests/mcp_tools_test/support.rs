use tempfile::TempDir;

use cas::mcp::CasCore;
use cas::store::{
    open_agent_store, open_rule_store, open_skill_store, open_store, open_task_store,
};
use cas::types::Agent;

/// Helper to create an initialized CAS environment.
pub(crate) fn setup_cas() -> (TempDir, CasCore) { todo!() }

/// Extract text from a tool result.
pub(crate) fn extract_text(result: rmcp::model::CallToolResult) -> String { todo!() }

/// Extract entry ID from "Created entry: {id} - {preview}" format.
pub(crate) fn extract_entry_id(text: &str) -> Option<&str> { todo!() }

/// Extract task ID from "Created task: {id} - {title}" output.
pub(crate) fn extract_task_id(text: &str) -> Option<&str> { todo!() }

/// Extract rule ID from output.
pub(crate) fn extract_rule_id(text: &str) -> Option<String> { todo!() }

/// Extract skill ID from output.
pub(crate) fn extract_skill_id(text: &str) -> Option<String> { todo!() }
