//! Stress test - exercise various SDK features to find bugs.
//!
//! Run with: cargo run --example stress_test

use claude_rs::{Message, PermissionMode, QueryOptions, prompt, query, session};
use futures::StreamExt;
use std::time::Duration;

#[tokio::main]
async fn main() -> claude_rs::Result<()> {
    println!("=== Claude RS Stress Test ===\n");

    // Test 1: Basic query
    println!("--- Test 1: Basic Query ---");
    test_basic_query().await?;

    // Test 2: Query with options
    println!("\n--- Test 2: Query with Options ---");
    test_query_with_options().await?;

    // Test 3: Streaming messages
    println!("\n--- Test 3: Streaming Messages ---");
    test_streaming().await?;

    // Test 4: Session management
    println!("\n--- Test 4: Session Management ---");
    test_session().await?;

    // Test 5: Empty/edge case inputs
    println!("\n--- Test 5: Edge Cases ---");
    test_edge_cases().await?;

    // Test 6: Rapid successive queries
    println!("\n--- Test 6: Rapid Queries ---");
    test_rapid_queries().await?;

    println!("\n=== All Tests Completed ===");
    Ok(())
}

async fn test_basic_query() -> claude_rs::Result<()> {
    let result = prompt(
        "Reply with only the word 'OK'",
        QueryOptions::new().max_turns(1),
    )
    .await?;
    println!("Result: {}", result.result.as_deref().unwrap_or("(none)"));
    println!("Success: {}", result.is_success());
    println!("Cost: ${:.6}", result.total_cost_usd.unwrap_or(0.0));
    Ok(())
}

async fn test_query_with_options() -> claude_rs::Result<()> {
    let options = QueryOptions::new()
        .max_turns(2)
        .max_budget_usd(0.50)
        .permission_mode(PermissionMode::Plan);

    let result = prompt(
        "What would be the steps to create a hello world program in Rust? Just list 3 steps briefly.",
        options,
    )
    .await?;

    println!(
        "Result length: {} chars",
        result.result.as_deref().map(|s| s.len()).unwrap_or(0)
    );
    println!("Turns used: {:?}", result.num_turns);
    Ok(())
}

async fn test_streaming() -> claude_rs::Result<()> {
    let mut stream = query(
        "Count from 1 to 5, each on a new line",
        QueryOptions::new().max_turns(1),
    )?;

    let mut message_count = 0;
    let mut assistant_count = 0;

    while let Some(msg_result) = stream.next().await {
        match msg_result {
            Ok(msg) => {
                message_count += 1;
                match &msg {
                    Message::System(s) => {
                        println!("System: session={:?}", s.session_id);
                    }
                    Message::Assistant(a) => {
                        assistant_count += 1;
                        let text = a.text();
                        if !text.is_empty() {
                            println!("Assistant ({} chars)", text.len());
                        }
                    }
                    Message::Result(r) => {
                        println!("Result: success={}", r.is_success());
                    }
                    _ => {}
                }
            }
            Err(e) => {
                println!("Error: {e}");
                break;
            }
        }
    }

    println!("Total messages: {message_count}, Assistant messages: {assistant_count}");
    Ok(())
}

async fn test_session() -> claude_rs::Result<()> {
    let result = session(QueryOptions::new().max_turns(3), |mut sess| async move {
        // First message
        sess.send("Remember: my favorite color is blue. Reply with just 'Noted.'")
            .await?;

        let msg = sess.await_response(Some(Duration::from_secs(30))).await?;
        if let Message::Assistant(a) = &msg {
            println!(
                "First response: {}",
                a.text().chars().take(50).collect::<String>()
            );
        }

        // Wait for result
        let _ = sess.await_result(Some(Duration::from_secs(30))).await?;

        // Second message - test memory
        sess.send("What is my favorite color? Reply with just the color.")
            .await?;

        loop {
            let msg = sess.await_response(Some(Duration::from_secs(30))).await?;
            match msg {
                Message::Assistant(a) => {
                    let text = a.text();
                    if !text.is_empty() {
                        println!("Second response: {text}");
                    }
                }
                Message::Result(r) => {
                    println!("Session result: success={}", r.is_success());
                    return Ok(());
                }
                _ => {}
            }
        }
    })
    .await;

    match result {
        Ok(_) => println!("Session test passed"),
        Err(e) => println!("Session test error: {e}"),
    }
    Ok(())
}

async fn test_edge_cases() -> claude_rs::Result<()> {
    // Test with very short prompt
    println!("Testing short prompt...");
    let result = prompt("Hi", QueryOptions::new().max_turns(1)).await;
    match result {
        Ok(r) => println!(
            "Short prompt: {} chars",
            r.result.as_deref().map(|s| s.len()).unwrap_or(0)
        ),
        Err(e) => println!("Short prompt error: {e}"),
    }

    // Test with special characters
    println!("Testing special characters...");
    let result = prompt(
        "Echo back: @#$%^&*(){}[]|\\:\";<>?,./`~",
        QueryOptions::new().max_turns(1),
    )
    .await;
    match result {
        Ok(r) => println!("Special chars: success={}", r.is_success()),
        Err(e) => println!("Special chars error: {e}"),
    }

    // Test with unicode
    println!("Testing unicode...");
    let result = prompt("Echo: 你好世界 🌍 مرحبا", QueryOptions::new().max_turns(1)).await;
    match result {
        Ok(r) => println!("Unicode: success={}", r.is_success()),
        Err(e) => println!("Unicode error: {e}"),
    }

    Ok(())
}

async fn test_rapid_queries() -> claude_rs::Result<()> {
    let start = std::time::Instant::now();

    for i in 1..=3 {
        let result = prompt(
            &format!("Reply with only the number {i}"),
            QueryOptions::new().max_turns(1),
        )
        .await;

        match result {
            Ok(r) => println!(
                "Query {}: {}",
                i,
                r.result.as_deref().unwrap_or("(none)").trim()
            ),
            Err(e) => println!("Query {i} error: {e}"),
        }
    }

    println!("3 queries completed in {:?}", start.elapsed());
    Ok(())
}
