//! Hook system tests.

use async_trait::async_trait;
use claude_rs::hook::{Hook, HookEvent, HookHandler, HookInput, HookOutput, PermissionDecision};
use std::time::Duration;

/// Handler that always approves.
struct ApproveHandler;

#[async_trait]
impl HookHandler for ApproveHandler {
    async fn handle(&self, _input: HookInput) -> HookOutput {
        HookOutput::approve()
    }
}

/// Handler that always denies.
struct DenyHandler {
    reason: String,
}

#[async_trait]
impl HookHandler for DenyHandler {
    async fn handle(&self, _input: HookInput) -> HookOutput {
        HookOutput::deny(&self.reason)
    }
}

#[test]
fn test_hook_event_as_str() {
    assert_eq!(HookEvent::PreToolUse.as_str(), "PreToolUse");
    assert_eq!(HookEvent::PostToolUse.as_str(), "PostToolUse");
    assert_eq!(HookEvent::PermissionRequest.as_str(), "PermissionRequest");
    assert_eq!(HookEvent::SessionStart.as_str(), "SessionStart");
}

#[test]
fn test_hook_event_from_str() {
    assert_eq!(
        HookEvent::from_str("PreToolUse"),
        Some(HookEvent::PreToolUse)
    );
    assert_eq!(
        HookEvent::from_str("pre_tool_use"),
        Some(HookEvent::PreToolUse)
    );
    assert_eq!(
        HookEvent::from_str("PostToolUse"),
        Some(HookEvent::PostToolUse)
    );
    assert_eq!(HookEvent::from_str("invalid"), None);
}

#[test]
fn test_hook_creation() {
    let hook = Hook::on(HookEvent::PreToolUse, ApproveHandler);

    assert_eq!(hook.event, HookEvent::PreToolUse);
    assert!(hook.matcher.is_none());
    assert_eq!(hook.timeout, Duration::from_secs(30));
}

#[test]
fn test_hook_with_matcher() {
    let hook = Hook::on(HookEvent::PreToolUse, ApproveHandler).matcher("Bash");

    assert_eq!(hook.event, HookEvent::PreToolUse);
    assert_eq!(hook.matcher.as_deref(), Some("Bash"));
}

#[test]
fn test_hook_with_timeout() {
    let hook = Hook::on(HookEvent::PreToolUse, ApproveHandler).timeout(Duration::from_secs(60));

    assert_eq!(hook.timeout, Duration::from_secs(60));
}

#[test]
fn test_hook_builder() {
    let hook = Hook::builder(HookEvent::PreToolUse)
        .matcher("Edit")
        .timeout(Duration::from_secs(10))
        .handler(ApproveHandler);

    assert_eq!(hook.event, HookEvent::PreToolUse);
    assert_eq!(hook.matcher.as_deref(), Some("Edit"));
    assert_eq!(hook.timeout, Duration::from_secs(10));
}

#[test]
fn test_hook_builder_with_closure() {
    let hook = Hook::builder(HookEvent::PreToolUse)
        .handler_fn(|_input| async move { HookOutput::approve() });

    assert_eq!(hook.event, HookEvent::PreToolUse);
}

#[test]
fn test_hook_matches_event() {
    let hook = Hook::on(HookEvent::PreToolUse, ApproveHandler);

    assert!(hook.matches(HookEvent::PreToolUse, None));
    assert!(!hook.matches(HookEvent::PostToolUse, None));
}

#[test]
fn test_hook_matches_with_tool_name() {
    let hook = Hook::on(HookEvent::PreToolUse, ApproveHandler).matcher("Bash");

    // Matches correct tool
    assert!(hook.matches(HookEvent::PreToolUse, Some("Bash")));

    // Doesn't match wrong tool
    assert!(!hook.matches(HookEvent::PreToolUse, Some("Read")));

    // Doesn't match no tool (when matcher is set)
    assert!(!hook.matches(HookEvent::PreToolUse, None));
}

#[test]
fn test_hook_matches_without_matcher() {
    let hook = Hook::on(HookEvent::PreToolUse, ApproveHandler);

    // Matches any tool when no matcher
    assert!(hook.matches(HookEvent::PreToolUse, Some("Bash")));
    assert!(hook.matches(HookEvent::PreToolUse, Some("Read")));
    assert!(hook.matches(HookEvent::PreToolUse, None));
}

#[test]
fn test_hook_output_approve() {
    let output = HookOutput::approve();

    assert!(output.continue_execution);
    assert!(!output.suppress_output);
    assert_eq!(output.permission_decision, Some(PermissionDecision::Allow));
}

#[test]
fn test_hook_output_deny() {
    let output = HookOutput::deny("Not allowed");

    assert!(output.continue_execution);
    assert_eq!(output.permission_decision, Some(PermissionDecision::Deny));
    assert_eq!(
        output.permission_decision_reason.as_deref(),
        Some("Not allowed")
    );
}

#[test]
fn test_hook_output_ask() {
    let output = HookOutput::ask();

    assert!(output.continue_execution);
    assert_eq!(output.permission_decision, Some(PermissionDecision::Ask));
}

#[test]
fn test_hook_output_stop() {
    let output = HookOutput::stop("User requested stop");

    assert!(!output.continue_execution);
    assert_eq!(output.stop_reason.as_deref(), Some("User requested stop"));
}

#[test]
fn test_hook_output_with_updated_input() {
    let output = HookOutput::approve().with_updated_input(serde_json::json!({"new": "value"}));

    assert!(output.updated_input.is_some());
    assert_eq!(output.updated_input.unwrap()["new"], "value");
}

#[test]
fn test_hook_output_with_system_message() {
    let output = HookOutput::approve().with_system_message("Remember this context");

    assert_eq!(
        output.system_message.as_deref(),
        Some("Remember this context")
    );
}

#[test]
fn test_hook_output_suppress() {
    let output = HookOutput::approve().suppress();

    assert!(output.suppress_output);
}

#[tokio::test]
async fn test_hook_execute() {
    let hook = Hook::on(HookEvent::PreToolUse, ApproveHandler);

    let input = HookInput {
        event: "PreToolUse".to_string(),
        hook_id: "hook_123".to_string(),
        session_id: Some("session".to_string()),
        transcript_path: None,
        cwd: None,
        permission_mode: None,
        data: claude_rs::hook::input::HookInputData::Empty {},
    };

    let output = hook.execute(input).await;
    assert!(output.continue_execution);
}

#[tokio::test]
async fn test_hook_execute_deny() {
    let hook = Hook::on(
        HookEvent::PreToolUse,
        DenyHandler {
            reason: "Dangerous operation".to_string(),
        },
    );

    let input = HookInput {
        event: "PreToolUse".to_string(),
        hook_id: "hook_123".to_string(),
        session_id: None,
        transcript_path: None,
        cwd: None,
        permission_mode: None,
        data: claude_rs::hook::input::HookInputData::Empty {},
    };

    let output = hook.execute(input).await;
    assert_eq!(output.permission_decision, Some(PermissionDecision::Deny));
}
