//! E2E hook tests with real API calls.
//!
//! These tests use actual Claude API calls to verify hook behavior.
//! They require:
//! - Valid Claude API credentials
//! - The hook CLI to be installed and accessible
//!
//! Run with: cargo test --test e2e_hooks_test -- --ignored
//!
//! Set CLAUDE_RS_E2E_HOOK_CMD to specify the hook command (default: "cas hook")

use claude_rs::{QueryOptions, prompt};
use serde_json::json;
use std::fs;
use tempfile::TempDir;

/// Get the hook command from environment or use default
fn hook_command() -> String {
    std::env::var("CLAUDE_RS_E2E_HOOK_CMD").unwrap_or_else(|_| "cas hook".to_string())
}

/// Set up a test project directory with hook configuration
fn setup_test_project(hook_cmd: &str) -> TempDir {
    let temp = TempDir::new().expect("Failed to create temp dir");
    let claude_dir = temp.path().join(".claude");
    fs::create_dir_all(&claude_dir).expect("Failed to create .claude dir");

    // Create settings.json with hooks configured
    let settings = json!({
        "hooks": {
            "PreToolUse": [{
                "matcher": ".*",
                "hooks": [{
                    "type": "command",
                    "command": format!("{} PreToolUse", hook_cmd),
                    "timeout": 5000
                }]
            }],
            "PostToolUse": [{
                "matcher": ".*",
                "hooks": [{
                    "type": "command",
                    "command": format!("{} PostToolUse", hook_cmd),
                    "timeout": 5000
                }]
            }],
            "Stop": [{
                "hooks": [{
                    "type": "command",
                    "command": format!("{} Stop", hook_cmd),
                    "timeout": 5000
                }]
            }]
        }
    });

    let settings_path = claude_dir.join("settings.json");
    fs::write(
        &settings_path,
        serde_json::to_string_pretty(&settings).unwrap(),
    )
    .expect("Failed to write settings.json");

    // Create a simple test file for Read operations
    fs::write(temp.path().join("test.txt"), "Hello from test file")
        .expect("Failed to write test file");

    temp
}

/// Helper to run a one-shot query with hooks
async fn run_query(
    prompt_text: &str,
    project_dir: &std::path::Path,
) -> claude_rs::Result<claude_rs::message::ResultMessage> {
    let options = QueryOptions::new().cwd(project_dir).max_turns(3);

    prompt(prompt_text, options).await
}

// =============================================================================
// E2E Tests (require real API calls)
// =============================================================================

#[tokio::test]
#[ignore = "Requires real API calls - run with --ignored"]
async fn test_pre_tool_use_hook_fires() {
    let hook_cmd = hook_command();
    let project = setup_test_project(&hook_cmd);

    // Ask Claude to read a file - this should trigger PreToolUse hook
    let result = run_query(
        "Read the contents of test.txt and tell me what it says.",
        project.path(),
    )
    .await
    .expect("Query failed");

    // Verify we got a successful response (hook allowed the operation)
    assert!(result.is_success(), "Query should succeed");

    // The result should contain something about the test file
    if let Some(ref text) = result.result {
        println!("Result: {text}");
    }
}

#[tokio::test]
#[ignore = "Requires real API calls - run with --ignored"]
async fn test_hook_can_deny_tool_use() {
    // This test requires the hook to be configured to deny certain operations
    // Set CLAUDE_RS_E2E_DENY_PATTERN to a tool pattern that should be denied

    let deny_pattern =
        std::env::var("CLAUDE_RS_E2E_DENY_PATTERN").unwrap_or_else(|_| "Bash".to_string());

    let hook_cmd = hook_command();
    let project = setup_test_project(&hook_cmd);

    // Try to use a tool that should be denied
    let prompt_text = match deny_pattern.as_str() {
        "Bash" => "Run the command 'echo hello' using Bash",
        "Write" => "Create a new file called denied.txt with content 'test'",
        _ => "Do something that triggers a tool",
    };

    let result = run_query(prompt_text, project.path())
        .await
        .expect("Query failed");

    // The query should complete (possibly with Claude explaining it can't do the action)
    // Note: Even if hook denies, Claude might gracefully handle it
    // The important thing is the hook fired and prevented the actual tool execution
    println!("Result: {result:?}");
}

#[tokio::test]
#[ignore = "Requires real API calls - run with --ignored"]
async fn test_session_start_injects_context() {
    let hook_cmd = hook_command();
    let project = setup_test_project(&hook_cmd);

    // Add SessionStart hook
    let claude_dir = project.path().join(".claude");
    let settings = json!({
        "hooks": {
            "SessionStart": [{
                "hooks": [{
                    "type": "command",
                    "command": format!("{} SessionStart", hook_cmd),
                    "timeout": 5000
                }]
            }]
        }
    });
    fs::write(
        claude_dir.join("settings.json"),
        serde_json::to_string_pretty(&settings).unwrap(),
    )
    .expect("Failed to update settings");

    // Simple query - SessionStart hook should inject context
    let result = run_query(
        "What context do you have about this session?",
        project.path(),
    )
    .await
    .expect("Query failed");

    // Check that we got a response
    assert!(result.is_success(), "Query should succeed");
}

#[tokio::test]
#[ignore = "Requires real API calls - run with --ignored"]
async fn test_multi_agent_isolation() {
    // This test verifies that hooks properly isolate different sessions
    // Requires hook implementation to track per-session state

    let hook_cmd = hook_command();
    let project = setup_test_project(&hook_cmd);

    // Run two queries concurrently
    let project_path = project.path().to_path_buf();
    let project_path2 = project_path.clone();

    let handle1 = tokio::spawn(async move {
        let options = QueryOptions::new().cwd(&project_path).max_turns(2);

        prompt("What is 1 + 1?", options).await
    });

    let handle2 = tokio::spawn(async move {
        let options = QueryOptions::new().cwd(&project_path2).max_turns(2);

        prompt("What is 2 + 2?", options).await
    });

    // Both should complete successfully without interfering
    let result1 = handle1.await.expect("Task 1 panicked");
    let result2 = handle2.await.expect("Task 2 panicked");

    assert!(result1.is_ok(), "Query 1 should succeed");
    assert!(result2.is_ok(), "Query 2 should succeed");
}

// =============================================================================
// Streaming Mode Tests
// =============================================================================

#[tokio::test]
#[ignore = "Requires real API calls - run with --ignored"]
async fn test_streaming_session_basic() {
    use claude_rs::{Message, QueryOptions, session};

    let result = session(QueryOptions::new().max_turns(1), |mut sess| async move {
        sess.send("What is 2 + 2? Reply with just the number.")
            .await?;

        loop {
            let msg = sess.await_response(None).await?;
            println!("Got message: {:?}", std::mem::discriminant(&msg));
            if let Message::Result(ref r) = msg {
                println!("Result: {:?}", r.result);
                return Ok(r.clone());
            }
        }
    })
    .await;

    match result {
        Ok(r) => {
            println!("Success: {:?}", r.result);
            assert!(r.is_success());
        }
        Err(e) => {
            panic!("Session failed: {e:?}");
        }
    }
}

#[tokio::test]
#[ignore = "Requires real API calls - run with --ignored"]
async fn test_streaming_session_with_hooks() {
    use claude_rs::{Message, QueryOptions, session};

    let hook_cmd = hook_command();
    let project = setup_test_project(&hook_cmd);

    let result = session(
        QueryOptions::new().cwd(project.path()).max_turns(3),
        |mut sess| async move {
            sess.send("Read the contents of test.txt").await?;

            loop {
                let msg = sess.await_response(None).await?;
                println!("Got message: {:?}", std::mem::discriminant(&msg));
                if let Message::Result(ref r) = msg {
                    println!("Result: {:?}", r.result);
                    return Ok(r.clone());
                }
            }
        },
    )
    .await;

    match result {
        Ok(r) => {
            println!("Success: {:?}", r.result);
            assert!(r.is_success());
        }
        Err(e) => {
            panic!("Session with hooks failed: {e:?}");
        }
    }
}

#[tokio::test]
#[ignore = "Requires real API calls - run with --ignored"]
async fn test_streaming_multi_turn() {
    use claude_rs::{Message, QueryOptions, session};

    let result = session(QueryOptions::new().max_turns(5), |mut sess| async move {
        // First turn
        sess.send("Remember this number: 42").await?;
        loop {
            let msg = sess.await_response(None).await?;
            if matches!(msg, Message::Result(_)) {
                break;
            }
        }

        // Second turn - ask about the remembered number
        sess.send("What number did I ask you to remember?").await?;
        loop {
            let msg = sess.await_response(None).await?;
            if let Message::Result(ref r) = msg {
                println!("Multi-turn result: {:?}", r.result);
                // The response should mention 42
                let text = r.result.as_deref().unwrap_or("");
                assert!(
                    text.contains("42"),
                    "Expected response to contain '42', got: {text}"
                );
                return Ok(r.clone());
            }
        }
    })
    .await;

    match result {
        Ok(r) => {
            println!("Multi-turn success: {:?}", r.result);
            assert!(r.is_success());
        }
        Err(e) => {
            panic!("Multi-turn session failed: {e:?}");
        }
    }
}

// =============================================================================
// Test Utilities
// =============================================================================

/// Verify the hook command is available
#[test]
fn test_hook_command_exists() {
    let hook_cmd = hook_command();
    let parts: Vec<&str> = hook_cmd.split_whitespace().collect();
    let cmd = parts.first().expect("Empty hook command");

    let output = std::process::Command::new("which")
        .arg(cmd)
        .output()
        .expect("Failed to run 'which'");

    if !output.status.success() {
        eprintln!("Warning: Hook command '{cmd}' not found in PATH. E2E tests will fail.");
        eprintln!("Set CLAUDE_RS_E2E_HOOK_CMD to specify a different command.");
    }
}
