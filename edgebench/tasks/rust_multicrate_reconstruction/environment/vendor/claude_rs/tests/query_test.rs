//! Query tests.

use async_trait::async_trait;
use claude_rs::hook::{Hook, HookEvent, HookHandler, HookInput, HookOutput};
use claude_rs::options::{PermissionMode, QueryOptions, SystemPrompt};

/// Test handler that approves everything.
struct ApproveHandler;

#[async_trait]
impl HookHandler for ApproveHandler {
    async fn handle(&self, _input: HookInput) -> HookOutput {
        HookOutput::approve()
    }
}

#[test]
fn test_query_options_default() {
    let options = QueryOptions::default();

    assert!(options.model.is_none());
    assert!(options.system_prompt.is_none());
    assert!(options.cwd.is_none());
    assert!(options.hooks.is_empty());
    assert!(options.tools.is_empty());
}

#[test]
fn test_query_options_with_model() {
    let options = QueryOptions::new().model("claude-sonnet-4-5-20250929");

    assert_eq!(options.model.as_deref(), Some("claude-sonnet-4-5-20250929"));
}

#[test]
fn test_query_options_with_hooks() {
    let hook = Hook::on(HookEvent::PreToolUse, ApproveHandler);

    let options = QueryOptions::new().hook(hook);

    assert_eq!(options.hooks.len(), 1);
    assert_eq!(options.hooks[0].event, HookEvent::PreToolUse);
}

#[test]
fn test_query_options_with_multiple_hooks() {
    let hook1 = Hook::on(HookEvent::PreToolUse, ApproveHandler);
    let hook2 = Hook::on(HookEvent::PostToolUse, ApproveHandler);

    let options = QueryOptions::new().hook(hook1).hook(hook2);

    assert_eq!(options.hooks.len(), 2);
}

#[test]
fn test_query_options_with_system_prompt() {
    let options =
        QueryOptions::new().system_prompt(SystemPrompt::text("You are a helpful assistant"));

    assert!(options.system_prompt.is_some());
    match &options.system_prompt {
        Some(SystemPrompt::Text(text)) => assert_eq!(text, "You are a helpful assistant"),
        _ => panic!("Expected Text system prompt"),
    }
}

#[test]
fn test_query_options_with_max_turns() {
    let options = QueryOptions::new().max_turns(5);

    assert_eq!(options.max_turns, Some(5));
}

#[test]
fn test_query_options_with_max_budget() {
    let options = QueryOptions::new().max_budget_usd(10.0);

    assert_eq!(options.max_budget_usd, Some(10.0));
}

#[test]
fn test_query_options_with_permission_mode() {
    let options = QueryOptions::new().permission_mode(PermissionMode::BypassPermissions);

    assert_eq!(
        options.permission_mode,
        Some(PermissionMode::BypassPermissions)
    );
}

#[test]
fn test_query_options_with_resume_session() {
    let options = QueryOptions::new().resume_session("session-abc-123");

    assert_eq!(options.resume.as_deref(), Some("session-abc-123"));
}

#[test]
fn test_query_options_with_continue_last() {
    let options = QueryOptions::new().continue_last();

    assert!(options.continue_session);
}

#[test]
fn test_query_options_chaining() {
    let hook = Hook::on(HookEvent::PreToolUse, ApproveHandler);

    let options = QueryOptions::new()
        .model("claude-sonnet-4-5-20250929")
        .system_prompt(SystemPrompt::text("Be concise"))
        .max_turns(10)
        .max_budget_usd(5.0)
        .permission_mode(PermissionMode::AcceptEdits)
        .hook(hook)
        .include_partials()
        .include_replays();

    assert_eq!(options.model.as_deref(), Some("claude-sonnet-4-5-20250929"));
    assert!(matches!(options.system_prompt, Some(SystemPrompt::Text(_))));
    assert_eq!(options.max_turns, Some(10));
    assert_eq!(options.max_budget_usd, Some(5.0));
    assert_eq!(options.permission_mode, Some(PermissionMode::AcceptEdits));
    assert_eq!(options.hooks.len(), 1);
    assert!(options.include_partial_messages);
    assert!(options.include_replays);
}

#[test]
fn test_query_options_with_cwd() {
    let options = QueryOptions::new().cwd("/home/user/project");

    assert!(options.cwd.is_some());
}

#[test]
fn test_query_options_with_tool_filters() {
    let options = QueryOptions::new()
        .allow_tool("Bash")
        .allow_tool("Read")
        .disallow_tool("Write");

    assert_eq!(options.allowed_tools, vec!["Bash", "Read"]);
    assert_eq!(options.disallowed_tools, vec!["Write"]);
}

#[test]
fn test_query_options_mock_mode() {
    let options = QueryOptions::new().mock();

    assert!(options.mock);
}

#[test]
fn test_query_options_with_output_schema() {
    let schema = serde_json::json!({
        "type": "object",
        "properties": {
            "answer": {"type": "string"}
        }
    });

    let options = QueryOptions::new().output_schema(schema.clone());

    assert_eq!(options.output_schema, Some(schema));
}
