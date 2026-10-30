//! Hook test harness for E2E testing of external CLI hooks.
//!
//! This harness allows testing external hook commands (configured via settings.json)
//! without requiring actual Claude API calls.
//!
//! # Example
//!
//! ```rust,no_run
//! use claude_rs::testing::HookTestHarness;
//! use serde_json::json;
//!
//! let harness = HookTestHarness::new("my-hook-cli")
//!     .cwd("/path/to/project")
//!     .session_id("test-session-123");
//!
//! // Test PreToolUse hook
//! let output = harness.pre_tool_use("Read", json!({"file_path": "/test.rs"}));
//! assert!(output.is_allowed());
//!
//! // Test with custom session for multi-agent scenarios
//! let output = harness
//!     .with_session("agent-2")
//!     .pre_tool_use("Write", json!({"file_path": "/out.rs", "content": "test"}));
//! ```

use crate::hook::{HookOutput, PermissionDecision};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::io::Write;
use std::path::PathBuf;
use std::process::{Command, Stdio};
use std::time::Duration;

/// Test harness for external CLI hooks.
///
/// Simulates Claude Code's hook invocation protocol, allowing you to test
/// external hook commands without actual API calls.
#[derive(Debug, Clone)]
pub struct HookTestHarness {
    /// Base hook command (e.g., "my-hook-cli hook")
    command: String,
    /// Working directory for hook execution
    cwd: PathBuf,
    /// Session ID to use in hook inputs
    session_id: String,
    /// Timeout for hook execution
    timeout: Duration,
}

/// Input sent to external hooks (matches Claude Code protocol).
#[derive(Debug, Clone, Default, Serialize)]
struct ExternalHookInput {
    session_id: String,
    cwd: String,
    hook_event_name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    tool_name: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    tool_input: Option<Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    tool_response: Option<Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    tool_use_id: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    user_prompt: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    source: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    reason: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    subagent_type: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    transcript_path: Option<String>,
}

/// Output from external hooks.
#[derive(Debug, Clone, Default, Deserialize)]
pub struct ExternalHookOutput {
    /// Whether to continue execution
    #[serde(rename = "continue")]
    pub continue_session: Option<bool>,
    /// Reason for stopping
    #[serde(rename = "stopReason")]
    pub stop_reason: Option<String>,
    /// Decision (block/allow)
    pub decision: Option<String>,
    /// Reason for decision
    pub reason: Option<String>,
    /// System message to display
    #[serde(rename = "systemMessage")]
    pub system_message: Option<String>,
    /// Hook-specific output
    #[serde(rename = "hookSpecificOutput")]
    pub hook_specific_output: Option<HookSpecificOutput>,
}

/// Hook-specific output fields.
#[derive(Debug, Clone, Default, Deserialize)]
pub struct HookSpecificOutput {
    #[serde(rename = "hookEventName")]
    pub hook_event_name: Option<String>,
    #[serde(rename = "additionalContext")]
    pub additional_context: Option<String>,
    #[serde(rename = "permissionDecision")]
    pub permission_decision: Option<String>,
    #[serde(rename = "permissionDecisionReason")]
    pub permission_decision_reason: Option<String>,
    #[serde(rename = "updatedInput")]
    pub updated_input: Option<Value>,
}

impl ExternalHookOutput {
    /// Check if the hook allowed the operation.
    pub fn is_allowed(&self) -> bool {
        if let Some(ref hso) = self.hook_specific_output
            && let Some(ref decision) = hso.permission_decision
        {
            return decision == "allow";
        }
        // Default: allowed if no explicit deny
        !self.is_denied()
    }

    /// Check if the hook denied the operation.
    pub fn is_denied(&self) -> bool {
        if let Some(ref hso) = self.hook_specific_output
            && let Some(ref decision) = hso.permission_decision
        {
            return decision == "deny";
        }
        false
    }

    /// Check if the hook blocked (for Stop/SubagentStop hooks).
    pub fn is_blocked(&self) -> bool {
        self.decision.as_deref() == Some("block")
    }

    /// Get the permission decision.
    pub fn permission_decision(&self) -> Option<&str> {
        self.hook_specific_output
            .as_ref()
            .and_then(|h| h.permission_decision.as_deref())
    }

    /// Get the denial/block reason.
    pub fn denial_reason(&self) -> Option<&str> {
        self.hook_specific_output
            .as_ref()
            .and_then(|h| h.permission_decision_reason.as_deref())
            .or(self.reason.as_deref())
    }

    /// Get injected context (for SessionStart/UserPromptSubmit).
    pub fn additional_context(&self) -> Option<&str> {
        self.hook_specific_output
            .as_ref()
            .and_then(|h| h.additional_context.as_deref())
    }

    /// Get modified input (for PreToolUse).
    pub fn updated_input(&self) -> Option<&Value> {
        self.hook_specific_output
            .as_ref()
            .and_then(|h| h.updated_input.as_ref())
    }

    /// Convert to claude_rs HookOutput.
    pub fn to_hook_output(&self) -> HookOutput {
        let mut output = HookOutput::default();

        if self.is_denied() {
            output.permission_decision = Some(PermissionDecision::Deny);
            output.permission_decision_reason = self.denial_reason().map(String::from);
        } else if self.is_allowed() {
            output.permission_decision = Some(PermissionDecision::Allow);
        }

        if let Some(ctx) = self.additional_context() {
            output.system_message = Some(ctx.to_string());
        }

        if let Some(input) = self.updated_input() {
            output.updated_input = Some(input.clone());
        }

        if !self.continue_session.unwrap_or(true) {
            output.continue_execution = false;
            output.stop_reason = self.stop_reason.clone();
        }

        output
    }
}

/// Result of hook execution.
#[derive(Debug)]
pub struct HookResult {
    /// Parsed output from the hook
    pub output: ExternalHookOutput,
    /// Raw stdout from the hook process
    pub raw_stdout: String,
    /// Raw stderr from the hook process
    pub raw_stderr: String,
    /// Exit code
    pub exit_code: i32,
    /// Execution time
    pub duration: Duration,
}

impl HookResult {
    /// Check if hook execution succeeded (exit code 0).
    pub fn is_success(&self) -> bool {
        self.exit_code == 0
    }

    /// Check if the hook allowed the operation.
    pub fn is_allowed(&self) -> bool {
        self.output.is_allowed()
    }

    /// Check if the hook denied the operation.
    pub fn is_denied(&self) -> bool {
        self.output.is_denied()
    }
}

impl HookTestHarness {
    /// Create a new hook test harness.
    ///
    /// # Arguments
    /// * `command` - Base command for the hook (e.g., "my-hook-cli hook")
    pub fn new(command: impl Into<String>) -> Self {
        Self {
            command: command.into(),
            cwd: std::env::current_dir().unwrap_or_else(|_| PathBuf::from(".")),
            session_id: format!("test-session-{}", uuid::Uuid::new_v4()),
            timeout: Duration::from_secs(30),
        }
    }

    /// Set the working directory.
    pub fn cwd(mut self, cwd: impl Into<PathBuf>) -> Self {
        self.cwd = cwd.into();
        self
    }

    /// Set the session ID.
    pub fn session_id(mut self, session_id: impl Into<String>) -> Self {
        self.session_id = session_id.into();
        self
    }

    /// Set the timeout for hook execution.
    pub fn timeout(mut self, timeout: Duration) -> Self {
        self.timeout = timeout;
        self
    }

    /// Create a copy with a different session ID.
    ///
    /// Useful for testing multi-agent scenarios.
    pub fn with_session(&self, session_id: impl Into<String>) -> Self {
        let mut copy = self.clone();
        copy.session_id = session_id.into();
        copy
    }

    // =========================================================================
    // Hook Event Methods
    // =========================================================================

    /// Simulate SessionStart hook.
    pub fn session_start(&self, source: Option<&str>) -> HookResult {
        let input = ExternalHookInput {
            session_id: self.session_id.clone(),
            cwd: self.cwd.to_string_lossy().to_string(),
            hook_event_name: "SessionStart".to_string(),
            source: source.map(String::from),
            ..Default::default()
        };
        self.call_hook("SessionStart", input)
    }

    /// Simulate PreToolUse hook.
    pub fn pre_tool_use(&self, tool_name: &str, tool_input: Value) -> HookResult {
        let input = ExternalHookInput {
            session_id: self.session_id.clone(),
            cwd: self.cwd.to_string_lossy().to_string(),
            hook_event_name: "PreToolUse".to_string(),
            tool_name: Some(tool_name.to_string()),
            tool_input: Some(tool_input),
            tool_use_id: Some(format!("toolu_{}", uuid::Uuid::new_v4())),
            ..Default::default()
        };
        self.call_hook("PreToolUse", input)
    }

    /// Simulate PostToolUse hook.
    pub fn post_tool_use(
        &self,
        tool_name: &str,
        tool_input: Value,
        tool_response: Value,
    ) -> HookResult {
        let input = ExternalHookInput {
            session_id: self.session_id.clone(),
            cwd: self.cwd.to_string_lossy().to_string(),
            hook_event_name: "PostToolUse".to_string(),
            tool_name: Some(tool_name.to_string()),
            tool_input: Some(tool_input),
            tool_response: Some(tool_response),
            tool_use_id: Some(format!("toolu_{}", uuid::Uuid::new_v4())),
            ..Default::default()
        };
        self.call_hook("PostToolUse", input)
    }

    /// Simulate UserPromptSubmit hook.
    pub fn user_prompt_submit(&self, user_prompt: &str) -> HookResult {
        let input = ExternalHookInput {
            session_id: self.session_id.clone(),
            cwd: self.cwd.to_string_lossy().to_string(),
            hook_event_name: "UserPromptSubmit".to_string(),
            user_prompt: Some(user_prompt.to_string()),
            ..Default::default()
        };
        self.call_hook("UserPromptSubmit", input)
    }

    /// Simulate Stop hook.
    pub fn stop(&self, reason: Option<&str>) -> HookResult {
        let input = ExternalHookInput {
            session_id: self.session_id.clone(),
            cwd: self.cwd.to_string_lossy().to_string(),
            hook_event_name: "Stop".to_string(),
            reason: reason.map(String::from),
            ..Default::default()
        };
        self.call_hook("Stop", input)
    }

    /// Simulate SubagentStart hook.
    pub fn subagent_start(&self, subagent_type: Option<&str>) -> HookResult {
        let input = ExternalHookInput {
            session_id: self.session_id.clone(),
            cwd: self.cwd.to_string_lossy().to_string(),
            hook_event_name: "SubagentStart".to_string(),
            subagent_type: subagent_type.map(String::from),
            ..Default::default()
        };
        self.call_hook("SubagentStart", input)
    }

    /// Simulate SubagentStop hook.
    pub fn subagent_stop(&self, subagent_type: Option<&str>) -> HookResult {
        let input = ExternalHookInput {
            session_id: self.session_id.clone(),
            cwd: self.cwd.to_string_lossy().to_string(),
            hook_event_name: "SubagentStop".to_string(),
            subagent_type: subagent_type.map(String::from),
            ..Default::default()
        };
        self.call_hook("SubagentStop", input)
    }

    // =========================================================================
    // Internal
    // =========================================================================

    fn call_hook(&self, event: &str, input: ExternalHookInput) -> HookResult {
        let start = std::time::Instant::now();
        let full_command = format!("{} {}", self.command, event);

        let mut child = Command::new("sh")
            .args(["-c", &full_command])
            .current_dir(&self.cwd)
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()
            .expect("Failed to spawn hook process");

        // Write input to stdin
        if let Some(mut stdin) = child.stdin.take() {
            let input_json = serde_json::to_string(&input).expect("Failed to serialize input");
            stdin
                .write_all(input_json.as_bytes())
                .expect("Failed to write to hook stdin");
        }

        // Wait for output
        let output = child
            .wait_with_output()
            .expect("Failed to wait for hook process");

        let duration = start.elapsed();
        let raw_stdout = String::from_utf8_lossy(&output.stdout).to_string();
        let raw_stderr = String::from_utf8_lossy(&output.stderr).to_string();
        let exit_code = output.status.code().unwrap_or(-1);

        // Parse output
        let hook_output: ExternalHookOutput = if raw_stdout.trim().is_empty() {
            ExternalHookOutput::default()
        } else {
            serde_json::from_str(&raw_stdout).unwrap_or_else(|e| {
                eprintln!("Warning: Failed to parse hook output: {e}\nRaw: {raw_stdout}");
                ExternalHookOutput::default()
            })
        };

        HookResult {
            output: hook_output,
            raw_stdout,
            raw_stderr,
            exit_code,
            duration,
        }
    }
}

#[cfg(test)]
mod tests {
    use crate::testing::hook_harness::*;

    #[test]
    fn test_harness_creation() {
        let harness = HookTestHarness::new("echo")
            .cwd("/tmp")
            .session_id("test-123");

        assert_eq!(harness.command, "echo");
        assert_eq!(harness.cwd, PathBuf::from("/tmp"));
        assert_eq!(harness.session_id, "test-123");
    }

    #[test]
    fn test_with_session() {
        let harness = HookTestHarness::new("echo").session_id("agent-1");
        let harness2 = harness.with_session("agent-2");

        assert_eq!(harness.session_id, "agent-1");
        assert_eq!(harness2.session_id, "agent-2");
    }

    #[test]
    fn test_output_parsing() {
        let json = r#"{
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": "Not allowed"
            }
        }"#;

        let output: ExternalHookOutput = serde_json::from_str(json).unwrap();
        assert!(output.is_denied());
        assert!(!output.is_allowed());
        assert_eq!(output.denial_reason(), Some("Not allowed"));
    }

    #[test]
    fn test_output_allowed() {
        let json = r#"{
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "allow"
            }
        }"#;

        let output: ExternalHookOutput = serde_json::from_str(json).unwrap();
        assert!(output.is_allowed());
        assert!(!output.is_denied());
    }

    #[test]
    fn test_empty_output_is_allowed() {
        let output = ExternalHookOutput::default();
        assert!(output.is_allowed());
        assert!(!output.is_denied());
    }

    #[test]
    fn test_blocked_output() {
        let json = r#"{
            "decision": "block",
            "reason": "Task incomplete"
        }"#;

        let output: ExternalHookOutput = serde_json::from_str(json).unwrap();
        assert!(output.is_blocked());
        assert_eq!(output.denial_reason(), Some("Task incomplete"));
    }
}
