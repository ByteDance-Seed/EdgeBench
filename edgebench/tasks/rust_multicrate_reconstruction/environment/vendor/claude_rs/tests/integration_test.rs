//! Integration tests requiring live Claude CLI.
//!
//! These tests are ignored by default. Run with:
//! ```
//! ANTHROPIC_API_KEY=sk-... cargo test --test integration_test -- --ignored
//! ```
//!
//! Or in mock mode:
//! ```
//! cargo test --test integration_test -- --ignored
//! ```

use claude_rs::message::Message;
use claude_rs::options::QueryOptions;
use futures::StreamExt;

/// Test basic query execution (live mode - requires Claude CLI with subscription).
#[tokio::test]
#[ignore]
async fn test_basic_query_live() {
    let options = QueryOptions::new().max_turns(1);

    let stream = claude_rs::query("What is 2+2? Reply with just the number.", options).unwrap();
    futures::pin_mut!(stream);

    let mut received_result = false;

    while let Some(result) = stream.next().await {
        match result {
            Ok(Message::System(_)) => {}
            Ok(Message::Assistant(a)) => {
                println!("Assistant: {}", a.text());
            }
            Ok(Message::Result(r)) => {
                received_result = true;
                println!("Result: success={}", r.is_success());
            }
            Ok(msg) => {
                println!("Other message: {:?}", std::mem::discriminant(&msg));
            }
            Err(e) => panic!("Error: {e}"),
        }
    }

    // System message may or may not be received depending on CLI version/timing
    // The important assertions are that we got a result
    assert!(received_result, "Expected result message");
}

/// Test prompt function (live mode).
#[tokio::test]
#[ignore]
async fn test_prompt_live() {
    let options = QueryOptions::new().max_turns(1);

    let result = claude_rs::prompt("Say 'hello' and nothing else", options).await;

    match result {
        Ok(r) => {
            println!("Prompt result: {}", r.text());
            assert!(r.is_success() || r.is_max_turns());
        }
        Err(e) => {
            panic!("Prompt failed: {e}");
        }
    }
}

/// Test query with custom model.
#[tokio::test]
#[ignore]
async fn test_query_with_model() {
    let options = QueryOptions::new()
        .model("claude-sonnet-4-5-20250929")
        .max_turns(1);

    let stream = claude_rs::query("Say 'test'", options).unwrap();
    futures::pin_mut!(stream);

    let mut message_count = 0;
    while let Some(result) = stream.next().await {
        message_count += 1;
        if let Err(e) = result {
            panic!("Stream error: {e}");
        }
    }

    assert!(message_count > 0, "Expected at least one message");
}

/// Test that tool filtering works.
#[tokio::test]
#[ignore]
async fn test_tool_filtering() {
    let options = QueryOptions::new()
        .disallow_tool("Bash")
        .disallow_tool("Write")
        .max_turns(1);

    let result = claude_rs::query("Say 'filtered'", options);
    assert!(result.is_ok(), "Query should succeed with tool filtering");
}

/// Test permission mode setting.
#[tokio::test]
#[ignore]
async fn test_permission_mode() {
    use claude_rs::options::PermissionMode;

    let options = QueryOptions::new()
        .permission_mode(PermissionMode::Plan)
        .max_turns(1);

    let result = claude_rs::query("Say 'plan mode'", options);
    assert!(result.is_ok(), "Query should succeed with permission mode");
}

/// Test CLI detection.
#[test]
fn test_cli_executable_detection() {
    use claude_rs::cli::find_executable;

    // This should either find the CLI or return an error
    match find_executable() {
        Ok(path) => {
            assert!(!path.as_os_str().is_empty(), "CLI path should not be empty");
        }
        Err(_) => {
            // Expected if CLI is not installed
        }
    }
}
