//! CLI integration tests.
//!
//! These tests require the Claude CLI to be installed.
//! Run with: cargo test --features live

use claude_rs::cli::{CommandBuilder, Parser};
use claude_rs::message::Message;

#[test]
fn test_command_builder_creates_valid_args() {
    let builder = CommandBuilder::new();
    let args = builder.build();

    assert!(args.contains(&"--print".to_string()));
    assert!(args.contains(&"--output-format".to_string()));
    assert!(args.contains(&"stream-json".to_string()));
}

#[test]
fn test_command_builder_with_prompt() {
    let mut builder = CommandBuilder::new();
    builder.prompt("Hello Claude");
    let args = builder.build();

    assert!(args.contains(&"-p".to_string()));
    assert!(args.contains(&"Hello Claude".to_string()));
}

#[test]
fn test_parser_handles_system_message() {
    let mut parser = Parser::new();
    let json = r#"{"type": "system", "subtype": "init", "session_id": "test-session", "model": "claude-sonnet"}"#;
    let messages = parser.feed(&format!("{json}\n"));

    assert_eq!(messages.len(), 1);
    match &messages[0] {
        Message::System(sys) => {
            assert_eq!(sys.session_id.as_deref(), Some("test-session"));
            assert_eq!(sys.model.as_deref(), Some("claude-sonnet"));
        }
        _ => panic!("Expected System message"),
    }
}

#[test]
fn test_parser_handles_assistant_message() {
    let mut parser = Parser::new();
    let json = r#"{"type": "assistant", "session_id": "test", "message": {"role": "assistant", "content": [{"type": "text", "text": "Hello!"}]}}"#;
    let messages = parser.feed(&format!("{json}\n"));

    assert_eq!(messages.len(), 1);
    match &messages[0] {
        Message::Assistant(assistant) => {
            assert_eq!(assistant.text(), "Hello!");
        }
        _ => panic!("Expected Assistant message"),
    }
}

#[test]
fn test_parser_handles_result_message() {
    let mut parser = Parser::new();
    let json = r#"{"type": "result", "subtype": "success", "session_id": "test", "result": "Done", "total_cost_usd": 0.001}"#;
    let messages = parser.feed(&format!("{json}\n"));

    assert_eq!(messages.len(), 1);
    match &messages[0] {
        Message::Result(result) => {
            assert!(result.is_success());
            assert_eq!(result.text(), "Done");
            assert_eq!(result.total_cost_usd, Some(0.001));
        }
        _ => panic!("Expected Result message"),
    }
}

#[test]
fn test_parser_handles_user_message() {
    let mut parser = Parser::new();
    let json = r#"{"type": "user", "session_id": "test", "message": {"role": "user", "content": [{"type": "text", "text": "Hi"}]}, "is_replay": true}"#;
    let messages = parser.feed(&format!("{json}\n"));

    assert_eq!(messages.len(), 1);
    match &messages[0] {
        Message::User(user) => {
            assert!(user.is_replay());
            assert_eq!(user.text(), "Hi");
        }
        _ => panic!("Expected User message"),
    }
}

#[test]
fn test_parser_handles_tool_progress() {
    let mut parser = Parser::new();
    let json = r#"{"type": "tool_progress", "session_id": "test", "tool_name": "Bash", "tool_use_id": "tool_123"}"#;
    let messages = parser.feed(&format!("{json}\n"));

    assert_eq!(messages.len(), 1);
    match &messages[0] {
        Message::ToolProgress(progress) => {
            assert_eq!(progress.tool_name.as_deref(), Some("Bash"));
            assert_eq!(progress.tool_use_id.as_deref(), Some("tool_123"));
        }
        _ => panic!("Expected ToolProgress message"),
    }
}

#[test]
fn test_parser_handles_status_message() {
    let mut parser = Parser::new();
    let json = r#"{"type": "status", "session_id": "test", "status": "compacting"}"#;
    let messages = parser.feed(&format!("{json}\n"));

    assert_eq!(messages.len(), 1);
    match &messages[0] {
        Message::Status(status) => {
            assert_eq!(status.status.as_deref(), Some("compacting"));
        }
        _ => panic!("Expected Status message"),
    }
}

// Live tests - only run with --features live
#[cfg(feature = "live")]
mod live_tests {
    use claude_rs::{QueryOptions, prompt, query};
    use futures::StreamExt;

    #[tokio::test]
    async fn test_simple_query() {
        let options = QueryOptions::new()
            .model("claude-sonnet-4-5-20250929")
            .max_turns(1);

        let mut stream = query("What is 2+2? Reply with just the number.", options)
            .expect("Failed to start query");

        let mut got_result = false;
        while let Some(msg) = stream.next().await {
            if let Ok(claude_rs::Message::Result(r)) = msg {
                got_result = true;
                assert!(r.is_success() || r.result.is_some());
            }
        }
        assert!(got_result, "Should have received a result message");
    }

    #[tokio::test]
    #[ignore = "Live CLI behavior and account state can return non-success terminal results"]
    async fn test_prompt_function() {
        let options = QueryOptions::new()
            .model("claude-sonnet-4-5-20250929")
            .max_turns(1);

        let result = prompt("What is 2+2? Reply with just the number.", options)
            .await
            .expect("Failed to get prompt result");

        assert!(result.is_success() || !result.is_error.unwrap_or(false));
    }
}
