//! Assistant message type.

use crate::message::content::ContentBlock;
use serde::{Deserialize, Serialize};
use serde_json::Value;

/// Assistant response message.
///
/// Contains the assistant's response including text and tool use requests.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AssistantMessage {
    /// Unique message identifier
    pub uuid: Option<String>,

    /// Session identifier
    pub session_id: Option<String>,

    /// The message content
    pub message: Option<MessageContent>,

    /// Parent tool use ID (for subagent responses)
    pub parent_tool_use_id: Option<String>,

    /// Error information if any
    pub error: Option<Value>,
}

/// Content of an assistant message.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MessageContent {
    /// Role (always "assistant" for assistant messages)
    pub role: Option<String>,

    /// Content blocks
    pub content: Option<Vec<ContentBlock>>,
}

impl AssistantMessage {
    /// Get all text content concatenated.
    pub fn text(&self) -> String {
        self.message
            .as_ref()
            .and_then(|m| m.content.as_ref())
            .map(|blocks| {
                blocks
                    .iter()
                    .filter_map(|b| match b {
                        ContentBlock::Text { text } => Some(text.as_str()),
                        _ => None,
                    })
                    .collect::<Vec<_>>()
                    .join("")
            })
            .unwrap_or_default()
    }

    /// Get all text blocks.
    pub fn text_blocks(&self) -> Vec<&str> {
        self.message
            .as_ref()
            .and_then(|m| m.content.as_ref())
            .map(|blocks| {
                blocks
                    .iter()
                    .filter_map(|b| match b {
                        ContentBlock::Text { text } => Some(text.as_str()),
                        _ => None,
                    })
                    .collect()
            })
            .unwrap_or_default()
    }

    /// Get all tool use blocks.
    pub fn tool_uses(&self) -> Vec<&super::content::ToolUse> {
        self.message
            .as_ref()
            .and_then(|m| m.content.as_ref())
            .map(|blocks| {
                blocks
                    .iter()
                    .filter_map(|b| match b {
                        ContentBlock::ToolUse(tu) => Some(tu),
                        _ => None,
                    })
                    .collect()
            })
            .unwrap_or_default()
    }

    /// Check if this message contains tool use.
    pub fn has_tool_use(&self) -> bool {
        self.message
            .as_ref()
            .and_then(|m| m.content.as_ref())
            .map(|blocks| blocks.iter().any(|b| matches!(b, ContentBlock::ToolUse(_))))
            .unwrap_or(false)
    }

    /// Get thinking content if present.
    pub fn thinking(&self) -> Option<&str> {
        self.message
            .as_ref()
            .and_then(|m| m.content.as_ref())
            .and_then(|blocks| {
                blocks.iter().find_map(|b| match b {
                    ContentBlock::Thinking { thinking } => Some(thinking.as_str()),
                    _ => None,
                })
            })
    }
}
