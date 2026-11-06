//! Test interleaved recv/send operations
//!
//! This test specifically checks if recv() and send_message() can be safely interleaved

use claude_rs::{QueryOptions, start_query};
use std::time::{Duration, Instant};

#[tokio::main]
async fn main() -> claude_rs::Result<()> {
    println!("=== Testing Interleaved recv/send ===\n");

    println!("Test 1: Send then recv pattern...");
    let start = Instant::now();
    match tokio::time::timeout(Duration::from_secs(30), test_send_recv()).await {
        Ok(Ok(_)) => println!("✓ Test 1 passed in {:?}\n", start.elapsed()),
        Ok(Err(e)) => println!("✗ Test 1 failed: {e}\n"),
        Err(_) => println!("✗ Test 1 TIMED OUT (potential deadlock!)\n"),
    }

    println!("Test 2: Multiple sends then recv...");
    let start = Instant::now();
    match tokio::time::timeout(Duration::from_secs(30), test_multi_send()).await {
        Ok(Ok(_)) => println!("✓ Test 2 passed in {:?}\n", start.elapsed()),
        Ok(Err(e)) => println!("✗ Test 2 failed: {e}\n"),
        Err(_) => println!("✗ Test 2 TIMED OUT (potential deadlock!)\n"),
    }

    println!("Test 3: Interleaved send/recv...");
    let start = Instant::now();
    match tokio::time::timeout(Duration::from_secs(30), test_interleaved()).await {
        Ok(Ok(_)) => println!("✓ Test 3 passed in {:?}\n", start.elapsed()),
        Ok(Err(e)) => println!("✗ Test 3 failed: {e}\n"),
        Err(_) => println!("✗ Test 3 TIMED OUT (potential deadlock!)\n"),
    }

    Ok(())
}

async fn test_send_recv() -> claude_rs::Result<()> {
    let mut query = start_query(QueryOptions::new().max_turns(1))?;

    query.send_message("Reply with: OK").await?;

    let mut count = 0;
    while let Some(_msg) = query.recv().await {
        count += 1;
        if count > 10 {
            break;
        }
    }

    println!("  Received {count} messages");
    Ok(())
}

async fn test_multi_send() -> claude_rs::Result<()> {
    let mut query = start_query(QueryOptions::new().max_turns(2))?;

    // Send two messages before any recv
    query.send_message("First message").await?;
    query.send_message("Second message").await?;

    // Now drain all messages
    let mut count = 0;
    while let Some(_msg) = query.recv().await {
        count += 1;
        if count > 20 {
            break;
        }
    }

    println!("  Received {count} messages");
    Ok(())
}

async fn test_interleaved() -> claude_rs::Result<()> {
    let mut query = start_query(QueryOptions::new().max_turns(2))?;

    // Send, recv one, send again
    query.send_message("Message 1").await?;

    println!("  Sent message 1, trying to recv...");
    let msg1 = query.recv().await;
    println!("  Got message 1: {:?}", msg1.is_some());

    query.send_message("Message 2").await?;
    println!("  Sent message 2, trying to recv...");

    let msg2 = query.recv().await;
    println!("  Got message 2: {:?}", msg2.is_some());

    // Drain the rest
    let mut count = 2;
    while let Some(_msg) = query.recv().await {
        count += 1;
        if count > 20 {
            break;
        }
    }

    println!("  Received {count} total messages");
    Ok(())
}
