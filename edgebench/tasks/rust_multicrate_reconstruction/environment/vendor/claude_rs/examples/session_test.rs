//! Session tests - test resume and continue functionality.
//!
//! Run with: cargo run --example session_test

use claude_rs::{Message, QueryOptions, start_query};

#[tokio::main]
async fn main() -> claude_rs::Result<()> {
    println!("=== Session Tests ===\n");

    // Test 1: Create a session and get its ID
    println!("--- Test 1: Get Session ID ---");
    let session_id = test_get_session_id().await;

    // Test 2: Resume that session
    if let Some(id) = session_id {
        println!("\n--- Test 2: Resume Session ---");
        test_resume_session(&id).await;
    }

    // Test 3: Continue last session
    println!("\n--- Test 3: Continue Last Session ---");
    test_continue_session().await;

    // Test 4: Fork a session
    println!("\n--- Test 4: Fork Session ---");
    test_fork_session().await;

    println!("\n=== Session Tests Completed ===");
    Ok(())
}

async fn test_get_session_id() -> Option<String> {
    // Use start_query (streaming mode) instead of query (one-shot mode)
    // because one-shot mode sessions are NOT persisted to disk
    let mut q = match start_query(QueryOptions::new().max_turns(1)) {
        Ok(q) => q,
        Err(e) => {
            println!("Error: {e}");
            return None;
        }
    };

    // Send the message
    if let Err(e) = q
        .send_message("Remember this secret code: ALPHA-7. Reply with 'Code stored.'")
        .await
    {
        println!("Error sending message: {e}");
        return None;
    }

    let mut session_id = None;

    while let Some(msg) = q.recv().await {
        match msg {
            Ok(Message::Assistant(a)) => {
                // Session ID comes on assistant/result messages, not system
                if session_id.is_none() {
                    session_id = a.session_id.clone();
                    println!("Session ID: {session_id:?}");
                }
            }
            Ok(Message::Result(r)) => {
                // Also check result message for session_id
                if session_id.is_none() {
                    session_id = r.session_id.clone();
                    println!("Session ID (from result): {session_id:?}");
                }
                println!("Result: {}", r.result.as_deref().unwrap_or("(none)"));
                break;
            }
            Ok(_) => {}
            Err(e) => {
                println!("Error: {e}");
                break;
            }
        }
    }

    session_id
}

async fn test_resume_session(session_id: &str) {
    println!("Resuming session: {session_id}");

    let mut q = match start_query(QueryOptions::new().resume_session(session_id).max_turns(2)) {
        Ok(q) => q,
        Err(e) => {
            println!("Error starting resume: {e}");
            return;
        }
    };

    // Ask about the secret code
    println!("Sending message...");
    if let Err(e) = q
        .send_message("What was the secret code I told you? Reply with just the code.")
        .await
    {
        println!("Error sending message: {e}");
        return;
    }
    println!("Message sent, waiting for response...");

    let mut msg_count = 0;
    while let Some(msg) = q.recv().await {
        msg_count += 1;
        match msg {
            Ok(Message::Assistant(a)) => {
                let text = a.text();
                println!("Assistant message #{msg_count}: '{text}'");
            }
            Ok(Message::Result(r)) => {
                println!(
                    "Result #{}: success={}, result={:?}",
                    msg_count,
                    r.is_success(),
                    r.result
                );
                break;
            }
            Ok(other) => {
                println!(
                    "Other message #{}: {:?}",
                    msg_count,
                    std::mem::discriminant(&other)
                );
            }
            Err(e) => {
                println!("Error #{msg_count}: {e}");
                break;
            }
        }
    }
    println!("Received {msg_count} messages total");
}

async fn test_continue_session() {
    // First, create a session using streaming mode (persists to disk)
    let mut q = match start_query(QueryOptions::new().max_turns(1)) {
        Ok(q) => q,
        Err(e) => {
            println!("Error creating first session: {e}");
            return;
        }
    };

    if let Err(e) = q
        .send_message("Remember: my lucky number is 777. Reply with 'Noted.'")
        .await
    {
        println!("Error sending message: {e}");
        return;
    }

    while let Some(msg) = q.recv().await {
        if let Ok(Message::Result(r)) = msg {
            println!("First query done: {}", r.result.as_deref().unwrap_or(""));
            break;
        }
    }

    // Drop the query handle
    drop(q);

    // Now continue the session
    let mut q = match start_query(QueryOptions::new().continue_last().max_turns(2)) {
        Ok(q) => q,
        Err(e) => {
            println!("Error continuing session: {e}");
            return;
        }
    };

    if let Err(e) = q
        .send_message("What is my lucky number? Reply with just the number.")
        .await
    {
        println!("Error sending message: {e}");
        return;
    }

    while let Some(msg) = q.recv().await {
        match msg {
            Ok(Message::Assistant(a)) => {
                let text = a.text();
                if !text.is_empty() {
                    println!("Continued response: {text}");
                }
            }
            Ok(Message::Result(r)) => {
                println!("Success: {}", r.is_success());
                break;
            }
            Ok(_) => {}
            Err(e) => {
                println!("Error: {e}");
                break;
            }
        }
    }
}

async fn test_fork_session() {
    // Create initial session using streaming mode (persists to disk)
    let mut q = match start_query(QueryOptions::new().max_turns(1)) {
        Ok(q) => q,
        Err(e) => {
            println!("Error: {e}");
            return;
        }
    };

    if let Err(e) = q
        .send_message("Remember: the password is 'sunshine'. Reply 'OK'.")
        .await
    {
        println!("Error: {e}");
        return;
    }

    let mut original_session_id = None;
    while let Some(msg) = q.recv().await {
        match msg {
            Ok(Message::Assistant(a)) => {
                if original_session_id.is_none() {
                    original_session_id = a.session_id.clone();
                }
            }
            Ok(Message::Result(r)) => {
                if original_session_id.is_none() {
                    original_session_id = r.session_id.clone();
                }
                println!("Initial response done");
                break;
            }
            _ => {}
        }
    }

    let session_id = match original_session_id {
        Some(id) => id,
        None => {
            println!("No session ID found");
            return;
        }
    };

    println!("Original session: {session_id}");

    // Fork the session
    let mut q = match start_query(
        QueryOptions::new()
            .resume_session(&session_id)
            .fork()
            .max_turns(2),
    ) {
        Ok(q) => q,
        Err(e) => {
            println!("Error forking: {e}");
            return;
        }
    };

    if let Err(e) = q
        .send_message("What was the password? Reply with just the password.")
        .await
    {
        println!("Error: {e}");
        return;
    }

    let mut forked_session_id = None;
    while let Some(msg) = q.recv().await {
        match msg {
            Ok(Message::Assistant(a)) => {
                if forked_session_id.is_none() {
                    forked_session_id = a.session_id.clone();
                }
                let text = a.text();
                if !text.is_empty() {
                    println!("Forked response: {text}");
                }
            }
            Ok(Message::Result(r)) => {
                if forked_session_id.is_none() {
                    forked_session_id = r.session_id.clone();
                }
                println!("Success: {}", r.is_success());
                break;
            }
            _ => {}
        }
    }

    if let Some(forked_id) = forked_session_id {
        println!("Forked session ID: {forked_id}");
        println!("IDs different: {}", forked_id != session_id);
    }
}
