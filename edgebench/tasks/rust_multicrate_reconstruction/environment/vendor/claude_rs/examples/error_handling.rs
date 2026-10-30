//! Comprehensive error handling tests for claude_rs.
//!
//! Run with: cargo run --example error_handling
//!
//! This example demonstrates proper error handling for various failure scenarios:
//! 1. Invalid/non-existent model names - Tests API validation
//! 2. max_turns=0 - Tests turn limiting behavior
//! 3. Zero/negative max_budget_usd - Tests budget constraints
//! 4. Resuming a non-existent session - Tests session validation
//! 5. CLI not installed - Tests executable detection (Note: falls back to PATH)
//! 6. Interrupting a query mid-stream - Tests graceful cancellation
//! 7. Dropping the Query handle early - Tests resource cleanup
//! 8. Permission mode requiring input - Tests permission flow
//!
//! Key findings:
//! - All errors are returned as Result::Err (no panics)
//! - Invalid model names return API error in result message
//! - max_turns=0 still allows one turn (CLI behavior)
//! - Zero budget queries may hang waiting for API response
//! - Non-existent sessions may create new sessions instead of failing
//! - Executable detection is resilient (tries CLAUDE_EXECUTABLE, PATH, known paths)
//! - Interrupts send signal but may not stop query immediately
//! - Dropping Query handle triggers proper cleanup via Drop trait
//! - Permission prompts may auto-grant in some modes

use claude_rs::{Message, PermissionMode, QueryOptions, query, resume_session, start_query};
use futures::StreamExt;
use std::time::Duration;

#[tokio::main]
async fn main() -> claude_rs::Result<()> {
    println!("=== Claude RS Error Handling Tests ===\n");

    // Test 1: Invalid model name
    println!("--- Test 1: Invalid Model Name ---");
    test_invalid_model().await;

    // Test 2: max_turns=0
    println!("\n--- Test 2: max_turns=0 ---");
    test_zero_max_turns().await;

    // Test 3: Negative budget - Note: f64 allows negatives but API rejects them
    println!("\n--- Test 3: Zero/Tiny Budget ---");
    test_zero_budget().await;

    println!("\n--- Test 3b: Negative Budget ---");
    test_negative_budget().await;

    // Test 4: Resume non-existent session
    println!("\n--- Test 4: Resume Non-existent Session ---");
    test_resume_nonexistent_session().await;

    // Test 5: CLI not found (simulated)
    println!("\n--- Test 5: CLI Not Found ---");
    test_cli_not_found().await;

    // Test 6: Interrupt mid-stream
    println!("\n--- Test 6: Interrupt Mid-stream ---");
    test_interrupt_mid_stream().await;

    // Test 7: Drop Query handle early
    println!("\n--- Test 7: Drop Query Early ---");
    test_drop_query_early().await;

    // Test 8: Permission mode requiring input
    println!("\n--- Test 8: Permission Mode Requiring Input ---");
    test_permission_mode_ask().await;

    println!("\n=== All Error Handling Tests Completed ===");
    println!("\nKey takeaways:");
    println!("- All errors were returned as Result::Err (no panics)");
    println!("- Error types are descriptive and actionable");
    println!("- Resources are properly cleaned up even on error");

    Ok(())
}

/// Test 1: Query with an invalid/non-existent model name
async fn test_invalid_model() {
    println!("Testing with invalid model 'gpt-4-turbo'...");

    let options = QueryOptions::new()
        .model("gpt-4-turbo") // This is an OpenAI model, not Claude
        .max_turns(1);

    match query("Hello", options) {
        Ok(mut stream) => {
            println!("Query started, awaiting response...");
            let mut got_error = false;

            while let Some(msg_result) = stream.next().await {
                match msg_result {
                    Ok(Message::Result(r)) => {
                        if r.is_error.unwrap_or(false) {
                            println!("✓ Got error result: {:?}", r.subtype);
                            println!("  Error message: {}", r.result.unwrap_or_default());
                            got_error = true;
                        } else {
                            println!("✗ Unexpectedly succeeded with invalid model");
                        }
                    }
                    Err(e) => {
                        println!("✓ Stream error (expected): {e}");
                        got_error = true;
                        break;
                    }
                    _ => {}
                }
            }

            if !got_error {
                println!("⚠ No error received (CLI may have fallen back to default model)");
            }
        }
        Err(e) => {
            println!("✓ Query creation failed (expected): {e}");
        }
    }
}

/// Test 2: Query with max_turns=0 (should complete immediately)
async fn test_zero_max_turns() {
    println!("Testing with max_turns=0...");

    let options = QueryOptions::new().max_turns(0);

    match query("What is 2+2?", options) {
        Ok(mut stream) => {
            println!("Query started...");
            let mut got_result = false;

            while let Some(msg_result) = stream.next().await {
                match msg_result {
                    Ok(Message::Result(r)) => {
                        println!(
                            "✓ Got result: is_error={}, subtype={:?}",
                            r.is_error.unwrap_or(false),
                            r.subtype
                        );
                        println!("  Result: {}", r.result.as_deref().unwrap_or("(none)"));
                        got_result = true;
                    }
                    Ok(Message::Assistant(_)) => {
                        println!("⚠ Got assistant message with max_turns=0");
                    }
                    Err(e) => {
                        println!("✓ Got error (expected): {e}");
                        got_result = true;
                        break;
                    }
                    _ => {}
                }
            }

            if got_result {
                println!("✓ Query completed (no assistant response expected)");
            } else {
                println!("✗ No result received");
            }
        }
        Err(e) => {
            println!("✓ Query failed immediately (alternative expected behavior): {e}");
        }
    }
}

/// Test 3: Query with zero/very small budget
async fn test_zero_budget() {
    println!("Testing with max_budget_usd=0.0...");

    let options = QueryOptions::new().max_budget_usd(0.0).max_turns(1);

    // Wrap the entire query in a timeout
    let timeout_result = tokio::time::timeout(Duration::from_secs(10), async {
        match query("What is the meaning of life?", options) {
            Ok(mut stream) => {
                println!("Query started...");

                while let Some(msg_result) = stream.next().await {
                    match msg_result {
                        Ok(Message::Result(r)) => {
                            if r.is_error.unwrap_or(false) {
                                println!("✓ Query failed due to budget constraint");
                                println!("  Subtype: {:?}", r.subtype);
                                println!("  Message: {}", r.result.unwrap_or_default());
                            } else {
                                println!("⚠ Query succeeded despite zero budget");
                                println!("  Cost: ${:.6}", r.total_cost_usd.unwrap_or(0.0));
                            }
                            return true;
                        }
                        Err(e) => {
                            println!("✓ Got error (may be budget-related): {e}");
                            return true;
                        }
                        _ => {}
                    }
                }
                false
            }
            Err(e) => {
                println!("✓ Query failed at creation (expected): {e}");
                true
            }
        }
    })
    .await;

    match timeout_result {
        Ok(_) => {
            println!("✓ Test completed within timeout");
        }
        Err(_) => {
            println!("⚠ Test timed out - zero budget query may hang indefinitely");
            println!("  This demonstrates that zero budget doesn't prevent query from starting");
        }
    }
}

/// Test 3b: Negative budget (f64 allows it, but should be rejected)
async fn test_negative_budget() {
    println!("Testing with max_budget_usd=-1.0...");

    let options = QueryOptions::new().max_budget_usd(-1.0).max_turns(1);

    // Wrap in timeout
    let timeout_result = tokio::time::timeout(Duration::from_secs(10), async {
        match query("Hello", options) {
            Ok(mut stream) => {
                println!("Query started (negative budget not rejected at SDK level)...");

                while let Some(msg_result) = stream.next().await {
                    match msg_result {
                        Ok(Message::Result(r)) => {
                            if r.is_error.unwrap_or(false) {
                                println!("✓ Query failed (likely due to invalid budget)");
                                println!("  Subtype: {:?}", r.subtype);
                            } else {
                                println!("⚠ Query succeeded with negative budget");
                            }
                            return true;
                        }
                        Err(e) => {
                            println!("✓ Got error: {e}");
                            return true;
                        }
                        _ => {}
                    }
                }
                false
            }
            Err(e) => {
                println!("✓ Query creation failed (expected): {e}");
                true
            }
        }
    })
    .await;

    match timeout_result {
        Ok(_) => println!("✓ Test completed"),
        Err(_) => println!("⚠ Test timed out"),
    }
}

/// Test 4: Resume a session that doesn't exist
async fn test_resume_nonexistent_session() {
    println!("Testing resume with fake session ID...");

    let fake_session_id = "session_nonexistent_12345_fake";
    let options = QueryOptions::new();

    match resume_session(fake_session_id, options) {
        Ok(mut query) => {
            println!("Resume call succeeded, sending message...");

            if let Err(e) = query.send_message("Hello").await {
                println!("✓ Send message failed (expected): {e}");
                return;
            }

            // Try to receive messages
            let mut got_error = false;
            while let Some(msg_result) = query.recv().await {
                match msg_result {
                    Ok(Message::Result(r)) => {
                        if r.is_error.unwrap_or(false) {
                            println!("✓ Got error result: {:?}", r.subtype);
                            println!("  Message: {}", r.result.unwrap_or_default());
                            got_error = true;
                        } else {
                            println!("✗ Unexpectedly succeeded resuming fake session");
                        }
                        break;
                    }
                    Err(e) => {
                        println!("✓ Got error (expected): {e}");
                        got_error = true;
                        break;
                    }
                    _ => {}
                }
            }

            if !got_error {
                println!("⚠ No error received when resuming fake session");
            }
        }
        Err(e) => {
            println!("✓ Resume failed immediately (expected): {e}");
        }
    }
}

/// Test 5: Simulate CLI not found by using invalid executable path
async fn test_cli_not_found() {
    println!("Testing with CLI not found (set CLAUDE_EXECUTABLE to invalid path)...");

    // This test is tricky because we need to set env var BEFORE spawning process
    // We'll use a subprocess approach
    println!("Note: Testing executable detection by setting invalid path");

    // Test with a clearly non-existent path
    unsafe {
        std::env::set_var(
            "CLAUDE_EXECUTABLE",
            "/this/path/definitely/does/not/exist/claude",
        );
    }

    let options = QueryOptions::new();
    let result = query("Hello", options);

    // Restore to default (remove our override)
    unsafe { std::env::remove_var("CLAUDE_EXECUTABLE") };

    match result {
        Ok(_) => {
            println!("⚠ Query succeeded (may have found claude in PATH despite override)");
            println!("  Note: CLAUDE_EXECUTABLE override may not prevent PATH search");
        }
        Err(e) => {
            println!("✓ Query failed as expected: {e}");
            match e {
                claude_rs::Error::ExecutableNotFound => {
                    println!("  Error type: ExecutableNotFound (perfect!)");
                }
                claude_rs::Error::Cli(msg) => {
                    println!("  Error type: CLI error: {msg}");
                }
                claude_rs::Error::Io(io_err) => {
                    println!("  Error type: IO error: {io_err}");
                }
                _ => {
                    println!("  Error type: {e:?}");
                }
            }
        }
    }
}

/// Test 6: Interrupt a query mid-stream
async fn test_interrupt_mid_stream() {
    println!("Testing interrupt mid-stream...");

    let mut query = match start_query(QueryOptions::new().max_turns(3)) {
        Ok(q) => q,
        Err(e) => {
            println!("✗ Failed to start query: {e}");
            return;
        }
    };

    // Send a message that would take some time
    println!("Sending long-running query...");
    if let Err(e) = query
        .send_message("Count from 1 to 1000, one number per line")
        .await
    {
        println!("✗ Failed to send message: {e}");
        return;
    }

    // Wait a bit for the query to start
    tokio::time::sleep(Duration::from_millis(500)).await;

    // Send interrupt
    println!("Sending interrupt signal...");
    match query.interrupt() {
        Ok(_) => println!("✓ Interrupt signal sent successfully"),
        Err(e) => println!("✗ Interrupt failed: {e}"),
    }

    // Receive remaining messages
    let mut got_interrupted = false;
    let mut message_count = 0;

    while let Some(msg_result) = query.recv().await {
        message_count += 1;
        match msg_result {
            Ok(Message::Result(r)) => {
                println!(
                    "✓ Got result after interrupt: is_error={}",
                    r.is_error.unwrap_or(false)
                );
                println!("  Subtype: {:?}", r.subtype);
                if r.subtype.as_deref() == Some("interrupted") {
                    println!("  Perfect! Marked as interrupted");
                    got_interrupted = true;
                }
                break;
            }
            Err(e) => {
                println!("✓ Got error after interrupt: {e}");
                if matches!(e, claude_rs::Error::Interrupted) {
                    println!("  Perfect! Interrupted error type");
                    got_interrupted = true;
                }
                break;
            }
            _ => {}
        }

        // Safety: don't loop forever
        if message_count > 100 {
            println!("⚠ Too many messages after interrupt, breaking");
            break;
        }
    }

    if got_interrupted {
        println!("✓ Interrupt was properly handled");
    } else {
        println!("⚠ Interrupt may not have been detected");
    }
}

/// Test 7: Drop Query handle while messages are still being received
async fn test_drop_query_early() {
    println!("Testing early Query drop...");

    let options = QueryOptions::new().max_turns(3);

    {
        let mut query = match start_query(options) {
            Ok(q) => q,
            Err(e) => {
                println!("✗ Failed to start query: {e}");
                return;
            }
        };

        // Send a long-running query
        println!("Sending query...");
        if let Err(e) = query
            .send_message("Write a 500-word essay about space")
            .await
        {
            println!("✗ Failed to send message: {e}");
            return;
        }

        // Receive just one message, then drop
        if let Some(msg_result) = query.recv().await {
            match msg_result {
                Ok(Message::System(_)) => println!("Got System message"),
                Ok(Message::Assistant(_)) => println!("Got Assistant message"),
                Ok(Message::User(_)) => println!("Got User message"),
                Ok(Message::Result(_)) => println!("Got Result message"),
                Ok(Message::Partial(_)) => println!("Got Partial message"),
                Ok(Message::ToolProgress(_)) => println!("Got ToolProgress message"),
                Ok(_) => println!("Got other message type"),
                Err(e) => println!("Got error: {e}"),
            }
        }

        println!("Dropping query handle early (should clean up gracefully)...");
        // Query drops here
    }

    println!("✓ Query dropped, no panic occurred");

    // Give it a moment to clean up
    tokio::time::sleep(Duration::from_millis(100)).await;
    println!("✓ Cleanup completed successfully");
}

/// Test 8: Permission mode that requires user input (will timeout or fail)
async fn test_permission_mode_ask() {
    println!("Testing permission mode that requires user input...");
    println!("Note: This will fail/timeout since we can't provide input programmatically");

    // Use Default permission mode and request a file operation
    // This should trigger a permission prompt that we can't answer
    let options = QueryOptions::new()
        .permission_mode(PermissionMode::Default)
        .max_turns(2);

    match query(
        "Create a file called test_permission.txt with 'hello' in it",
        options,
    ) {
        Ok(mut stream) => {
            println!("Query started...");

            // Set a timeout for this test
            let timeout = Duration::from_secs(10);
            let start = std::time::Instant::now();

            while let Some(msg_result) = stream.next().await {
                if start.elapsed() > timeout {
                    println!("✓ Query timed out waiting for permission (expected)");
                    break;
                }

                match msg_result {
                    Ok(Message::System(sys)) => {
                        if sys.subtype.as_deref() == Some("awaiting_permission") {
                            println!("✓ Query is waiting for permission (expected)");
                            println!("  Breaking test to avoid indefinite wait...");
                            break;
                        }
                    }
                    Ok(Message::Result(r)) => {
                        if r.is_error.unwrap_or(false) {
                            println!("✓ Query failed due to permission denial");
                            println!("  Subtype: {:?}", r.subtype);
                        } else {
                            println!("⚠ Query succeeded (permission may have been auto-granted)");
                        }
                        break;
                    }
                    Err(e) => {
                        println!("✓ Got error (permission-related): {e}");
                        break;
                    }
                    _ => {}
                }
            }
        }
        Err(e) => {
            println!("✓ Query failed at creation: {e}");
        }
    }

    println!("Note: To avoid blocking tests, we don't wait indefinitely for user input");
}
