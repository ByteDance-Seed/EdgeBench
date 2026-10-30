//! QueryOptions tests.

use claude_rs::options::{PermissionMode, QueryOptions, SystemPrompt};
use std::path::PathBuf;

#[test]
fn test_default_options() {
    let options = QueryOptions::default();

    assert!(options.model.is_none());
    assert!(options.system_prompt.is_none());
    assert!(options.max_turns.is_none());
    assert!(options.permission_mode.is_none());
    assert!(options.tools.is_empty());
    assert!(options.hooks.is_empty());
    assert!(!options.continue_session);
    assert!(!options.mock);
}

#[test]
fn test_options_builder_pattern() {
    let options = QueryOptions::new()
        .model("claude-sonnet-4-5-20250929")
        .max_turns(10)
        .max_thinking_tokens(5000)
        .max_budget_usd(1.0)
        .permission_mode(PermissionMode::AcceptEdits);

    assert_eq!(options.model.as_deref(), Some("claude-sonnet-4-5-20250929"));
    assert_eq!(options.max_turns, Some(10));
    assert_eq!(options.max_thinking_tokens, Some(5000));
    assert_eq!(options.max_budget_usd, Some(1.0));
    assert_eq!(options.permission_mode, Some(PermissionMode::AcceptEdits));
}

#[test]
fn test_system_prompt_text() {
    let options =
        QueryOptions::new().system_prompt(SystemPrompt::text("You are a helpful assistant"));

    match &options.system_prompt {
        Some(SystemPrompt::Text(text)) => assert_eq!(text, "You are a helpful assistant"),
        _ => panic!("Expected Text system prompt"),
    }
}

#[test]
fn test_system_prompt_preset() {
    let options = QueryOptions::new().system_prompt(SystemPrompt::preset("claude_code"));

    match &options.system_prompt {
        Some(SystemPrompt::Preset(name)) => assert_eq!(name, "claude_code"),
        _ => panic!("Expected Preset system prompt"),
    }
}

#[test]
fn test_system_prompt_append() {
    let options = QueryOptions::new().system_prompt(SystemPrompt::append("Additional context"));

    match &options.system_prompt {
        Some(SystemPrompt::Append(text)) => assert_eq!(text, "Additional context"),
        _ => panic!("Expected Append system prompt"),
    }
}

#[test]
fn test_cwd_option() {
    let options = QueryOptions::new().cwd("/home/user/project");

    assert_eq!(
        options.cwd.as_deref(),
        Some(PathBuf::from("/home/user/project").as_path())
    );
}

#[test]
fn test_tool_filters() {
    let options = QueryOptions::new()
        .allow_tool("Bash")
        .allow_tool("Read")
        .disallow_tool("Write");

    assert_eq!(options.allowed_tools, vec!["Bash", "Read"]);
    assert_eq!(options.disallowed_tools, vec!["Write"]);
}

#[test]
fn test_session_options() {
    let options = QueryOptions::new().resume_session("session-123").fork();

    assert_eq!(options.resume.as_deref(), Some("session-123"));
    assert!(options.fork_session);
}

#[test]
fn test_continue_last() {
    let options = QueryOptions::new().continue_last();

    assert!(options.continue_session);
}

#[test]
fn test_include_partials() {
    let options = QueryOptions::new().include_partials();

    assert!(options.include_partial_messages);
}

#[test]
fn test_output_schema() {
    let schema = serde_json::json!({
        "type": "object",
        "properties": {
            "answer": {"type": "string"}
        }
    });

    let options = QueryOptions::new().output_schema(schema.clone());

    assert_eq!(options.output_schema, Some(schema));
}

#[test]
fn test_beta_features() {
    let options = QueryOptions::new()
        .beta("extended_thinking")
        .beta("web_search");

    assert_eq!(options.betas, vec!["extended_thinking", "web_search"]);
}

#[test]
fn test_mock_mode() {
    let options = QueryOptions::new().mock();

    assert!(options.mock);
}

#[test]
fn test_permission_mode_to_cli_arg() {
    assert_eq!(PermissionMode::Default.to_cli_arg(), "default");
    assert_eq!(PermissionMode::AcceptEdits.to_cli_arg(), "acceptEdits");
    assert_eq!(
        PermissionMode::BypassPermissions.to_cli_arg(),
        "bypassPermissions"
    );
    assert_eq!(PermissionMode::Plan.to_cli_arg(), "plan");
    assert_eq!(PermissionMode::DontAsk.to_cli_arg(), "dontAsk");
}

#[test]
fn test_permission_mode_default() {
    let mode = PermissionMode::default();
    assert_eq!(mode, PermissionMode::Default);
}

#[test]
fn test_permission_mode_serde() {
    let mode = PermissionMode::AcceptEdits;
    let json = serde_json::to_string(&mode).unwrap();
    assert_eq!(json, "\"acceptEdits\"");

    let parsed: PermissionMode = serde_json::from_str(&json).unwrap();
    assert_eq!(parsed, PermissionMode::AcceptEdits);
}
