//! Factory MCP Tool E2E Tests (Claude Session)
//!
//! Tests that Claude can discover and use factory MCP tools (`mcp__cas__coordination`)
//! in a real session. Verifies tool discovery, parameter passing, and response
//! interpretation.
//!
//! # Running
//! These tests require tmux (to avoid CLAUDECODE env var conflict):
//! ```bash
//! cargo test --test e2e_test factory_e2e --features claude_rs_e2e -- --ignored --nocapture
//! ```

#![cfg(feature = "claude_rs_e2e")]

mod lifecycle;
mod real_factory;

use crate::fixtures::HookTestEnv;
use claude_rs::{Message, QueryOptions, session};

/// Test that Claude gets a clear error when spawning workers without an epic
#[tokio::test]
#[ignore]
async fn test_claude_spawn_without_epic_error() {
    let env = HookTestEnv::new();

    println!("Test environment: {:?}", env.dir());

    let result = session(
        QueryOptions::new()
            .model("haiku")
            .cwd(env.dir())
            .mcp_config(env.mcp_config_path())
            .max_turns(3)
            .allow_tool("mcp__cas__coordination"),
        |mut sess| async move {
            sess.send(
                "Use mcp__cas__coordination with action='spawn_workers' and count=2. \
                Report exactly what error you get.",
            )
            .await?;

            loop {
                let msg = sess.await_response(None).await?;
                if let Message::Assistant(ref a) = msg {
                    println!("Assistant: {}", a.text());
                }
                if let Message::Result(ref r) = msg {
                    return Ok(r.clone());
                }
            }
        },
    )
    .await;

    match result {
        Ok(r) => {
            let text = r.result.as_deref().unwrap_or("");
            println!("\nFinal result: {}", text);
            let lower = text.to_lowercase();
            assert!(
                lower.contains("epic") || lower.contains("error") || lower.contains("no active"),
                "Should report epic-related error. Got: {}",
                text
            );
        }
        Err(e) => {
            panic!("Session failed: {:?}", e);
        }
    }
}

/// Test that Claude can create an epic and spawn workers

/// Test that Claude can query worker status

/// Test that Claude can send a message to a worker

/// Test that Claude can run gc_report
#[tokio::test]
#[ignore]
async fn test_claude_gc_report() {
    let env = HookTestEnv::new();

    let result = session(
        QueryOptions::new()
            .model("haiku")
            .cwd(env.dir())
            .mcp_config(env.mcp_config_path())
            .max_turns(3)
            .allow_tool("mcp__cas__coordination"),
        |mut sess| async move {
            sess.send(
                "Use mcp__cas__coordination with action='gc_report'. \
                Report exactly what the tool returned.",
            )
            .await?;

            loop {
                let msg = sess.await_response(None).await?;
                if let Message::Assistant(ref a) = msg {
                    println!("Assistant: {}", a.text());
                }
                if let Message::Result(ref r) = msg {
                    return Ok(r.clone());
                }
            }
        },
    )
    .await;

    match result {
        Ok(r) => {
            let text = r.result.as_deref().unwrap_or("");
            println!("\nFinal result: {}", text);
            let lower = text.to_lowercase();
            assert!(
                lower.contains("stale")
                    || lower.contains("agents")
                    || lower.contains("prompts")
                    || lower.contains("gc"),
                "Should contain GC report info. Got: {}",
                text
            );
        }
        Err(e) => {
            panic!("Session failed: {:?}", e);
        }
    }
}
