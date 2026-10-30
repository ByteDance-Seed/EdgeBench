//! Hook-related message types.

use serde::{Deserialize, Serialize};
use serde_json::Value;

/// Control request message from CLI.
///
/// The CLI sends control requests for various operations including
/// hook callbacks, permission requests, and MCP messages.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ControlRequestMessage {
    /// Request ID for correlation
    pub request_id: String,

    /// Request payload
    pub request: ControlRequest,
}

/// Control request payload variants.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "subtype", rename_all = "snake_case")]
pub enum ControlRequest {
    /// Hook callback request
    HookCallback {
        callback_id: String,
        input: HookCallbackInput,
        tool_use_id: Option<String>,
    },

    /// Permission request (canUseTool)
    CanUseTool {
        tool_name: String,
        input: Value,
        permission_suggestions: Option<Vec<PermissionSuggestion>>,
        blocked_path: Option<String>,
        decision_reason: Option<String>,
        tool_use_id: String,
        agent_id: Option<String>,
    },

    /// MCP message
    McpMessage { server_name: String, message: Value },

    /// Other/unknown request types
    #[serde(other)]
    Unknown,
}

/// Hook callback input data.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HookCallbackInput {
    /// Session ID
    pub session_id: Option<String>,

    /// Transcript file path
    pub transcript_path: Option<String>,

    /// Current working directory
    pub cwd: Option<String>,

    /// Permission mode
    pub permission_mode: Option<String>,

    /// Hook event name
    pub hook_event_name: String,

    /// Tool name (for tool-related hooks)
    pub tool_name: Option<String>,

    /// Tool input (for PreToolUse/PostToolUse)
    pub tool_input: Option<Value>,

    /// Tool response (for PostToolUse)
    pub tool_response: Option<Value>,

    /// Tool use ID
    pub tool_use_id: Option<String>,

    /// User prompt (for UserPromptSubmit)
    pub prompt: Option<String>,

    /// Session start source (for SessionStart)
    pub source: Option<String>,

    /// Session end reason (for SessionEnd)
    pub reason: Option<String>,

    /// Stop hook active flag
    pub stop_hook_active: Option<bool>,
}

impl ControlRequestMessage {
    /// Check if this is a hook callback request.
    pub fn is_hook_callback(&self) -> bool {
        matches!(self.request, ControlRequest::HookCallback { .. })
    }

    /// Get the hook callback ID if this is a hook callback request.
    pub fn callback_id(&self) -> Option<&str> {
        match &self.request {
            ControlRequest::HookCallback { callback_id, .. } => Some(callback_id),
            _ => None,
        }
    }

    /// Get the hook input if this is a hook callback request.
    pub fn hook_input(&self) -> Option<&HookCallbackInput> {
        match &self.request {
            ControlRequest::HookCallback { input, .. } => Some(input),
            _ => None,
        }
    }
}

/// Hook input message (legacy format, kept for compatibility).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HookInputMessage {
    /// Hook event type
    pub event: Option<String>,

    /// Hook input data
    pub input: Option<Value>,

    /// Hook identifier for response correlation
    pub hook_id: Option<String>,

    /// Unique message identifier
    pub uuid: Option<String>,

    /// Session identifier
    pub session_id: Option<String>,
}

impl HookInputMessage {
    /// Get the event type.
    pub fn event_type(&self) -> Option<&str> {
        self.event.as_deref()
    }

    /// Get the tool name from the input data (if present).
    pub fn tool_name(&self) -> Option<&str> {
        self.input
            .as_ref()
            .and_then(|v| v.get("tool_name"))
            .and_then(|v| v.as_str())
    }

    /// Get input as a specific type.
    pub fn input_as<T: for<'de> Deserialize<'de>>(&self) -> Option<T> {
        self.input
            .as_ref()
            .and_then(|v| serde_json::from_value(v.clone()).ok())
    }
}

/// Hook response message.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HookResponseMessage {
    /// Unique message identifier
    pub uuid: Option<String>,

    /// Session identifier
    pub session_id: Option<String>,

    /// Hook name
    pub hook_name: Option<String>,

    /// Hook event type
    pub hook_event: Option<String>,

    /// Stdout from hook execution
    pub stdout: Option<String>,

    /// Stderr from hook execution
    pub stderr: Option<String>,

    /// Exit code from hook execution
    pub exit_code: Option<i32>,
}

/// Control response message (for runtime queries).
/// Format: {"type": "control_response", "response": {...}}
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ControlResponseMessage {
    /// The response data
    pub response: ControlResponseData,
}

/// Inner response data for control responses.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ControlResponseData {
    /// Request ID for correlation
    pub request_id: Option<String>,

    /// Response subtype (success/error)
    pub subtype: Option<String>,

    /// Response payload data
    pub response: Option<Value>,

    /// Error information
    pub error: Option<String>,
}

impl ControlResponseMessage {
    /// Check if this is a successful response.
    pub fn is_success(&self) -> bool {
        self.response.subtype.as_deref() == Some("success")
    }

    /// Get the request ID.
    pub fn request_id(&self) -> Option<&str> {
        self.response.request_id.as_deref()
    }

    /// Get response data as a specific type.
    pub fn data_as<T: for<'de> Deserialize<'de>>(&self) -> Option<T> {
        self.response
            .response
            .as_ref()
            .and_then(|v| serde_json::from_value(v.clone()).ok())
    }
}

/// Pre-tool-use hook input.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PreToolUseInput {
    pub tool_name: String,
    pub tool_input: Value,
    pub tool_use_id: String,
    pub session_id: Option<String>,
    pub transcript_path: Option<String>,
    pub cwd: Option<String>,
    pub permission_mode: Option<String>,
}

/// Post-tool-use hook input.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PostToolUseInput {
    pub tool_name: String,
    pub tool_input: Value,
    pub tool_response: Value,
    pub tool_use_id: String,
    pub session_id: Option<String>,
    pub transcript_path: Option<String>,
    pub cwd: Option<String>,
    pub permission_mode: Option<String>,
}

/// Permission request hook input.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PermissionRequestInput {
    pub tool_name: String,
    pub tool_input: Value,
    pub permission_suggestions: Option<Vec<PermissionSuggestion>>,
    pub session_id: Option<String>,
    pub transcript_path: Option<String>,
    pub cwd: Option<String>,
    pub permission_mode: Option<String>,
}

/// Permission suggestion from the CLI.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PermissionSuggestion {
    pub suggestion_type: Option<String>,
    pub message: Option<String>,
}

/// Session start hook input.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SessionStartInput {
    pub source: Option<String>, // startup, resume, clear, compact
    pub session_id: Option<String>,
    pub transcript_path: Option<String>,
    pub cwd: Option<String>,
    pub permission_mode: Option<String>,
}

/// Session end hook input.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SessionEndInput {
    pub reason: Option<String>, // clear, logout, prompt_input_exit, other
    pub session_id: Option<String>,
    pub transcript_path: Option<String>,
    pub cwd: Option<String>,
    pub permission_mode: Option<String>,
}
