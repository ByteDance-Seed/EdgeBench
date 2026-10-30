//! Resource exhaustion test - stress test memory, channels, and resource limits.
//!
//! # Usage
//!
//! ```bash
//! # Run the tests
//! cargo run --example resource_exhaust
//!
//! # Monitor execution time and resource usage
//! time cargo run --example resource_exhaust
//!
//! # Monitor memory usage (macOS)
//! # In another terminal while tests run:
//! while true; do ps aux | grep resource_exhaust | grep -v grep; sleep 1; done
//! ```
//!
//! # What This Tests
//!
//! 1. **Large Message (1MB+)** - Tests if the SDK can handle very large prompts
//!    without crashing or hanging. Verifies proper buffer handling.
//!
//! 2. **Multiple Query Handles** - Creates many Query handles simultaneously
//!    without dropping them. Detects memory leaks in handle management.
//!
//! 3. **Tight recv() Loop** - Calls recv() in a tight loop to verify proper
//!    async yielding behavior. A busy loop would cause 100% CPU usage.
//!
//! 4. **Many Turns** - Tests max_turns=1000 to ensure high limits don't cause
//!    issues in configuration or validation.
//!
//! 5. **Rapid Message Sending** - Sends multiple messages as fast as possible
//!    to test stdin buffer handling and backpressure.
//!
//! 6. **Channel Buffer Saturation** - Starts a query but delays reading messages,
//!    allowing the internal channel buffer to fill. Tests backpressure.
//!
//! 7. **CLI Stdout Buffer** - Requests large output from CLI and reads slowly
//!    to test if the CLI process blocks properly on full buffers.
//!
//! 8. **Abandoned Streams** - Creates streams and immediately drops them without
//!    reading any messages. Tests cleanup and resource leak prevention.
//!
//! # Expected Behavior
//!
//! - All tests should complete without panics or hangs
//! - Memory usage should be reasonable (< 500MB)
//! - No zombie processes should remain after completion
//! - Total execution time should be under 5 minutes
//!
//! # Signs of Problems
//!
//! - ✗ markers in output indicate failures
//! - Hangs or timeouts suggest deadlocks
//! - Excessive memory growth suggests leaks
//! - High CPU during waiting suggests busy loops

use claude_rs::{Message, QueryOptions, query, start_query};
use futures::StreamExt;
use std::time::{Duration, Instant};

#[tokio::main]
async fn main() -> claude_rs::Result<()> {
    println!("=== Resource Exhaustion Tests ===");
    println!("Testing memory leaks, buffer overflows, and resource limits\n");

    // Test 1: Very large message
    println!("--- Test 1: Large Message (1MB+) ---");
    test_large_message().await;

    // Test 2: Multiple Query handles (memory leak detection)
    println!("\n--- Test 2: Multiple Query Handles ---");
    test_multiple_handles().await;

    // Test 3: Tight recv() loop
    println!("\n--- Test 3: Tight recv() Loop ---");
    test_tight_recv_loop().await;

    // Test 4: Many turns
    println!("\n--- Test 4: Many Turns (max_turns=1000) ---");
    test_many_turns().await;

    // Test 5: Send messages faster than CLI processes
    println!("\n--- Test 5: Rapid Message Sending ---");
    test_rapid_sending().await;

    // Test 6: Don't read messages, let channel buffer fill
    println!("\n--- Test 6: Channel Buffer Saturation ---");
    test_channel_buffer_saturation().await;

    // Test 7: Stdout buffer from CLI
    println!("\n--- Test 7: CLI Stdout Buffer Test ---");
    test_cli_stdout_buffer().await;

    // Test 8: Create streams and abandon them (drop without reading)
    println!("\n--- Test 8: Abandoned Streams ---");
    test_abandoned_streams().await;

    println!("\n=== All Resource Tests Completed ===");
    println!("\nNote: Monitor system resources with:");
    println!("  - macOS: Activity Monitor or 'top'");
    println!("  - Linux: 'top' or 'htop'");
    println!("  - Memory leaks: run with 'valgrind' or instruments");
    Ok(())
}

/// Test 1: Send a very large message (1MB+ of text)
async fn test_large_message() {
    let start = Instant::now();

    // Create a 1MB+ message
    let large_text: String = (0..50_000)
        .map(|i| format!("Line {i}: This is some filler text to make the message large. "))
        .collect();

    println!(
        "Created message of {} bytes ({:.2} MB)",
        large_text.len(),
        large_text.len() as f64 / 1_048_576.0
    );

    let prompt = format!(
        "I'm sending you a large message. Just reply with 'Received' and the approximate size. Here it is:\n\n{large_text}"
    );

    match query(&prompt, QueryOptions::new().max_turns(1)) {
        Ok(mut stream) => {
            let mut received_result = false;
            let mut message_count = 0;
            while let Some(msg_result) = stream.next().await {
                message_count += 1;
                match msg_result {
                    Ok(Message::System(_)) => {
                        println!("  Received system message");
                    }
                    Ok(Message::Assistant(a)) => {
                        let text = a.text();
                        if !text.is_empty() {
                            println!("  Received assistant message ({} chars)", text.len());
                        }
                    }
                    Ok(Message::Result(r)) => {
                        received_result = true;
                        println!("Result: success={}", r.is_success());
                        if let Some(result_text) = &r.result {
                            println!(
                                "Response: {}",
                                result_text.chars().take(100).collect::<String>()
                            );
                        }
                    }
                    Ok(_) => {
                        println!("  Received other message");
                    }
                    Err(e) => {
                        println!("Error: {e}");
                        break;
                    }
                }
            }
            if received_result {
                println!("✓ Large message handled successfully ({message_count} messages)");
            } else {
                println!("✗ No result received (got {message_count} messages)");
            }
        }
        Err(e) => {
            println!("✗ Failed to create query: {e}");
        }
    }

    println!("Completed in {:?}", start.elapsed());
}

/// Test 2: Create many Query handles without dropping them
async fn test_multiple_handles() {
    let start = Instant::now();
    let mut handles = Vec::new();

    println!("Creating 10 Query handles...");

    for i in 0..10 {
        match start_query(QueryOptions::new().max_turns(1)) {
            Ok(query) => {
                handles.push(query);
                println!("  Created handle {}", i + 1);
            }
            Err(e) => {
                println!("  Failed to create handle {}: {}", i + 1, e);
                break;
            }
        }
    }

    println!("Created {} handles", handles.len());
    println!(
        "Memory pressure check: handles alive for {} handles",
        handles.len()
    );

    // Keep handles alive for a moment
    tokio::time::sleep(Duration::from_millis(500)).await;

    // Now explicitly drop them
    drop(handles);
    println!("✓ All handles dropped");

    println!("Completed in {:?}", start.elapsed());
}

/// Test 3: Call recv() in a tight loop without yielding
async fn test_tight_recv_loop() {
    let start = Instant::now();

    let mut query = match start_query(QueryOptions::new().max_turns(2)) {
        Ok(q) => q,
        Err(e) => {
            println!("✗ Failed to create query: {e}");
            return;
        }
    };

    // Send a message
    if let Err(e) = query
        .send_message("Count from 1 to 5. Reply briefly.")
        .await
    {
        println!("✗ Failed to send message: {e}");
        return;
    }

    println!("Calling recv() in tight loop...");
    let mut count = 0;
    let mut iterations = 0;

    loop {
        iterations += 1;
        match query.recv().await {
            Some(Ok(msg)) => {
                count += 1;
                if matches!(msg, Message::Result(_)) {
                    println!("✓ Received result message");
                    break;
                }
            }
            Some(Err(e)) => {
                println!("✗ Error: {e}");
                break;
            }
            None => {
                println!("✓ Stream ended");
                break;
            }
        }

        // Check if we're blocked/yielding properly
        if iterations > 10000 {
            println!("✗ Too many iterations without messages - possible busy loop");
            break;
        }
    }

    println!("Received {count} messages in {iterations} iterations");
    println!("Completed in {:?}", start.elapsed());
}

/// Test 4: Test with max_turns=1000
async fn test_many_turns() {
    let start = Instant::now();

    println!("Starting query with max_turns=1000...");

    // This won't actually do 1000 turns, but tests if the CLI/SDK handles it
    let mut stream = match query(
        "Reply with 'OK'. This is just a simple test.",
        QueryOptions::new().max_turns(1000),
    ) {
        Ok(s) => s,
        Err(e) => {
            println!("✗ Failed to create query: {e}");
            return;
        }
    };

    while let Some(msg_result) = stream.next().await {
        match msg_result {
            Ok(Message::Result(r)) => {
                let turns = r.num_turns.unwrap_or(0);
                println!("Result: success={}, turns={}", r.is_success(), turns);
                println!("✓ High max_turns handled correctly");
                break;
            }
            Ok(_) => {}
            Err(e) => {
                println!("✗ Error: {e}");
                break;
            }
        }
    }

    println!("Completed in {:?}", start.elapsed());
}

/// Test 5: Send messages faster than the CLI can process them
async fn test_rapid_sending() {
    let start = Instant::now();

    let mut query = match start_query(QueryOptions::new().max_turns(5)) {
        Ok(q) => q,
        Err(e) => {
            println!("✗ Failed to create query: {e}");
            return;
        }
    };

    println!("Sending 5 messages rapidly...");

    // Send messages as fast as possible
    for i in 1..=5 {
        match query
            .send_message(&format!("Message {i}: Just reply OK"))
            .await
        {
            Ok(_) => println!("  Sent message {i}"),
            Err(e) => {
                println!("  ✗ Failed to send message {i}: {e}");
                break;
            }
        }
        // No delay - send immediately
    }

    // Finish input
    if let Err(e) = query.finish_input() {
        println!("✗ Failed to finish input: {e}");
        return;
    }

    // Now receive all responses
    let mut message_count = 0;
    while let Some(msg_result) = query.recv().await {
        match msg_result {
            Ok(msg) => {
                message_count += 1;
                if matches!(msg, Message::Result(_)) {
                    println!("✓ Received result after {message_count} messages");
                    break;
                }
            }
            Err(e) => {
                println!("✗ Error receiving: {e}");
                break;
            }
        }
    }

    println!("Completed in {:?}", start.elapsed());
}

/// Test 6: Create a query, don't read any messages, let the channel buffer fill up
async fn test_channel_buffer_saturation() {
    let start = Instant::now();

    println!("Creating query without reading messages...");

    // Start a query that will generate output
    let mut stream = match query(
        "List numbers from 1 to 100, one per line",
        QueryOptions::new().max_turns(1),
    ) {
        Ok(s) => s,
        Err(e) => {
            println!("✗ Failed to create query: {e}");
            return;
        }
    };

    println!("Waiting 2 seconds without reading messages...");
    tokio::time::sleep(Duration::from_secs(2)).await;

    println!("Now draining messages...");
    let mut count = 0;
    while let Some(msg_result) = stream.next().await {
        match msg_result {
            Ok(msg) => {
                count += 1;
                if matches!(msg, Message::Result(_)) {
                    println!("✓ Received result after {count} messages");
                    break;
                }
            }
            Err(e) => {
                println!("✗ Error: {e}");
                break;
            }
        }
    }

    println!("✓ Channel buffer saturation test completed, received {count} messages");
    println!("Completed in {:?}", start.elapsed());
}

/// Test 7: Test what happens when stdout buffer from CLI fills up
async fn test_cli_stdout_buffer() {
    let start = Instant::now();

    println!("Requesting CLI to generate large output...");

    // Ask for a large amount of output
    let mut stream = match query(
        "Generate a list of 1000 random words. Just make up words, one per line.",
        QueryOptions::new().max_turns(1),
    ) {
        Ok(s) => s,
        Err(e) => {
            println!("✗ Failed to create query: {e}");
            return;
        }
    };

    // Read slowly to test backpressure
    println!("Reading messages slowly to test backpressure...");
    let mut count = 0;
    let mut assistant_messages = 0;

    while let Some(msg_result) = stream.next().await {
        match msg_result {
            Ok(msg) => {
                count += 1;
                if matches!(msg, Message::Assistant(_)) {
                    assistant_messages += 1;
                    // Slow down reading every 10 messages
                    if assistant_messages % 10 == 0 {
                        tokio::time::sleep(Duration::from_millis(50)).await;
                    }
                }
                if matches!(msg, Message::Result(_)) {
                    println!("✓ Completed with {count} total messages");
                    break;
                }
            }
            Err(e) => {
                println!("✗ Error: {e}");
                break;
            }
        }
    }

    println!("✓ CLI stdout buffer test completed");
    println!("Completed in {:?}", start.elapsed());
}

/// Test 8: Create streams and abandon them (drop without reading)
async fn test_abandoned_streams() {
    let start = Instant::now();

    println!("Creating 5 streams and dropping them without reading...");

    for i in 1..=5 {
        match query("Hello, this is a test", QueryOptions::new().max_turns(1)) {
            Ok(stream) => {
                println!("  Created stream {i}");
                // Immediately drop without reading
                drop(stream);
                println!("  Dropped stream {i}");
            }
            Err(e) => {
                println!("  ✗ Failed to create stream {i}: {e}");
            }
        }
        // Small delay between creations
        tokio::time::sleep(Duration::from_millis(100)).await;
    }

    println!("✓ All streams created and abandoned");
    println!("Waiting 1 second for cleanup...");
    tokio::time::sleep(Duration::from_secs(1)).await;

    println!("✓ Abandoned streams test completed");
    println!("Completed in {:?}", start.elapsed());
}
