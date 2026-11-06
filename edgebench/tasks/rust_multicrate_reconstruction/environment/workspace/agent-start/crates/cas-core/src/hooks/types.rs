//! Claude Code hook input/output types
//!
//! Defines the JSON structures for communicating with Claude Code hooks.

use serde::{Deserialize, Serialize};

/// Input received from Claude Code hooks via stdin
#[derive(Debug, Clone, Deserialize, Default)]
pub struct HookInput {
    /// Unique session identifier
    #[serde(default)]
    pub session_id: String,

    /// Path to the transcript file
    #[serde(default)]
    pub transcript_path: Option<String>,

    /// Current working directory
    #[serde(default)]
    pub cwd: String,

    /// Permission mode (default, plan, acceptEdits, bypassPermissions)
    #[serde(default)]
    pub permission_mode: Option<String>,

    /// Hook event name
    #[serde(default)]
    pub hook_event_name: String,

    /// Tool name (PostToolUse)
    #[serde(default)]
    pub tool_name: Option<String>,

    /// Tool input parameters (PostToolUse)
    #[serde(default)]
    pub tool_input: Option<serde_json::Value>,

    /// Tool response (PostToolUse)
    #[serde(default)]
    pub tool_response: Option<serde_json::Value>,

    /// Tool use ID (PostToolUse)
    #[serde(default)]
    pub tool_use_id: Option<String>,

    /// User prompt text (UserPromptSubmit)
    #[serde(default)]
    pub user_prompt: Option<String>,

    /// Session start source (SessionStart)
    #[serde(default)]
    pub source: Option<String>,

    /// Session end reason (SessionEnd)
    #[serde(default)]
    pub reason: Option<String>,

    /// Subagent type (SubagentStart/SubagentStop)
    #[serde(default)]
    pub subagent_type: Option<String>,

    /// Subagent prompt (SubagentStart)
    #[serde(default)]
    pub subagent_prompt: Option<String>,
}

/// Output sent back to Claude Code via stdout (JSON)
#[derive(Debug, Clone, Serialize, Default)]
pub struct HookOutput {
    /// Whether to continue (false stops Claude entirely)
    #[serde(skip_serializing_if = "Option::is_none", rename = "continue")]
    pub continue_session: Option<bool>,

    /// Reason for stopping (when continue=false, shown to user not Claude)
    #[serde(skip_serializing_if = "Option::is_none", rename = "stopReason")]
    pub stop_reason: Option<String>,

    /// Decision control for Stop/SubagentStop/PostToolUse hooks
    /// - "block" prevents the action (for Stop: Claude continues working)
    /// - undefined allows the action
    #[serde(skip_serializing_if = "Option::is_none")]
    pub decision: Option<String>,

    /// Reason for decision (shown to Claude when decision="block")
    #[serde(skip_serializing_if = "Option::is_none")]
    pub reason: Option<String>,

    /// Suppress output from transcript
    #[serde(skip_serializing_if = "Option::is_none", rename = "suppressOutput")]
    pub suppress_output: Option<bool>,

    /// System message to show user
    #[serde(skip_serializing_if = "Option::is_none", rename = "systemMessage")]
    pub system_message: Option<String>,

    /// Hook-specific output
    #[serde(skip_serializing_if = "Option::is_none", rename = "hookSpecificOutput")]
    pub hook_specific_output: Option<HookSpecificOutput>,
}

/// Hook-specific output variants
#[derive(Debug, Clone, Serialize)]
pub struct HookSpecificOutput {
    /// Hook event name (must match input)
    #[serde(rename = "hookEventName")]
    pub hook_event_name: String,

    /// Additional context to inject (SessionStart, UserPromptSubmit)
    #[serde(skip_serializing_if = "Option::is_none", rename = "additionalContext")]
    pub additional_context: Option<String>,

    /// Permission decision (PreToolUse only)
    #[serde(skip_serializing_if = "Option::is_none", rename = "permissionDecision")]
    pub permission_decision: Option<String>,

    /// Reason for permission decision
    #[serde(
        skip_serializing_if = "Option::is_none",
        rename = "permissionDecisionReason"
    )]
    pub permission_decision_reason: Option<String>,

    /// Modified input (PreToolUse only)
    #[serde(skip_serializing_if = "Option::is_none", rename = "updatedInput")]
    pub updated_input: Option<serde_json::Value>,
}

impl HookOutput {
    /// Create an empty output (success, no changes)
    pub fn empty() -> Self { todo!() }

    /// Create output with context injection
    pub fn with_context(event_name: &str, context: String) -> Self { todo!() }

    /// Create output that signals an error (exit code 2)
    pub fn blocking_error(message: String) -> Self { todo!() }

    /// Create output that blocks the Stop hook (Claude continues working)
    /// Use this when you want to prevent Claude from stopping.
    /// The reason is shown to Claude to explain why it should continue.
    pub fn block_stop(reason: String) -> Self { todo!() }

    /// Create output that blocks Stop and also injects context
    ///
    /// Note: Stop hooks don't support hookSpecificOutput in Claude Code's schema.
    /// Context is passed via systemMessage instead.
    pub fn block_stop_with_context(_event_name: &str, reason: String, context: String) -> Self { todo!() }

    /// Create output with permission decision (for PreToolUse/PermissionRequest)
    ///
    /// Use "allow" to auto-approve, "deny" to block, or return empty() to ask user.
    pub fn with_permission_decision(event_name: &str, decision: &str, reason: &str) -> Self { todo!() }

    /// Create output with modified tool input (for PreToolUse)
    pub fn with_updated_input(event_name: &str, updated_input: serde_json::Value) -> Self { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::hooks::types::*;


    #[test]
    fn test_parse_post_tool_use_input() {
        let json = r#"{
            "session_id": "abc123",
            "cwd": "/test/dir",
            "hook_event_name": "PostToolUse",
            "tool_name": "Write",
            "tool_input": {"file_path": "/test/file.rs"},
            "tool_response": {"success": true}
        }"#;

        let input: HookInput = serde_json::from_str(json).unwrap();
        assert_eq!(input.tool_name, Some("Write".to_string()));
        assert!(input.tool_input.is_some());
    }

    #[test]
    fn test_hook_output_serialization() {
        let output = HookOutput::with_context("SessionStart", "Test context".to_string());
        let json = serde_json::to_string(&output).unwrap();

        assert!(json.contains("hookSpecificOutput"));
        assert!(json.contains("SessionStart"));
        assert!(json.contains("additionalContext"));
    }

    #[test]
    fn test_empty_output() {
        let output = HookOutput::empty();
        let json = serde_json::to_string(&output).unwrap();
        assert_eq!(json, "{}");
    }


}
