//! Edge case tests - try to break the SDK.
//!
//! Run with: cargo run --example edge_test

use claude_rs::{Message, PermissionMode, QueryOptions, query, start_query};
use futures::StreamExt;
use std::time::Duration;

#[tokio::main]
async fn main() -> claude_rs::Result<()> {
    println!("=== Edge Case Tests ===\n");

    // Test 1: Query that triggers tool use
    println!("--- Test 1: Tool Use Query ---");
    test_tool_use().await;

    // Test 2: Query with max_turns=0
    println!("\n--- Test 2: Zero Max Turns ---");
    test_zero_turns().await;

    // Test 3: Very restrictive budget
    println!("\n--- Test 3: Tiny Budget ---");
    test_tiny_budget().await;

    // Test 4: Multiple streams concurrently
    println!("\n--- Test 4: Concurrent Streams ---");
    test_concurrent().await;

    // Test 5: Interrupt a query
    println!("\n--- Test 5: Query Interrupt ---");
    test_interrupt().await;

    // Test 6: Send message without finishing
    println!("\n--- Test 6: Streaming Input Mode ---");
    test_streaming_input().await;

    // Test 7: Long prompt
    println!("\n--- Test 7: Long Prompt ---");
    test_long_prompt().await;

    println!("\n=== Edge Tests Completed ===");
    Ok(())
}

async fn test_tool_use() {
    // This should trigger Bash or Read tool use
    let mut stream = match query(
        "What files are in the current directory? Use the Glob tool to check.",
        QueryOptions::new()
            .max_turns(3)
            .permission_mode(PermissionMode::AcceptEdits),
    ) {
        Ok(s) => s,
        Err(e) => {
            println!("Error starting query: {e}");
            return;
        }
    };

    let mut tool_uses = 0;
    while let Some(msg_result) = stream.next().await {
        match msg_result {
            Ok(msg) => match &msg {
                Message::Assistant(a) => {
                    // Check for tool use
                    if let Some(msg_content) = &a.message
                        && let Some(content) = &msg_content.content
                    {
                        for block in content {
                            if let claude_rs::message::ContentBlock::ToolUse(tu) = block {
                                tool_uses += 1;
                                println!("Tool use: {} (id: {})", tu.name, tu.id);
                            }
                        }
                    }
                }
                Message::User(u) => {
                    // Tool result
                    if let Some(msg_content) = &u.message
                        && let Some(content) = &msg_content.content
                    {
                        println!("Tool result received ({} blocks)", content.len());
                    }
                }
                Message::Result(r) => {
                    println!(
                        "Result: success={}, tools_used={}",
                        r.is_success(),
                        tool_uses
                    );
                }
                _ => {}
            },
            Err(e) => {
                println!("Stream error: {e}");
                break;
            }
        }
    }
}

async fn test_zero_turns() {
    let result = query("Hello", QueryOptions::new().max_turns(0));

    match result {
        Ok(mut stream) => {
            while let Some(msg) = stream.next().await {
                match msg {
                    Ok(Message::Result(r)) => {
                        println!("Result: is_error={}", r.is_error.unwrap_or(false));
                        println!("Subtype: {:?}", r.subtype);
                    }
                    Ok(_) => {}
                    Err(e) => println!("Error: {e}"),
                }
            }
        }
        Err(e) => println!("Query error: {e}"),
    }
}

async fn test_tiny_budget() {
    let result = query(
        "Write a 100-word essay about the moon",
        QueryOptions::new().max_budget_usd(0.0001),
    );

    match result {
        Ok(mut stream) => {
            while let Some(msg) = stream.next().await {
                match msg {
                    Ok(Message::Result(r)) => {
                        println!("Result: success={}", r.is_success());
                        println!("Subtype: {:?}", r.subtype);
                        println!("Cost: ${:.6}", r.total_cost_usd.unwrap_or(0.0));
                    }
                    Ok(_) => {}
                    Err(e) => println!("Error: {e}"),
                }
            }
        }
        Err(e) => println!("Query error: {e}"),
    }
}

async fn test_concurrent() {
    let queries = vec!["What is 1+1?", "What is 2+2?", "What is 3+3?"];

    let handles: Vec<_> = queries
        .into_iter()
        .map(|q| {
            tokio::spawn(async move {
                let mut stream = query(q, QueryOptions::new().max_turns(1)).ok()?;
                while let Some(msg) = stream.next().await {
                    if let Ok(Message::Result(r)) = msg {
                        return Some(r.result.unwrap_or_default());
                    }
                }
                None
            })
        })
        .collect();

    for (i, h) in handles.into_iter().enumerate() {
        match h.await {
            Ok(Some(result)) => println!("Query {}: {}", i + 1, result.trim()),
            Ok(None) => println!("Query {}: no result", i + 1),
            Err(e) => println!("Query {}: join error: {}", i + 1, e),
        }
    }
}

async fn test_interrupt() {
    let mut q = match start_query(QueryOptions::new().max_turns(5)) {
        Ok(q) => q,
        Err(e) => {
            println!("Error starting query: {e}");
            return;
        }
    };

    // Send a message that would take a while
    if let Err(e) = q
        .send_message("Count from 1 to 100, very slowly, one number per line")
        .await
    {
        println!("Error sending message: {e}");
        return;
    }

    // Wait a bit then interrupt
    tokio::time::sleep(Duration::from_millis(500)).await;

    match q.interrupt() {
        Ok(_) => println!("Interrupt sent"),
        Err(e) => println!("Interrupt error: {e}"),
    }

    // Try to receive remaining messages
    let mut count = 0;
    while let Some(msg) = q.recv().await {
        count += 1;
        if let Ok(Message::Result(r)) = msg {
            println!("Result after interrupt: success={}", r.is_success());
            break;
        }
    }
    println!("Received {count} messages after interrupt");
}

async fn test_streaming_input() {
    let mut q = match start_query(QueryOptions::new().max_turns(2)) {
        Ok(q) => q,
        Err(e) => {
            println!("Error starting query: {e}");
            return;
        }
    };

    // Send first message
    if let Err(e) = q.send_message("Remember: X=42. Reply with 'OK'.").await {
        println!("Error sending message: {e}");
        return;
    }

    // Receive response
    let mut got_response = false;
    while let Some(msg) = q.recv().await {
        match msg {
            Ok(Message::Assistant(a)) => {
                let text = a.text();
                if !text.is_empty() {
                    println!("Response 1: {text}");
                    got_response = true;
                }
            }
            Ok(Message::Result(_)) => break,
            _ => {}
        }
    }

    if !got_response {
        println!("No response received for first message");
    }

    // Send second message
    if let Err(e) = q
        .send_message("What is X? Reply with just the number.")
        .await
    {
        println!("Error sending second message: {e}");
        return;
    }

    // Receive second response
    while let Some(msg) = q.recv().await {
        match msg {
            Ok(Message::Assistant(a)) => {
                let text = a.text();
                if !text.is_empty() {
                    println!("Response 2: {text}");
                }
            }
            Ok(Message::Result(r)) => {
                println!("Final result: success={}", r.is_success());
                break;
            }
            _ => {}
        }
    }
}

async fn test_long_prompt() {
    // Create a prompt that's ~10KB
    let long_text: String = (0..500)
        .map(|i| format!("This is sentence number {i}. "))
        .collect();

    let prompt = format!(
        "I'm going to give you a lot of text. Just reply with 'Received'. Here it is: {long_text}"
    );

    println!("Prompt length: {} chars", prompt.len());

    let mut stream = match query(&prompt, QueryOptions::new().max_turns(1)) {
        Ok(s) => s,
        Err(e) => {
            println!("Error starting query: {e}");
            return;
        }
    };

    while let Some(msg) = stream.next().await {
        match msg {
            Ok(Message::Result(r)) => {
                println!("Result: success={}", r.is_success());
                println!(
                    "Response: {}",
                    r.result.as_deref().unwrap_or("(none)").trim()
                );
            }
            Err(e) => {
                println!("Error: {e}");
                break;
            }
            _ => {}
        }
    }
}
