//! Control message response types for runtime queries.

use serde::{Deserialize, Serialize};
use serde_json::Value;

/// Slash command information.
///
/// **Note:** In Claude Code 2.1.3+, slash commands and skills were unified.
/// This struct is still valid for API responses but represents the unified skill concept.
/// Skills can be hidden from the slash menu with `user-invocable: false` or blocked
/// from model invocation with `disable-model-invocation: true`.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SlashCommand {
    /// Command name (without leading slash)
    pub name: String,
    /// Description of what the command does
    pub description: String,
    /// Hint for command arguments (e.g., "<file>")
    #[serde(default)]
    pub argument_hint: String,
}

/// Model information.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ModelInfo {
    /// Model identifier for API calls
    pub value: String,
    /// Human-readable display name
    pub display_name: String,
    /// Description of capabilities
    pub description: String,
}

/// Account information.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AccountInfo {
    /// User email
    #[serde(skip_serializing_if = "Option::is_none")]
    pub email: Option<String>,
    /// Organization name
    #[serde(skip_serializing_if = "Option::is_none")]
    pub organization: Option<String>,
    /// Subscription type
    #[serde(skip_serializing_if = "Option::is_none")]
    pub subscription_type: Option<String>,
    /// Token source
    #[serde(skip_serializing_if = "Option::is_none")]
    pub token_source: Option<String>,
    /// API key source
    #[serde(skip_serializing_if = "Option::is_none")]
    pub api_key_source: Option<String>,
}

/// MCP server connection status.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct McpServerStatus {
    /// Server name as configured
    pub name: String,
    /// Current connection status
    pub status: McpConnectionStatus,
    /// Server information (when connected)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub server_info: Option<McpServerInfo>,
}

/// MCP connection status.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum McpConnectionStatus {
    Connected,
    Failed,
    NeedsAuth,
    Pending,
}

/// MCP server info.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct McpServerInfo {
    /// Server name
    pub name: String,
    /// Server version
    pub version: String,
}

/// Initialize response from CLI.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct InitializeResponse {
    /// Available slash commands
    pub commands: Vec<SlashCommand>,
    /// Current output style
    pub output_style: String,
    /// Available output styles
    pub available_output_styles: Vec<String>,
    /// Available models
    pub models: Vec<ModelInfo>,
    /// Account information
    pub account: AccountInfo,
}

/// Control request subtypes that can be sent to CLI.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "subtype", rename_all = "snake_case")]
pub enum ControlRequestPayload {
    /// Initialize the session
    Initialize {
        #[serde(skip_serializing_if = "Option::is_none")]
        hooks: Option<Value>,
        #[serde(skip_serializing_if = "Option::is_none")]
        sdk_mcp_servers: Option<Vec<String>>,
        #[serde(skip_serializing_if = "Option::is_none")]
        json_schema: Option<Value>,
        #[serde(skip_serializing_if = "Option::is_none")]
        system_prompt: Option<String>,
        #[serde(skip_serializing_if = "Option::is_none")]
        append_system_prompt: Option<String>,
        #[serde(skip_serializing_if = "Option::is_none")]
        agents: Option<Value>,
    },
    /// Interrupt execution
    Interrupt,
    /// Set permission mode
    SetPermissionMode { mode: String },
    /// Set model
    SetModel { model: Option<String> },
    /// Set max thinking tokens
    SetMaxThinkingTokens { max_thinking_tokens: Option<u32> },
    /// Get MCP server status
    McpStatus,
    /// Rewind files to checkpoint
    RewindFiles { user_message_id: String },
}

/// Wrapper for control requests sent to CLI.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ControlRequestWrapper {
    #[serde(rename = "type")]
    pub msg_type: String,
    pub request_id: String,
    pub request: ControlRequestPayload,
}

impl ControlRequestWrapper {
    /// Create a new control request.
    pub fn new(request_id: String, request: ControlRequestPayload) -> Self {
        Self {
            msg_type: "control_request".to_string(),
            request_id,
            request,
        }
    }
}
