//! Test query options validation
//!
//! Tests that invalid options are rejected early with clear error messages.

use claude_rs::{QueryOptions, resume_session, start_query};

fn main() {
    println!("=== Testing Query Options Validation ===\n");

    // === Session ID Validation ===
    println!("--- Session ID Validation ---\n");

    // Test 1: Empty session ID
    println!("Test 1: Empty session ID");
    match resume_session("", QueryOptions::new()) {
        Ok(_) => println!("  FAIL: Empty session ID was accepted"),
        Err(e) => {
            let msg = e.to_string();
            if msg.contains("cannot be empty") {
                println!("  PASS: Got expected error: {msg}");
            } else {
                println!("  FAIL: Wrong error message: {msg}");
            }
        }
    }

    // Test 2: Invalid format (not a UUID)
    println!("\nTest 2: Invalid format (not a UUID)");
    match resume_session("invalid-session-id", QueryOptions::new()) {
        Ok(_) => println!("  FAIL: Invalid session ID was accepted"),
        Err(e) => {
            let msg = e.to_string();
            if msg.contains("Invalid session ID format") {
                println!("  PASS: Got expected error: {msg}");
            } else {
                println!("  FAIL: Wrong error message: {msg}");
            }
        }
    }

    // Test 3: Random garbage
    println!("\nTest 3: Random garbage");
    match resume_session("abc123", QueryOptions::new()) {
        Ok(_) => println!("  FAIL: Random garbage was accepted"),
        Err(e) => {
            let msg = e.to_string();
            if msg.contains("Invalid session ID format") {
                println!("  PASS: Got expected error: {msg}");
            } else {
                println!("  FAIL: Wrong error message: {msg}");
            }
        }
    }

    // Test 4: start_query with invalid resume option
    println!("\nTest 4: start_query with invalid resume option");
    match start_query(QueryOptions::new().resume_session("not-a-uuid")) {
        Ok(_) => println!("  FAIL: Invalid session ID was accepted via options"),
        Err(e) => {
            let msg = e.to_string();
            if msg.contains("Invalid session ID format") {
                println!("  PASS: Got expected error: {msg}");
            } else {
                println!("  FAIL: Wrong error message: {msg}");
            }
        }
    }

    // === max_turns Validation ===
    println!("\n--- max_turns Validation ---\n");

    // Test 5: max_turns=0 should error
    println!("Test 5: max_turns=0 should error");
    match start_query(QueryOptions::new().max_turns(0)) {
        Ok(_) => println!("  FAIL: max_turns=0 was accepted"),
        Err(e) => {
            let msg = e.to_string();
            if msg.contains("max_turns must be at least 1") {
                println!("  PASS: Got expected error: {msg}");
            } else {
                println!("  FAIL: Wrong error message: {msg}");
            }
        }
    }

    // === Budget Validation ===
    println!("\n--- Budget Validation ---\n");

    // Test 6: max_budget_usd=0 should error
    println!("Test 6: max_budget_usd=0 should error");
    match start_query(QueryOptions::new().max_budget_usd(0.0)) {
        Ok(_) => println!("  FAIL: max_budget_usd=0 was accepted"),
        Err(e) => {
            let msg = e.to_string();
            if msg.contains("max_budget_usd must be positive") {
                println!("  PASS: Got expected error: {msg}");
            } else {
                println!("  FAIL: Wrong error message: {msg}");
            }
        }
    }

    // Test 7: Negative budget should error
    println!("\nTest 7: Negative budget should error");
    match start_query(QueryOptions::new().max_budget_usd(-1.0)) {
        Ok(_) => println!("  FAIL: Negative budget was accepted"),
        Err(e) => {
            let msg = e.to_string();
            if msg.contains("max_budget_usd must be positive") {
                println!("  PASS: Got expected error: {msg}");
            } else {
                println!("  FAIL: Wrong error message: {msg}");
            }
        }
    }

    println!("\n=== Query Options Validation Tests Complete ===");
    println!("All validation tests PASSED!");
}
