//! Content block types.

use serde::{Deserialize, Serialize};
use serde_json::Value;

/// A content block within a message.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum ContentBlock {
    /// Plain text content
    Text { text: String },

    /// Tool use request
    #[serde(rename = "tool_use")]
    ToolUse(ToolUse),

    /// Tool result
    #[serde(rename = "tool_result")]
    ToolResult(ToolResult),

    /// Thinking content (extended thinking)
    Thinking { thinking: String },

    /// Image content
    Image { source: ImageSource },

    /// Redacted thinking
    #[serde(rename = "redacted_thinking")]
    RedactedThinking { data: Option<String> },

    /// Server tool use (MCP)
    #[serde(rename = "server_tool_use")]
    ServerToolUse {
        id: String,
        name: String,
        input: Value,
    },

    /// Web search tool use
    #[serde(rename = "web_search_tool_use")]
    WebSearchToolUse {
        id: String,
        name: String,
        input: Value,
    },

    /// Web search tool result
    #[serde(rename = "web_search_tool_result")]
    WebSearchToolResult { tool_use_id: String, content: Value },

    /// MCP tool result
    #[serde(rename = "mcp_tool_result")]
    McpToolResult { tool_use_id: String, content: Value },

    /// Citation marker
    #[serde(rename = "citation_marker")]
    CitationMarker {
        source_id: String,
        citation_index: u32,
    },

    /// Container for nested content
    Container { items: Vec<ContentBlock> },
}

/// Tool use request.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToolUse {
    /// Unique ID for this tool use
    pub id: String,

    /// Name of the tool to use
    pub name: String,

    /// Input arguments for the tool
    pub input: Value,
}

impl ToolUse {
    /// Get a specific input field.
    pub fn get_input(&self, key: &str) -> Option<&Value> {
        self.input.get(key)
    }

    /// Get input as a specific type.
    pub fn input_as<T: for<'de> Deserialize<'de>>(&self) -> Result<T, serde_json::Error> {
        serde_json::from_value(self.input.clone())
    }
}

/// Tool result.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToolResult {
    /// ID of the tool use this is a result for
    pub tool_use_id: String,

    /// Result content (can be string or structured)
    pub content: Value,

    /// Whether this is an error result
    #[serde(default)]
    pub is_error: bool,
}

/// Image source in content blocks.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum ImageSource {
    /// Base64 encoded image
    Base64 { media_type: String, data: String },
    /// URL reference
    Url { url: String },
}
