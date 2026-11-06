//! Test that session() API works correctly under concurrent load
//!
//! This validates the recommended workaround for the start_query() deadlock

use claude_rs::{QueryOptions, session};
use std::time::{Duration, Instant};

#[tokio::main]
async fn main() -> claude_rs::Result<()> {
    println!("=== Testing Concurrent Session API ===\n");

    println!("Test 1: Single session with multi-turn...");
    let start = Instant::now();
    match tokio::time::timeout(Duration::from_secs(60), test_single_session()).await {
        Ok(Ok(_)) => println!("✓ Test 1 passed in {:?}\n", start.elapsed()),
        Ok(Err(e)) => println!("✗ Test 1 failed: {e}\n"),
        Err(_) => println!("✗ Test 1 TIMED OUT\n"),
    }

    println!("Test 2: Three concurrent sessions...");
    let start = Instant::now();
    match tokio::time::timeout(Duration::from_secs(90), test_concurrent_sessions()).await {
        Ok(Ok(_)) => println!("✓ Test 2 passed in {:?}\n", start.elapsed()),
        Ok(Err(e)) => println!("✗ Test 2 failed: {e}\n"),
        Err(_) => println!("✗ Test 2 TIMED OUT\n"),
    }

    println!("All session tests completed!");
    Ok(())
}

async fn test_single_session() -> claude_rs::Result<()> {
    session(QueryOptions::new().max_turns(2), |mut sess| async move {
        println!("  Sending first message...");
        sess.send("Remember: my favorite color is blue. Reply with: Noted.")
            .await?;

        println!("  Waiting for response...");
        let _ = sess.await_result(Some(Duration::from_secs(30))).await?;
        println!("  Got first result");

        println!("  Sending second message...");
        sess.send("What is my favorite color? Reply with just the color.")
            .await?;

        println!("  Waiting for final response...");
        let result = sess.await_result(Some(Duration::from_secs(30))).await?;
        println!("  Got final result: success={}", result.is_success());

        Ok(())
    })
    .await
}

async fn test_concurrent_sessions() -> claude_rs::Result<()> {
    let handle1 = tokio::spawn(async {
        session(QueryOptions::new().max_turns(1), |mut sess| async move {
            sess.send("Reply with: Session1").await?;
            let result = sess.await_result(Some(Duration::from_secs(30))).await?;
            Ok::<_, claude_rs::Error>(result.is_success())
        })
        .await
    });

    let handle2 = tokio::spawn(async {
        session(QueryOptions::new().max_turns(1), |mut sess| async move {
            sess.send("Reply with: Session2").await?;
            let result = sess.await_result(Some(Duration::from_secs(30))).await?;
            Ok::<_, claude_rs::Error>(result.is_success())
        })
        .await
    });

    let handle3 = tokio::spawn(async {
        session(QueryOptions::new().max_turns(1), |mut sess| async move {
            sess.send("Reply with: Session3").await?;
            let result = sess.await_result(Some(Duration::from_secs(30))).await?;
            Ok::<_, claude_rs::Error>(result.is_success())
        })
        .await
    });

    let r1 = handle1.await.expect("Task 1 panicked")?;
    let r2 = handle2.await.expect("Task 2 panicked")?;
    let r3 = handle3.await.expect("Task 3 panicked")?;

    println!("  Session 1: {}", if r1 { "SUCCESS" } else { "FAILED" });
    println!("  Session 2: {}", if r2 { "SUCCESS" } else { "FAILED" });
    println!("  Session 3: {}", if r3 { "SUCCESS" } else { "FAILED" });

    if r1 && r2 && r3 {
        Ok(())
    } else {
        Err(claude_rs::Error::Runtime(
            "Some sessions failed".to_string(),
        ))
    }
}
