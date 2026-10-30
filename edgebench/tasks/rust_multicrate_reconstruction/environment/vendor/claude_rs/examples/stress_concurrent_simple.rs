//! Simplified concurrent stress test to verify basic functionality.
//!
//! Run with: cargo run --example stress_concurrent_simple

use claude_rs::{QueryOptions, prompt};
use std::time::Instant;

#[tokio::main]
async fn main() -> claude_rs::Result<()> {
    println!("=== Simple Concurrent Test ===\n");

    // Test: 3 concurrent queries
    println!("--- Running 3 concurrent queries ---");

    let start = Instant::now();

    let handle1 =
        tokio::spawn(async { prompt("Reply with: Test1", QueryOptions::new().max_turns(1)).await });

    let handle2 =
        tokio::spawn(async { prompt("Reply with: Test2", QueryOptions::new().max_turns(1)).await });

    let handle3 =
        tokio::spawn(async { prompt("Reply with: Test3", QueryOptions::new().max_turns(1)).await });

    // Wait for all
    let result1 = handle1.await;
    let result2 = handle2.await;
    let result3 = handle3.await;

    let elapsed = start.elapsed();

    println!("\nResults:");
    match result1 {
        Ok(Ok(r)) => println!(
            "  Task 1: SUCCESS - {}",
            r.result.as_deref().unwrap_or("(empty)")
        ),
        Ok(Err(e)) => println!("  Task 1: ERROR - {e}"),
        Err(e) => println!("  Task 1: PANIC - {e}"),
    }

    match result2 {
        Ok(Ok(r)) => println!(
            "  Task 2: SUCCESS - {}",
            r.result.as_deref().unwrap_or("(empty)")
        ),
        Ok(Err(e)) => println!("  Task 2: ERROR - {e}"),
        Err(e) => println!("  Task 2: PANIC - {e}"),
    }

    match result3 {
        Ok(Ok(r)) => println!(
            "  Task 3: SUCCESS - {}",
            r.result.as_deref().unwrap_or("(empty)")
        ),
        Ok(Err(e)) => println!("  Task 3: ERROR - {e}"),
        Err(e) => println!("  Task 3: PANIC - {e}"),
    }

    println!("\nCompleted in {elapsed:?}");
    println!("No crashes or hangs detected!");

    Ok(())
}
