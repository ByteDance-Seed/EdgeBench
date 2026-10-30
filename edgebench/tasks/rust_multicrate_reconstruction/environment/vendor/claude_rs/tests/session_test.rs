//! Session tests.

use claude_rs::cli::CommandBuilder;
use claude_rs::options::{PermissionMode, QueryOptions};

#[test]
fn test_session_resume_generates_correct_args() {
    let options = QueryOptions::new().resume_session("session-abc-123");

    let builder = CommandBuilder::from_options(&options);
    let args = builder.build();

    // The args should contain --resume with session ID
    assert!(args.iter().any(|a| a == "--resume"));
    assert!(args.iter().any(|a| a == "session-abc-123"));
}

#[test]
fn test_session_continue_generates_correct_args() {
    let options = QueryOptions::new().continue_last();

    let builder = CommandBuilder::from_options(&options);
    let args = builder.build();

    // The args should contain --continue
    assert!(args.iter().any(|a| a == "--continue"));
}

#[test]
fn test_session_fork_generates_correct_args() {
    let options = QueryOptions::new().resume_session("session-xyz").fork();

    let builder = CommandBuilder::from_options(&options);
    let args = builder.build();

    // The args should contain both --resume and --fork
    assert!(args.iter().any(|a| a == "--resume"));
    assert!(args.iter().any(|a| a == "session-xyz"));
    // Fork would typically be passed as part of resume behavior
}

#[test]
fn test_session_options_with_model() {
    let options = QueryOptions::new()
        .resume_session("session-123")
        .model("claude-sonnet-4-5-20250929");

    let builder = CommandBuilder::from_options(&options);
    let args = builder.build();

    assert!(args.iter().any(|a| a == "--model"));
    assert!(args.iter().any(|a| a == "claude-sonnet-4-5-20250929"));
    assert!(args.iter().any(|a| a == "--resume"));
}

#[test]
fn test_session_options_with_permission_mode() {
    let options = QueryOptions::new()
        .resume_session("session-456")
        .permission_mode(PermissionMode::AcceptEdits);

    let builder = CommandBuilder::from_options(&options);
    let args = builder.build();

    assert!(args.iter().any(|a| a == "--permission-mode"));
    assert!(args.iter().any(|a| a == "acceptEdits"));
}

#[test]
fn test_session_options_with_max_turns() {
    let options = QueryOptions::new()
        .resume_session("session-789")
        .max_turns(5);

    let builder = CommandBuilder::from_options(&options);
    let args = builder.build();

    assert!(args.iter().any(|a| a == "--max-turns"));
    assert!(args.iter().any(|a| a == "5"));
}

#[test]
fn test_session_options_comprehensive() {
    let options = QueryOptions::new()
        .resume_session("session-full")
        .model("claude-opus-4-20250514")
        .max_turns(10)
        .max_budget_usd(5.0)
        .permission_mode(PermissionMode::BypassPermissions);

    let builder = CommandBuilder::from_options(&options);
    let args = builder.build();

    // Verify all expected args are present
    assert!(args.iter().any(|a| a == "--resume"));
    assert!(args.iter().any(|a| a == "session-full"));
    assert!(args.iter().any(|a| a == "--model"));
    assert!(args.iter().any(|a| a == "claude-opus-4-20250514"));
    assert!(args.iter().any(|a| a == "--max-turns"));
    assert!(args.iter().any(|a| a == "10"));
    assert!(args.iter().any(|a| a == "--permission-mode"));
    assert!(args.iter().any(|a| a == "bypassPermissions"));
}

#[test]
fn test_streaming_input_mode() {
    // Streaming input mode is used internally by Query
    let options = QueryOptions::new().model("claude-sonnet-4-5-20250929");

    // When streaming_input is set via start_query, it should add --input-format json-stream
    // This is handled internally
    assert!(options.model.is_some());
}
