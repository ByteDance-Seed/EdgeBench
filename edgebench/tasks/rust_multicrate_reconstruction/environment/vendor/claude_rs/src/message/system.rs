//! System message type.

use serde::{Deserialize, Serialize};
use serde_json::Value;

/// System message sent at the start of a session.
///
/// Contains initialization information like session ID, available tools,
/// model information, and other session configuration.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SystemMessage {
    /// Message subtype (e.g., "init")
    pub subtype: Option<String>,

    /// Unique message identifier
    pub uuid: Option<String>,

    /// Session identifier
    pub session_id: Option<String>,

    /// API key source information
    pub api_key_source: Option<String>,

    /// Current working directory
    pub cwd: Option<String>,

    /// Available tools
    pub tools: Option<Vec<ToolInfo>>,

    /// MCP server information
    pub mcp_servers: Option<Vec<McpServerInfo>>,

    /// Model being used
    pub model: Option<String>,

    /// Permission mode
    pub permission_mode: Option<String>,

    /// Available slash commands
    pub slash_commands: Option<Vec<SlashCommand>>,

    /// Output style
    pub output_style: Option<String>,

    /// Available agents
    pub agents: Option<Value>,

    /// Enabled betas
    pub betas: Option<Vec<String>>,

    /// Claude Code version
    pub claude_code_version: Option<String>,

    /// Available skills
    pub skills: Option<Vec<SkillInfo>>,

    /// Available plugins
    pub plugins: Option<Vec<PluginInfo>>,
}

impl SystemMessage {
    /// Check if this is an init message.
    pub fn is_init(&self) -> bool {
        self.subtype.as_deref() == Some("init")
    }

    /// Get the list of available tool names.
    pub fn tool_names(&self) -> Vec<&str> {
        self.tools
            .as_ref()
            .map(|tools| tools.iter().filter_map(|t| t.name.as_deref()).collect())
            .unwrap_or_default()
    }
}

/// Information about an available tool.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToolInfo {
    pub name: Option<String>,
    pub description: Option<String>,
    #[serde(rename = "inputSchema")]
    pub input_schema: Option<Value>,
}

/// Information about an MCP server.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct McpServerInfo {
    pub name: Option<String>,
    pub status: Option<String>,
    pub tools: Option<Vec<String>>,
}

/// Information about a slash command.
///
/// **Note:** In Claude Code 2.1.3+, slash commands and skills were unified.
/// This struct represents the unified skill concept in system messages.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SlashCommand {
    pub name: Option<String>,
    pub description: Option<String>,
    #[serde(rename = "argsDescription")]
    pub args_description: Option<String>,
}

/// Information about a skill.
///
/// **Note:** In Claude Code 2.1.3+, skills and slash commands are unified.
/// Skills can be hidden from the slash menu with `user-invocable: false`
/// or blocked from model invocation with `disable-model-invocation: true`.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SkillInfo {
    pub name: Option<String>,
    pub description: Option<String>,
}

/// Information about a plugin.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PluginInfo {
    #[serde(rename = "type")]
    pub plugin_type: Option<String>,
    pub path: Option<String>,
    pub name: Option<String>,
}
