//! User message type.

use crate::message::content::ContentBlock;
use serde::{Deserialize, Serialize};
use serde_json::Value;

/// User input message.
///
/// Represents user input or tool results being fed back to the assistant.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserMessage {
    /// Unique message identifier
    pub uuid: Option<String>,

    /// Session identifier
    pub session_id: Option<String>,

    /// The message content
    pub message: Option<UserMessageContent>,

    /// Parent tool use ID (for tool results)
    pub parent_tool_use_id: Option<String>,

    /// Whether this is a synthetic message
    pub is_synthetic: Option<bool>,

    /// Tool use result metadata
    pub tool_use_result: Option<Value>,

    /// Whether this is a replay of a previous message
    pub is_replay: Option<bool>,
}

/// Content of a user message.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserMessageContent {
    /// Role (always "user" for user messages)
    pub role: Option<String>,

    /// Content blocks
    pub content: Option<Vec<ContentBlock>>,
}

impl UserMessage {
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

    /// Check if this is a replay message.
    pub fn is_replay(&self) -> bool {
        self.is_replay.unwrap_or(false)
    }

    /// Check if this is a tool result.
    pub fn is_tool_result(&self) -> bool {
        self.tool_use_result.is_some() || self.parent_tool_use_id.is_some()
    }
}
