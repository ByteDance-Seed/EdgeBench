//! Message types from the Claude CLI.
//!
//! The CLI outputs various message types as newline-delimited JSON.
//! This module defines typed structs for each message type.

mod assistant;
mod content;
mod control;
mod hook;
mod partial;
mod result;
mod system;
mod user;

pub use assistant::AssistantMessage;
pub use content::{ContentBlock, ToolUse};
pub use control::{
    AccountInfo, ControlRequestPayload, ControlRequestWrapper, InitializeResponse,
    McpConnectionStatus, McpServerInfo, McpServerStatus, ModelInfo, SlashCommand,
};
pub use hook::{
    ControlRequest,
    ControlRequestMessage,
    ControlResponseMessage,
    HookCallbackInput,
    HookInputMessage,
    HookResponseMessage,
    // Typed hook input structs for specific event handling
    PermissionRequestInput,
    PostToolUseInput,
    PreToolUseInput,
    SessionEndInput,
    SessionStartInput,
};
pub use partial::PartialMessage;
pub use result::ResultMessage;
pub use system::SystemMessage;
pub use user::UserMessage;

use serde::{Deserialize, Serialize};

/// A message from the Claude CLI.
///
/// Messages are streamed as newline-delimited JSON and parsed into
/// this enum based on their `type` field.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum Message {
    /// System/initialization message
    System(SystemMessage),

    /// Assistant response message
    Assistant(AssistantMessage),

    /// User input message (including tool results)
    User(UserMessage),

    /// Final result message
    Result(ResultMessage),

    /// Partial/streaming message
    Partial(PartialMessage),

    /// Tool execution progress
    #[serde(rename = "tool_progress")]
    ToolProgress(ToolProgressMessage),

    /// Status update (e.g., compacting)
    Status(StatusMessage),

    /// Authentication status
    #[serde(rename = "auth_status")]
    AuthStatus(AuthStatusMessage),

    /// Hook input (legacy callback request)
    #[serde(rename = "hook_input")]
    HookInput(HookInputMessage),

    /// Hook response
    #[serde(rename = "hook_response")]
    HookResponse(HookResponseMessage),

    /// Control request (for SDK hooks, permissions, MCP)
    #[serde(rename = "control_request")]
    ControlRequest(ControlRequestMessage),

    /// Control response (for runtime queries)
    #[serde(rename = "control_response")]
    ControlResponse(ControlResponseMessage),

    /// Context compaction boundary
    #[serde(rename = "compact_boundary")]
    CompactBoundary(CompactBoundaryMessage),
}

impl Message {
    /// Get the session ID from any message type.
    pub fn session_id(&self) -> Option<&str> {
        match self {
            Message::System(m) => m.session_id.as_deref(),
            Message::Assistant(m) => m.session_id.as_deref(),
            Message::User(m) => m.session_id.as_deref(),
            Message::Result(m) => m.session_id.as_deref(),
            Message::Partial(m) => m.session_id.as_deref(),
            Message::ToolProgress(m) => m.session_id.as_deref(),
            Message::Status(m) => m.session_id.as_deref(),
            Message::AuthStatus(m) => m.session_id.as_deref(),
            Message::HookInput(m) => m.session_id.as_deref(),
            Message::HookResponse(m) => m.session_id.as_deref(),
            Message::ControlRequest(_) => None,
            Message::ControlResponse(_) => None,
            Message::CompactBoundary(m) => m.session_id.as_deref(),
        }
    }

    /// Get the UUID from any message type.
    pub fn uuid(&self) -> Option<&str> {
        match self {
            Message::System(m) => m.uuid.as_deref(),
            Message::Assistant(m) => m.uuid.as_deref(),
            Message::User(m) => m.uuid.as_deref(),
            Message::Result(m) => m.uuid.as_deref(),
            Message::Partial(m) => m.uuid.as_deref(),
            Message::ToolProgress(m) => m.uuid.as_deref(),
            Message::Status(m) => m.uuid.as_deref(),
            Message::AuthStatus(m) => m.uuid.as_deref(),
            Message::HookInput(m) => m.uuid.as_deref(),
            Message::HookResponse(m) => m.uuid.as_deref(),
            Message::ControlRequest(_) => None,
            Message::ControlResponse(_) => None,
            Message::CompactBoundary(m) => m.uuid.as_deref(),
        }
    }

    /// Check if this is a replay message.
    pub fn is_replay(&self) -> bool {
        match self {
            Message::User(m) => m.is_replay.unwrap_or(false),
            _ => false,
        }
    }

    /// Check if this is an assistant message.
    pub fn is_assistant(&self) -> bool {
        matches!(self, Message::Assistant(_))
    }

    /// Check if this is a result message.
    pub fn is_result(&self) -> bool {
        matches!(self, Message::Result(_))
    }

    /// Get as assistant message if applicable.
    pub fn as_assistant(&self) -> Option<&AssistantMessage> {
        match self {
            Message::Assistant(m) => Some(m),
            _ => None,
        }
    }

    /// Get as result message if applicable.
    pub fn as_result(&self) -> Option<&ResultMessage> {
        match self {
            Message::Result(m) => Some(m),
            _ => None,
        }
    }
}

/// Tool execution progress message.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToolProgressMessage {
    pub uuid: Option<String>,
    pub session_id: Option<String>,
    pub tool_use_id: Option<String>,
    pub tool_name: Option<String>,
    pub parent_tool_use_id: Option<String>,
    pub elapsed_time_seconds: Option<f64>,
}

/// Status update message.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StatusMessage {
    pub uuid: Option<String>,
    pub session_id: Option<String>,
    pub status: Option<String>,
}

/// Authentication status message.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuthStatusMessage {
    pub uuid: Option<String>,
    pub session_id: Option<String>,
    pub is_authenticating: Option<bool>,
    pub output: Option<String>,
    pub error: Option<String>,
}

/// Context compaction boundary message.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CompactBoundaryMessage {
    pub uuid: Option<String>,
    pub session_id: Option<String>,
    pub compact_metadata: Option<serde_json::Value>,
}
