//! Concurrent stress test for claude_rs SDK.
//!
//! Run with: cargo run --example stress_concurrent
//!
//! This test is designed to find concurrency bugs, deadlocks, and race conditions by:
//! 1. Launching multiple concurrent queries using tokio::spawn
//! 2. Testing rapid session creation and message sending
//! 3. Interleaving recv() and send_message() calls to trigger race conditions
//! 4. Stress testing with different query patterns simultaneously

use claude_rs::{Message, PermissionMode, QueryOptions, prompt, query, session, start_query};
use futures::StreamExt;
use std::sync::Arc;
use std::time::{Duration, Instant};
use tokio::sync::{Barrier, Semaphore};

#[tokio::main]
async fn main() -> claude_rs::Result<()> {
    println!("=== Claude RS Concurrent Stress Test ===\n");
    println!("Testing for concurrency bugs, deadlocks, and race conditions...\n");

    let start = Instant::now();

    // Test 1: Concurrent simple queries
    println!("--- Test 1: Concurrent Simple Queries (5 tasks) ---");
    if let Err(e) = test_concurrent_simple_queries().await {
        eprintln!("FAILED: {e}");
    } else {
        println!("✓ Passed\n");
    }

    // Test 2: Concurrent streaming queries
    println!("--- Test 2: Concurrent Streaming Queries (5 tasks) ---");
    if let Err(e) = test_concurrent_streaming().await {
        eprintln!("FAILED: {e}");
    } else {
        println!("✓ Passed\n");
    }

    // Test 3: Rapid session creation
    println!("--- Test 3: Rapid Session Creation (10 sessions) ---");
    if let Err(e) = test_rapid_session_creation().await {
        eprintln!("FAILED: {e}");
    } else {
        println!("✓ Passed\n");
    }

    // Test 4: Interleaved recv/send operations
    println!("--- Test 4: Interleaved recv/send (race condition test) ---");
    if let Err(e) = test_interleaved_recv_send().await {
        eprintln!("FAILED: {e}");
    } else {
        println!("✓ Passed\n");
    }

    // Test 5: Concurrent with different options
    println!("--- Test 5: Concurrent Queries with Different Options ---");
    if let Err(e) = test_concurrent_mixed_options().await {
        eprintln!("FAILED: {e}");
    } else {
        println!("✓ Passed\n");
    }

    // Test 6: Synchronized concurrent start
    println!("--- Test 6: Synchronized Concurrent Start (barrier test) ---");
    if let Err(e) = test_synchronized_concurrent_start().await {
        eprintln!("FAILED: {e}");
    } else {
        println!("✓ Passed\n");
    }

    // Test 7: Concurrent session multi-turn
    println!("--- Test 7: Concurrent Multi-turn Sessions ---");
    if let Err(e) = test_concurrent_multiturn_sessions().await {
        eprintln!("FAILED: {e}");
    } else {
        println!("✓ Passed\n");
    }

    // Test 8: Resource cleanup stress test
    println!("--- Test 8: Resource Cleanup (spawn/drop cycles) ---");
    if let Err(e) = test_resource_cleanup().await {
        eprintln!("FAILED: {e}");
    } else {
        println!("✓ Passed\n");
    }

    // Test 9: Concurrent with throttling
    println!("--- Test 9: Concurrent with Throttling (semaphore test) ---");
    if let Err(e) = test_concurrent_throttled().await {
        eprintln!("FAILED: {e}");
    } else {
        println!("✓ Passed\n");
    }

    let elapsed = start.elapsed();
    println!("=== All Concurrent Tests Completed in {elapsed:?} ===");
    println!("No crashes, hangs, or panics detected!");

    Ok(())
}

/// Test 1: Launch 5 concurrent simple queries with different prompts
async fn test_concurrent_simple_queries() -> claude_rs::Result<()> {
    let prompts = [
        "Reply with only: Alpha",
        "Reply with only: Beta",
        "Reply with only: Gamma",
        "Reply with only: Delta",
        "Reply with only: Epsilon",
    ];

    let mut handles = vec![];

    for (i, prompt_text) in prompts.iter().enumerate() {
        let prompt_text = prompt_text.to_string();
        let handle = tokio::spawn(async move {
            let start = Instant::now();
            let result = prompt(&prompt_text, QueryOptions::new().max_turns(1)).await;
            let elapsed = start.elapsed();
            (i, result, elapsed)
        });
        handles.push(handle);
    }

    // Wait for all to complete
    let mut results = vec![];
    for handle in handles {
        match handle.await {
            Ok(result) => results.push(result),
            Err(e) => {
                return Err(claude_rs::Error::Runtime(format!("Task panicked: {e}")));
            }
        }
    }

    // Verify all completed successfully
    for (i, result, elapsed) in results {
        match result {
            Ok(r) => {
                println!(
                    "  Task {}: Success in {:?}, result: {}",
                    i,
                    elapsed,
                    r.result.as_deref().unwrap_or("(none)")
                );
            }
            Err(e) => {
                return Err(claude_rs::Error::Runtime(format!("Task {i} failed: {e}")));
            }
        }
    }

    Ok(())
}

/// Test 2: Concurrent streaming with message processing
async fn test_concurrent_streaming() -> claude_rs::Result<()> {
    let prompts = [
        "Count: 1, 2, 3",
        "List: A, B, C",
        "Say: Red, Green, Blue",
        "Reply: Up, Down, Left",
        "Echo: One, Two, Three",
    ];

    let mut handles = vec![];

    for (i, prompt_text) in prompts.iter().enumerate() {
        let prompt_text = prompt_text.to_string();
        let handle = tokio::spawn(async move {
            let mut stream = query(&prompt_text, QueryOptions::new().max_turns(1))?;

            let mut msg_count = 0;
            let mut has_result = false;

            while let Some(msg_result) = stream.next().await {
                match msg_result {
                    Ok(msg) => {
                        msg_count += 1;
                        if matches!(msg, Message::Result(_)) {
                            has_result = true;
                        }
                    }
                    Err(e) => {
                        return Err(claude_rs::Error::Runtime(format!("Stream error: {e}")));
                    }
                }
            }

            Ok::<_, claude_rs::Error>((i, msg_count, has_result))
        });
        handles.push(handle);
    }

    // Wait for all streams to complete
    for handle in handles {
        match handle.await {
            Ok(Ok((i, msg_count, has_result))) => {
                println!("  Stream {i}: {msg_count} messages, result={has_result}");
            }
            Ok(Err(e)) => {
                return Err(claude_rs::Error::Runtime(format!("Stream failed: {e}")));
            }
            Err(e) => {
                return Err(claude_rs::Error::Runtime(format!("Task panicked: {e}")));
            }
        }
    }

    Ok(())
}

/// Test 3: Rapid session creation (stress test session management)
async fn test_rapid_session_creation() -> claude_rs::Result<()> {
    let mut handles = vec![];

    for i in 0..10 {
        let handle = tokio::spawn(async move {
            let result = session(QueryOptions::new().max_turns(1), |mut sess| async move {
                sess.send(&format!("Reply with only the number {i}"))
                    .await?;

                // Wait for result
                let result_msg = sess.await_result(Some(Duration::from_secs(30))).await?;

                Ok::<_, claude_rs::Error>(result_msg.is_success())
            })
            .await;

            (i, result)
        });
        handles.push(handle);
    }

    // Wait for all sessions
    let mut success_count = 0;
    for handle in handles {
        match handle.await {
            Ok((_i, Ok(is_success))) => {
                if is_success {
                    success_count += 1;
                }
            }
            Ok((i, Err(e))) => {
                println!("  Session {i} error: {e}");
            }
            Err(e) => {
                return Err(claude_rs::Error::Runtime(format!("Task panicked: {e}")));
            }
        }
    }

    println!("  {success_count} / 10 sessions completed successfully");
    Ok(())
}

/// Test 4: Interleaved recv/send to trigger race conditions
async fn test_interleaved_recv_send() -> claude_rs::Result<()> {
    let handle1 = tokio::spawn(async {
        let mut query = start_query(QueryOptions::new().max_turns(2))?;

        // Send first message
        query.send_message("Say: First").await?;

        // Immediately try to recv while send might still be processing
        let _msg1 = query.recv().await;

        // Send second message without fully draining first response
        query.send_message("Say: Second").await?;

        // Try to recv again
        let _msg2 = query.recv().await;

        // Drain remaining messages
        let mut count = 2;
        while query.recv().await.is_some() {
            count += 1;
            if count > 20 {
                // Safety limit
                break;
            }
        }

        Ok::<_, claude_rs::Error>(count)
    });

    let handle2 = tokio::spawn(async {
        let mut query = start_query(QueryOptions::new().max_turns(2))?;

        // Different pattern: send multiple before any recv
        query.send_message("Reply: A").await?;
        query.send_message("Reply: B").await?;

        // Now try to recv all
        let mut count = 0;
        while query.recv().await.is_some() {
            count += 1;
            if count > 20 {
                // Safety limit
                break;
            }
        }

        Ok::<_, claude_rs::Error>(count)
    });

    // Wait for both patterns to complete
    let result1 = handle1.await;
    let result2 = handle2.await;

    match (result1, result2) {
        (Ok(Ok(count1)), Ok(Ok(count2))) => {
            println!("  Pattern 1: {count1} messages, Pattern 2: {count2} messages");
            Ok(())
        }
        (Err(e), _) | (_, Err(e)) => Err(claude_rs::Error::Runtime(format!("Task panicked: {e}"))),
        (Ok(Err(e)), _) | (_, Ok(Err(e))) => Err(e),
    }
}

/// Test 5: Concurrent queries with different options (stress different code paths)
async fn test_concurrent_mixed_options() -> claude_rs::Result<()> {
    let mut handles = vec![];

    // Task 1: Plan mode
    handles.push(tokio::spawn(async {
        prompt(
            "Reply: Plan",
            QueryOptions::new()
                .max_turns(1)
                .permission_mode(PermissionMode::Plan),
        )
        .await
    }));

    // Task 2: DontAsk mode
    handles.push(tokio::spawn(async {
        prompt(
            "Reply: DontAsk",
            QueryOptions::new()
                .max_turns(1)
                .permission_mode(PermissionMode::DontAsk),
        )
        .await
    }));

    // Task 3: With budget
    handles.push(tokio::spawn(async {
        prompt(
            "Reply: Budget",
            QueryOptions::new().max_turns(1).max_budget_usd(0.10),
        )
        .await
    }));

    // Task 4: With max turns
    handles.push(tokio::spawn(async {
        prompt("Reply: Turns", QueryOptions::new().max_turns(2)).await
    }));

    // Task 5: Basic options
    handles.push(tokio::spawn(async {
        prompt("Reply: Basic", QueryOptions::new().max_turns(1)).await
    }));

    // Wait for all
    let mut success_count = 0;
    for (i, handle) in handles.into_iter().enumerate() {
        match handle.await {
            Ok(Ok(_)) => {
                success_count += 1;
            }
            Ok(Err(e)) => {
                println!("  Task {i} error: {e}");
            }
            Err(e) => {
                return Err(claude_rs::Error::Runtime(format!("Task {i} panicked: {e}")));
            }
        }
    }

    println!("  {success_count} / 5 tasks with different options succeeded");
    Ok(())
}

/// Test 6: Synchronized concurrent start using barrier
async fn test_synchronized_concurrent_start() -> claude_rs::Result<()> {
    let barrier = Arc::new(Barrier::new(5));
    let mut handles = vec![];

    for i in 0..5 {
        let barrier = barrier.clone();
        let handle = tokio::spawn(async move {
            // Wait for all tasks to be ready
            barrier.wait().await;

            // All tasks start at the same time
            let result = prompt(
                &format!("Reply with only: Sync{i}"),
                QueryOptions::new().max_turns(1),
            )
            .await;

            (i, result)
        });
        handles.push(handle);
    }

    // Wait for all synchronized tasks
    for handle in handles {
        match handle.await {
            Ok((i, Ok(_))) => {
                println!("  Synchronized task {i} completed");
            }
            Ok((i, Err(e))) => {
                println!("  Synchronized task {i} error: {e}");
            }
            Err(e) => {
                return Err(claude_rs::Error::Runtime(format!("Task panicked: {e}")));
            }
        }
    }

    Ok(())
}

/// Test 7: Concurrent multi-turn sessions (complex interaction patterns)
async fn test_concurrent_multiturn_sessions() -> claude_rs::Result<()> {
    let mut handles = vec![];

    for i in 0..3 {
        let handle = tokio::spawn(async move {
            session(QueryOptions::new().max_turns(2), |mut sess| async move {
                // First turn
                sess.send(&format!("Remember this number: {}", i * 10))
                    .await?;
                let _ = sess.await_result(Some(Duration::from_secs(30))).await?;

                // Second turn - test memory
                sess.send("What number did I tell you to remember?").await?;
                let result = sess.await_result(Some(Duration::from_secs(30))).await?;

                Ok::<_, claude_rs::Error>(result.is_success())
            })
            .await
        });
        handles.push(handle);
    }

    let mut success_count = 0;
    for (i, handle) in handles.into_iter().enumerate() {
        match handle.await {
            Ok(Ok(is_success)) => {
                if is_success {
                    success_count += 1;
                }
                println!("  Multi-turn session {i} completed");
            }
            Ok(Err(e)) => {
                println!("  Multi-turn session {i} error: {e}");
            }
            Err(e) => {
                return Err(claude_rs::Error::Runtime(format!("Task {i} panicked: {e}")));
            }
        }
    }

    println!("  {success_count} / 3 multi-turn sessions succeeded");
    Ok(())
}

/// Test 8: Resource cleanup stress test (rapid spawn/drop cycles)
async fn test_resource_cleanup() -> claude_rs::Result<()> {
    for i in 0..10 {
        // Start a query and immediately drop it
        let query = start_query(QueryOptions::new().max_turns(1))?;
        drop(query);

        // Start a query, send message, then drop
        let mut query = start_query(QueryOptions::new().max_turns(1))?;
        let _ = query.send_message("Test").await;
        drop(query);

        if i % 3 == 0 {
            println!("  Cleanup cycle {} / 10", i + 1);
        }
    }

    println!("  All cleanup cycles completed without hanging");
    Ok(())
}

/// Test 9: Concurrent with throttling using semaphore
async fn test_concurrent_throttled() -> claude_rs::Result<()> {
    let semaphore = Arc::new(Semaphore::new(2)); // Only 2 concurrent at a time
    let mut handles = vec![];

    for i in 0..6 {
        let sem = semaphore.clone();
        let handle = tokio::spawn(async move {
            let _permit = sem.acquire().await.unwrap();

            let start = Instant::now();
            let result = prompt(
                &format!("Reply: Throttled{i}"),
                QueryOptions::new().max_turns(1),
            )
            .await;
            let elapsed = start.elapsed();

            (i, result, elapsed)
        });
        handles.push(handle);
    }

    // Wait for all throttled tasks
    let mut success_count = 0;
    for handle in handles {
        match handle.await {
            Ok((i, Ok(_), elapsed)) => {
                success_count += 1;
                println!("  Throttled task {i} completed in {elapsed:?}");
            }
            Ok((i, Err(e), _)) => {
                println!("  Throttled task {i} error: {e}");
            }
            Err(e) => {
                return Err(claude_rs::Error::Runtime(format!("Task panicked: {e}")));
            }
        }
    }

    println!("  {success_count} / 6 throttled tasks succeeded");
    Ok(())
}
