//! Session abuse tests - trying to break session management.
//!
//! Run with: cargo run --example session_abuse
//!
//! This example attempts to:
//! 1. Create a session and immediately try to resume it (race condition)
//! 2. Resume the same session from two concurrent queries
//! 3. Fork a session multiple times rapidly
//! 4. Create 10 sessions rapidly and verify continue_last() picks the right one
//! 5. Try to resume with a malformed session ID (not a UUID)
//! 6. Try to resume with an empty string session ID
//! 7. Create a session, send many messages without waiting, then resume

use claude_rs::{Message, QueryOptions, start_query};
use std::time::Duration;
use tokio::time::sleep;

#[tokio::main]
async fn main() -> claude_rs::Result<()> {
    println!("=== Session Abuse Tests ===\n");
    println!("WARNING: This will make many API calls and may incur costs.\n");

    // Test 1: Create session and immediately resume (race condition)
    println!("--- Test 1: Immediate Resume (Race Condition) ---");
    test_immediate_resume().await;

    // Test 2: Concurrent resume of same session
    println!("\n--- Test 2: Concurrent Resume of Same Session ---");
    test_concurrent_resume().await;

    // Test 3: Rapid fork abuse
    println!("\n--- Test 3: Rapid Fork Abuse ---");
    test_rapid_fork().await;

    // Test 4: Multiple sessions and continue_last
    println!("\n--- Test 4: Multiple Sessions + Continue Last ---");
    test_multiple_sessions_continue().await;

    // Test 5: Malformed session ID
    println!("\n--- Test 5: Malformed Session ID (Not UUID) ---");
    test_malformed_session_id().await;

    // Test 6: Empty session ID
    println!("\n--- Test 6: Empty Session ID ---");
    test_empty_session_id().await;

    // Test 7: Flood messages then resume
    println!("\n--- Test 7: Flood Messages Then Resume ---");
    test_flood_then_resume().await;

    println!("\n=== Session Abuse Tests Completed ===");
    println!("If you're still reading this, congratulations! The session system survived.");
    Ok(())
}

/// Test 1: Create a session, get its ID, then immediately try to resume it
/// This tests for race conditions where the session might not be persisted yet.
async fn test_immediate_resume() {
    println!("Creating session...");
    let mut q = match start_query(QueryOptions::new().max_turns(1)) {
        Ok(q) => q,
        Err(e) => {
            println!("❌ Failed to start query: {e}");
            return;
        }
    };

    // Send message
    if let Err(e) = q.send_message("Say 'test1' and nothing else.").await {
        println!("❌ Failed to send message: {e}");
        return;
    }

    // Get session ID from first message
    let mut session_id = None;
    while let Some(msg) = q.recv().await {
        match msg {
            Ok(Message::Assistant(a)) => {
                if session_id.is_none() {
                    session_id = a.session_id.clone();
                    println!("✓ Got session ID: {session_id:?}");
                }
            }
            Ok(Message::Result(_)) => break,
            Err(e) => {
                println!("❌ Error receiving message: {e}");
                break;
            }
            _ => {}
        }
    }

    if let Some(id) = session_id {
        // Immediately try to resume (no waiting)
        println!("Immediately attempting to resume session: {id}");
        match start_query(QueryOptions::new().resume_session(&id).max_turns(1)) {
            Ok(mut q) => {
                if let Err(e) = q.send_message("What did I just say?").await {
                    println!("❌ Failed to send message to resumed session: {e}");
                } else {
                    println!("✓ Successfully resumed session immediately!");
                    // Try to get response
                    while let Some(msg) = q.recv().await {
                        if let Ok(Message::Result(r)) = msg {
                            println!("✓ Got result: {}", r.is_success());
                            break;
                        }
                    }
                }
            }
            Err(e) => {
                println!("❌ Failed to resume session immediately: {e}");
            }
        }
    } else {
        println!("❌ Could not get session ID");
    }
}

/// Test 2: Try to resume the same session from two concurrent queries
async fn test_concurrent_resume() {
    println!("Creating initial session...");
    let mut q = match start_query(QueryOptions::new().max_turns(1)) {
        Ok(q) => q,
        Err(e) => {
            println!("❌ Failed to start query: {e}");
            return;
        }
    };

    if let Err(e) = q.send_message("Remember: CODE-42").await {
        println!("❌ Failed to send message: {e}");
        return;
    }

    let mut session_id = None;
    while let Some(msg) = q.recv().await {
        match msg {
            Ok(Message::Assistant(a)) => {
                if session_id.is_none() {
                    session_id = a.session_id.clone();
                }
            }
            Ok(Message::Result(_)) => break,
            _ => {}
        }
    }

    if let Some(id) = session_id {
        println!("Session created: {id}");
        println!("Spawning two concurrent resume attempts...");

        let id1 = id.clone();
        let id2 = id.clone();

        let task1 = tokio::spawn(async move {
            match start_query(QueryOptions::new().resume_session(&id1).max_turns(1)) {
                Ok(mut q) => {
                    let _ = q.send_message("What was the code? (query 1)").await;
                    while let Some(msg) = q.recv().await {
                        if let Ok(Message::Result(_)) = msg {
                            println!("✓ Query 1 completed");
                            return true;
                        }
                    }
                }
                Err(e) => println!("❌ Query 1 failed to start: {e}"),
            }
            false
        });

        let task2 = tokio::spawn(async move {
            match start_query(QueryOptions::new().resume_session(&id2).max_turns(1)) {
                Ok(mut q) => {
                    let _ = q.send_message("What was the code? (query 2)").await;
                    while let Some(msg) = q.recv().await {
                        if let Ok(Message::Result(_)) = msg {
                            println!("✓ Query 2 completed");
                            return true;
                        }
                    }
                }
                Err(e) => println!("❌ Query 2 failed to start: {e}"),
            }
            false
        });

        let (r1, r2) = tokio::join!(task1, task2);
        println!("Concurrent resume results: task1={r1:?}, task2={r2:?}");
    } else {
        println!("❌ Could not get session ID");
    }
}

/// Test 3: Fork a session multiple times in rapid succession
async fn test_rapid_fork() {
    println!("Creating initial session...");
    let mut q = match start_query(QueryOptions::new().max_turns(1)) {
        Ok(q) => q,
        Err(e) => {
            println!("❌ Failed to start query: {e}");
            return;
        }
    };

    if let Err(e) = q.send_message("Remember: SECRET-99").await {
        println!("❌ Failed to send message: {e}");
        return;
    }

    let mut session_id = None;
    while let Some(msg) = q.recv().await {
        match msg {
            Ok(Message::Assistant(a)) => {
                if session_id.is_none() {
                    session_id = a.session_id.clone();
                }
            }
            Ok(Message::Result(_)) => break,
            _ => {}
        }
    }

    if let Some(id) = session_id {
        println!("Original session: {id}");
        println!("Creating 5 forks rapidly...");

        let mut handles = vec![];
        for i in 0..5 {
            let session_id_clone = id.clone();
            let handle = tokio::spawn(async move {
                match start_query(
                    QueryOptions::new()
                        .resume_session(&session_id_clone)
                        .fork()
                        .max_turns(1),
                ) {
                    Ok(mut q) => {
                        let _ = q.send_message(&format!("Fork {i}!")).await;
                        let mut fork_id = None;
                        while let Some(msg) = q.recv().await {
                            match msg {
                                Ok(Message::Assistant(a)) => {
                                    if fork_id.is_none() {
                                        fork_id = a.session_id.clone();
                                    }
                                }
                                Ok(Message::Result(_)) => break,
                                _ => {}
                            }
                        }
                        fork_id
                    }
                    Err(e) => {
                        println!("❌ Fork {i} failed: {e}");
                        None
                    }
                }
            });
            handles.push(handle);
        }

        let results = futures::future::join_all(handles).await;
        let fork_ids: Vec<_> = results
            .into_iter()
            .filter_map(|r| r.ok().flatten())
            .collect();

        println!("✓ Created {} forks successfully", fork_ids.len());
        for (i, fork_id) in fork_ids.iter().enumerate() {
            println!("  Fork {i}: {fork_id}");
        }
    } else {
        println!("❌ Could not get session ID");
    }
}

/// Test 4: Create 10 sessions rapidly and try continue_last() - does it pick the right one?
async fn test_multiple_sessions_continue() {
    println!("Creating 10 sessions rapidly...");

    let mut session_ids = vec![];

    for i in 0..10 {
        let mut q = match start_query(QueryOptions::new().max_turns(1)) {
            Ok(q) => q,
            Err(e) => {
                println!("❌ Session {i} failed to start: {e}");
                continue;
            }
        };

        let marker = format!("SESSION-{i}");
        if let Err(e) = q.send_message(&format!("Remember this: {marker}")).await {
            println!("❌ Session {i} failed to send: {e}");
            continue;
        }

        let mut session_id = None;
        while let Some(msg) = q.recv().await {
            match msg {
                Ok(Message::Assistant(a)) => {
                    if session_id.is_none() {
                        session_id = a.session_id.clone();
                    }
                }
                Ok(Message::Result(_)) => break,
                _ => {}
            }
        }

        if let Some(id) = session_id {
            println!("✓ Session {i} created: {id}");
            session_ids.push((i, id));
        }

        // Small delay to ensure ordering
        sleep(Duration::from_millis(50)).await;
    }

    println!("\nAttempting continue_last() - should pick the most recent session...");
    match start_query(QueryOptions::new().continue_last().max_turns(1)) {
        Ok(mut q) => {
            if let Err(e) = q
                .send_message("What was the session marker I told you?")
                .await
            {
                println!("❌ Failed to send message: {e}");
            } else {
                while let Some(msg) = q.recv().await {
                    match msg {
                        Ok(Message::Assistant(a)) => {
                            let text = a.text();
                            if !text.is_empty() {
                                println!("✓ Response: {text}");
                            }
                        }
                        Ok(Message::Result(r)) => {
                            println!("✓ Continue last completed: {}", r.is_success());
                            break;
                        }
                        _ => {}
                    }
                }
            }
        }
        Err(e) => {
            println!("❌ continue_last() failed: {e}");
        }
    }

    println!("Created {} sessions total", session_ids.len());
}

/// Test 5: Try to resume with a malformed session ID (not a UUID)
async fn test_malformed_session_id() {
    let bad_ids = vec![
        "not-a-uuid",
        "12345",
        "session-abc-xyz-123",
        "../../../../etc/passwd",
        "'; DROP TABLE sessions; --",
    ];

    for bad_id in bad_ids {
        println!("Trying malformed ID: '{bad_id}'");
        match start_query(QueryOptions::new().resume_session(bad_id).max_turns(1)) {
            Ok(mut q) => match q.send_message("Hello?").await {
                Ok(_) => {
                    println!("  ⚠️  Message sent successfully (unexpected!)");
                    while let Some(msg) = q.recv().await {
                        match msg {
                            Ok(Message::Result(_)) => {
                                println!("  ⚠️  Got result (very unexpected!)");
                                break;
                            }
                            Err(e) => {
                                println!("  ✓ Error during receive: {e}");
                                break;
                            }
                            _ => {}
                        }
                    }
                }
                Err(e) => {
                    println!("  ✓ Failed to send message: {e}");
                }
            },
            Err(e) => {
                println!("  ✓ Failed to start query (expected): {e}");
            }
        }
    }
}

/// Test 6: Try to resume with an empty string session ID
async fn test_empty_session_id() {
    println!("Trying empty session ID...");
    match start_query(QueryOptions::new().resume_session("").max_turns(1)) {
        Ok(mut q) => match q.send_message("Hello?").await {
            Ok(_) => {
                println!("  ⚠️  Message sent successfully (unexpected!)");
                while let Some(msg) = q.recv().await {
                    match msg {
                        Ok(Message::Result(_)) => {
                            println!("  ⚠️  Got result (very unexpected!)");
                            break;
                        }
                        Err(e) => {
                            println!("  ✓ Error during receive: {e}");
                            break;
                        }
                        _ => {}
                    }
                }
            }
            Err(e) => {
                println!("  ✓ Failed to send message: {e}");
            }
        },
        Err(e) => {
            println!("  ✓ Failed to start query (expected): {e}");
        }
    }
}

/// Test 7: Create a session, send many messages without waiting for responses, then try to resume
async fn test_flood_then_resume() {
    println!("Creating session and flooding with messages...");
    let mut q = match start_query(QueryOptions::new().max_turns(10)) {
        Ok(q) => q,
        Err(e) => {
            println!("❌ Failed to start query: {e}");
            return;
        }
    };

    // Send 5 messages rapidly without waiting
    println!("Sending 5 messages rapidly...");
    for i in 0..5 {
        if let Err(e) = q.send_message(&format!("Message {i}!")).await {
            println!("❌ Failed to send message {i}: {e}");
        } else {
            println!("✓ Sent message {i}");
        }
    }

    // Finish input
    if let Err(e) = q.finish_input() {
        println!("❌ Failed to finish input: {e}");
    }

    // Collect all responses and get session ID
    println!("Collecting responses...");
    let mut session_id = None;
    let mut msg_count = 0;

    while let Some(msg) = q.recv().await {
        match msg {
            Ok(Message::Assistant(a)) => {
                if session_id.is_none() {
                    session_id = a.session_id.clone();
                    println!("✓ Got session ID: {session_id:?}");
                }
                msg_count += 1;
            }
            Ok(Message::Result(r)) => {
                println!("✓ Got result: {}", r.is_success());
                break;
            }
            Err(e) => {
                println!("❌ Error: {e}");
                break;
            }
            _ => {}
        }
    }

    println!("Received {msg_count} assistant messages");

    // Now try to resume
    if let Some(id) = session_id {
        println!("Attempting to resume flooded session: {id}");
        match start_query(QueryOptions::new().resume_session(&id).max_turns(2)) {
            Ok(mut q) => {
                if let Err(e) = q.send_message("Can you still hear me?").await {
                    println!("❌ Failed to send to resumed session: {e}");
                } else {
                    println!("✓ Successfully sent message to resumed session");
                    while let Some(msg) = q.recv().await {
                        if let Ok(Message::Result(r)) = msg {
                            println!("✓ Resume after flood successful: {}", r.is_success());
                            break;
                        }
                    }
                }
            }
            Err(e) => {
                println!("❌ Failed to resume: {e}");
            }
        }
    } else {
        println!("❌ Could not get session ID from flooded session");
    }
}
