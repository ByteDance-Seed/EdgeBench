//! Partial/streaming message type.

use serde::{Deserialize, Serialize};
use serde_json::Value;

/// Partial message for streaming events.
///
/// These messages are sent during streaming to provide real-time updates
/// on content generation.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PartialMessage {
    /// Unique message identifier
    pub uuid: Option<String>,

    /// Session identifier
    pub session_id: Option<String>,

    /// The streaming event data
    pub event: Option<StreamEvent>,

    /// Parent tool use ID (for subagent events)
    pub parent_tool_use_id: Option<String>,
}

/// A streaming event.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum StreamEvent {
    /// Message start event
    MessageStart { message: Option<Value> },

    /// Content block start
    ContentBlockStart {
        index: u32,
        content_block: Option<Value>,
    },

    /// Content block delta (incremental update)
    ContentBlockDelta {
        index: u32,
        delta: Option<ContentDelta>,
    },

    /// Content block stop
    ContentBlockStop { index: u32 },

    /// Message delta
    MessageDelta {
        delta: Option<Value>,
        usage: Option<Value>,
    },

    /// Message stop
    MessageStop,

    /// Ping event
    Ping,

    /// Error event
    Error { error: Option<Value> },
}

/// Content delta for streaming updates.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
#[allow(clippy::enum_variant_names)]
pub enum ContentDelta {
    /// Text delta
    TextDelta { text: String },

    /// Input JSON delta (for tool use)
    InputJsonDelta { partial_json: String },

    /// Thinking delta
    ThinkingDelta { thinking: String },
}

impl PartialMessage {
    /// Get text delta if this is a text streaming event.
    pub fn text_delta(&self) -> Option<&str> {
        match &self.event {
            Some(StreamEvent::ContentBlockDelta {
                delta: Some(ContentDelta::TextDelta { text }),
                ..
            }) => Some(text),
            _ => None,
        }
    }

    /// Get thinking delta if this is a thinking streaming event.
    pub fn thinking_delta(&self) -> Option<&str> {
        match &self.event {
            Some(StreamEvent::ContentBlockDelta {
                delta: Some(ContentDelta::ThinkingDelta { thinking }),
                ..
            }) => Some(thinking),
            _ => None,
        }
    }

    /// Check if this is a message stop event.
    pub fn is_message_stop(&self) -> bool {
        matches!(&self.event, Some(StreamEvent::MessageStop))
    }
}
