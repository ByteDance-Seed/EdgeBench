//! Prompt type for tracking user prompts in AI sessions
//!
//! Captures the full text of prompts sent to AI agents, enabling
//! attribution of code changes back to the prompts that triggered them.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

use crate::scope::Scope;

/// Role of a message in a conversation
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum MessageRole {
    /// User/human message
    #[default]
    User,
    /// Assistant response
    Assistant,
    /// Tool use by the assistant
    ToolUse,
}

/// A single message in a conversation transcript
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Message {
    /// Role of this message
    pub role: MessageRole,
    /// Content of the message
    pub content: String,
    /// Tool name (for ToolUse messages)
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub tool_name: Option<String>,
    /// Tool input (for ToolUse messages)
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub tool_input: Option<serde_json::Value>,
    /// When this message was sent
    pub timestamp: DateTime<Utc>,
}

impl Message {
    /// Create a user message
    pub fn user(content: String) -> Self { todo!() }

    /// Create an assistant message
    pub fn assistant(content: String) -> Self { todo!() }

    /// Create a tool use message
    pub fn tool_use(tool_name: String, tool_input: serde_json::Value, summary: String) -> Self { todo!() }
}

/// Information about the AI agent that processed the prompt
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct AgentInfo {
    /// Tool name (e.g., "claude-code")
    pub tool: String,
    /// Model ID (e.g., "claude-sonnet-4-20250514")
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub model: Option<String>,
    /// Tool version (e.g., "1.0.34")
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub version: Option<String>,
}

/// A captured user prompt from a Claude Code session
///
/// Prompts are captured via the UserPromptSubmit hook and linked to
/// file changes made in response to them. This enables "git blame"
/// style attribution: given any line of code, trace it back to the
/// prompt that requested its creation.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Prompt {
    /// Unique identifier (prompt-{ulid})
    pub id: String,

    /// Session ID where this prompt was submitted
    pub session_id: String,

    /// Agent ID that received the prompt
    pub agent_id: String,

    /// Full prompt text as submitted by the user
    pub content: String,

    /// SHA-256 hash of content for deduplication
    pub content_hash: String,

    /// When the prompt was submitted
    pub timestamp: DateTime<Utc>,

    /// When Claude started responding (if tracked)
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub response_started: Option<DateTime<Utc>>,

    /// Task ID being worked on when prompt was submitted (if any)
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub task_id: Option<String>,

    /// Storage scope (always project for prompts)
    #[serde(default)]
    pub scope: Scope,

    // Blame v2 fields
    /// Full conversation transcript (messages array)
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub messages: Vec<Message>,

    /// Model that processed this prompt (e.g., "claude-sonnet-4-20250514")
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub model: Option<String>,

    /// Claude Code version used (e.g., "1.0.34")
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub tool_version: Option<String>,
}

impl Prompt {
    /// Create a new prompt with the given content
    pub fn new(id: String, session_id: String, agent_id: String, content: String) -> Self { todo!() }

    /// Create a new prompt with all fields specified
    pub fn with_task(
        id: String,
        session_id: String,
        agent_id: String,
        content: String,
        task_id: Option<String>,
    ) -> Self { todo!() }

    /// Create a new prompt with model info
    pub fn with_model_info(
        id: String,
        session_id: String,
        agent_id: String,
        content: String,
        model: Option<String>,
        tool_version: Option<String>,
    ) -> Self { todo!() }

    /// Add a message to the conversation transcript
    pub fn add_message(&mut self, message: Message) { todo!() }

    /// Add a user message to the transcript
    pub fn add_user_message(&mut self, content: String) { todo!() }

    /// Add an assistant message to the transcript
    pub fn add_assistant_message(&mut self, content: String) { todo!() }

    /// Add a tool use to the transcript
    pub fn add_tool_use(
        &mut self,
        tool_name: String,
        tool_input: serde_json::Value,
        summary: String,
    ) { todo!() }

    /// Get a preview of the prompt content (first N characters)
    pub fn preview(&self, max_len: usize) -> String { todo!() }

    /// Mark when response started
    pub fn mark_response_started(&mut self) { todo!() }
}

impl Default for Prompt {
    fn default() -> Self { todo!() }
}

/// Compute SHA-256 hash of content for deduplication
fn compute_content_hash(content: &str) -> String { todo!() }

#[cfg(test)]
mod tests {
    use crate::prompt::*;


    #[test]
    fn test_prompt_with_task() {
        let prompt = Prompt::with_task(
            "prompt-abc123".to_string(),
            "session-xyz".to_string(),
            "agent-1".to_string(),
            "Fix the bug".to_string(),
            Some("cas-1234".to_string()),
        );

        assert_eq!(prompt.task_id, Some("cas-1234".to_string()));
    }

    #[test]
    fn test_prompt_preview() {
        let prompt = Prompt::new(
            "prompt-1".to_string(),
            "session-1".to_string(),
            "agent-1".to_string(),
            "This is a very long prompt that should be truncated".to_string(),
        );

        assert_eq!(prompt.preview(20), "This is a very lo...");
        assert_eq!(
            prompt.preview(100),
            "This is a very long prompt that should be truncated"
        );
    }

    #[test]
    fn test_content_hash_deterministic() {
        let content = "Test prompt content";
        let hash1 = compute_content_hash(content);
        let hash2 = compute_content_hash(content);

        assert_eq!(hash1, hash2);
        assert_eq!(hash1.len(), 64); // SHA-256 produces 64 hex chars
    }

    #[test]
    fn test_mark_response_started() {
        let mut prompt = Prompt::new(
            "prompt-1".to_string(),
            "session-1".to_string(),
            "agent-1".to_string(),
            "Test prompt".to_string(),
        );

        assert!(prompt.response_started.is_none());
        prompt.mark_response_started();
        assert!(prompt.response_started.is_some());
    }
}
