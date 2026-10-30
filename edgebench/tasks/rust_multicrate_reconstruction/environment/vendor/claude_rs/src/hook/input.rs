//! Hook input types.

use serde::{Deserialize, Serialize};
use serde_json::Value;

/// Input data for a hook.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HookInput {
    /// Hook event type
    pub event: String,

    /// Hook ID for response correlation
    pub hook_id: String,

    /// Session ID
    pub session_id: Option<String>,

    /// Transcript path
    pub transcript_path: Option<String>,

    /// Current working directory
    pub cwd: Option<String>,

    /// Permission mode
    pub permission_mode: Option<String>,

    /// Event-specific data
    #[serde(flatten)]
    pub data: HookInputData,
}

/// Event-specific hook input data.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(untagged)]
pub enum HookInputData {
    /// Pre-tool-use data
    PreToolUse {
        tool_name: String,
        tool_input: Value,
        tool_use_id: String,
    },

    /// Post-tool-use data
    PostToolUse {
        tool_name: String,
        tool_input: Value,
        tool_response: Value,
        tool_use_id: String,
    },

    /// Post-tool-use-failure data
    PostToolUseFailure {
        tool_name: String,
        tool_input: Value,
        tool_use_id: String,
        error: Option<String>,
        is_interrupt: Option<bool>,
    },

    /// Permission request data
    PermissionRequest {
        tool_name: String,
        tool_input: Value,
        permission_suggestions: Option<Vec<PermissionSuggestion>>,
    },

    /// Notification data
    Notification {
        message: String,
        title: Option<String>,
    },

    /// Session start data
    SessionStart { source: Option<String> },

    /// Session end data
    SessionEnd { reason: Option<String> },

    /// Subagent start data
    SubagentStart {
        agent_id: String,
        agent_type: Option<String>,
    },

    /// Subagent stop data
    SubagentStop {
        agent_id: String,
        agent_transcript_path: Option<String>,
        stop_hook_active: Option<bool>,
    },

    /// Pre-compact data
    PreCompact {
        trigger: Option<String>,
        custom_instructions: Option<String>,
    },

    /// Generic/empty data
    Empty {},
}

/// Permission suggestion from the CLI.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PermissionSuggestion {
    pub suggestion_type: Option<String>,
    pub message: Option<String>,
}

impl HookInput {
    /// Get the tool name if this is a tool-related event.
    pub fn tool_name(&self) -> Option<&str> {
        match &self.data {
            HookInputData::PreToolUse { tool_name, .. } => Some(tool_name),
            HookInputData::PostToolUse { tool_name, .. } => Some(tool_name),
            HookInputData::PostToolUseFailure { tool_name, .. } => Some(tool_name),
            HookInputData::PermissionRequest { tool_name, .. } => Some(tool_name),
            _ => None,
        }
    }

    /// Get the tool input if this is a tool-related event.
    pub fn tool_input(&self) -> Option<&Value> {
        match &self.data {
            HookInputData::PreToolUse { tool_input, .. } => Some(tool_input),
            HookInputData::PostToolUse { tool_input, .. } => Some(tool_input),
            HookInputData::PostToolUseFailure { tool_input, .. } => Some(tool_input),
            HookInputData::PermissionRequest { tool_input, .. } => Some(tool_input),
            _ => None,
        }
    }
}
