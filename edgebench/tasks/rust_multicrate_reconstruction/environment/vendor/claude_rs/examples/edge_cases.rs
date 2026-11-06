//! Comprehensive edge case tests for claude_rs.
//!
//! Tests weird inputs that might break the SDK:
//! - Empty string prompts
//! - Very long prompts (10000+ characters)
//! - Unicode edge cases (emojis, RTL text, null bytes)
//! - Special characters that might break JSON (quotes, backslashes, newlines)
//! - Calling recv() before send_message()
//! - Calling send_message() after finish_input()
//! - Double finish_input() calls
//! - Invalid session IDs for resume
//!
//! Run with: cargo run --example edge_cases

use claude_rs::{Message, QueryOptions, query, resume_session, start_query};
use futures::StreamExt;

#[tokio::main]
async fn main() -> claude_rs::Result<()> {
    println!("=== Edge Case Tests for claude_rs ===\n");

    // Test 1: Empty string prompt
    println!("--- Test 1: Empty String Prompt ---");
    test_empty_prompt().await;

    // Test 2: Whitespace-only prompt
    println!("\n--- Test 2: Whitespace-Only Prompt ---");
    test_whitespace_prompt().await;

    // Test 3: Very long prompt (10000+ characters)
    println!("\n--- Test 3: Very Long Prompt (10000+ chars) ---");
    test_very_long_prompt().await;

    // Test 4: Unicode emojis
    println!("\n--- Test 4: Unicode Emojis ---");
    test_unicode_emojis().await;

    // Test 5: Right-to-left text (Arabic/Hebrew)
    println!("\n--- Test 5: RTL Text ---");
    test_rtl_text().await;

    // Test 6: Special JSON-breaking characters
    println!("\n--- Test 6: JSON-Breaking Characters ---");
    test_json_breaking_chars().await;

    // Test 7: Embedded newlines and tabs
    println!("\n--- Test 7: Embedded Newlines and Tabs ---");
    test_embedded_whitespace().await;

    // Test 8: Unicode null bytes and control characters
    println!("\n--- Test 8: Null Bytes and Control Characters ---");
    test_null_bytes().await;

    // Test 9: Calling recv() before send_message()
    println!("\n--- Test 9: recv() Before send_message() ---");
    test_recv_before_send().await;

    // Test 10: Calling send_message() after finish_input()
    println!("\n--- Test 10: send_message() After finish_input() ---");
    test_send_after_finish().await;

    // Test 11: Double finish_input() calls
    println!("\n--- Test 11: Double finish_input() Calls ---");
    test_double_finish().await;

    // Test 12: Invalid session ID for resume
    println!("\n--- Test 12: Invalid Session ID for resume ---");
    test_invalid_session_id().await;

    // Test 13: Mixed unicode and special characters
    println!("\n--- Test 13: Mixed Unicode and Special Characters ---");
    test_mixed_unicode_special().await;

    // Test 14: Extremely nested quotes
    println!("\n--- Test 14: Extremely Nested Quotes ---");
    test_nested_quotes().await;

    // Test 15: Unicode combining characters
    println!("\n--- Test 15: Unicode Combining Characters ---");
    test_combining_characters().await;

    println!("\n=== Edge Case Tests Completed ===");
    Ok(())
}

async fn test_empty_prompt() {
    println!("Testing empty string prompt...");
    let result = query("", QueryOptions::new().max_turns(1));

    match result {
        Ok(mut stream) => {
            println!("Query started successfully with empty prompt");
            let timeout = std::time::Duration::from_secs(10);
            match tokio::time::timeout(timeout, async {
                let mut msg_count = 0;
                while let Some(msg) = stream.next().await {
                    msg_count += 1;
                    match msg {
                        Ok(Message::Result(r)) => {
                            return Ok((r.is_success(), msg_count));
                        }
                        Ok(_) => {}
                        Err(e) => return Err(e),
                    }
                }
                Err(claude_rs::Error::StreamEnded)
            })
            .await
            {
                Ok(Ok((success, count))) => {
                    println!("✓ Result received: success={success}, msgs={count}")
                }
                Ok(Err(e)) => println!("✗ Error: {e}"),
                Err(_) => println!("✗ Timeout - no result message received"),
            }
        }
        Err(e) => println!("✗ Query failed: {e}"),
    }
}

async fn test_whitespace_prompt() {
    println!("Testing whitespace-only prompt...");
    let prompts = [
        "   ",        // spaces
        "\t\t\t",     // tabs
        "\n\n\n",     // newlines
        "   \t\n   ", // mixed
    ];

    for (i, prompt) in prompts.iter().enumerate() {
        let result = query(prompt, QueryOptions::new().max_turns(1));
        match result {
            Ok(mut stream) => {
                let timeout = std::time::Duration::from_secs(10);
                match tokio::time::timeout(timeout, async {
                    while let Some(msg) = stream.next().await {
                        if let Ok(Message::Result(r)) = msg {
                            return Some(r.is_success());
                        }
                    }
                    None
                })
                .await
                {
                    Ok(Some(success)) => {
                        println!("✓ Whitespace test {} completed: success={}", i + 1, success)
                    }
                    Ok(None) => println!("✗ Whitespace test {} - no result", i + 1),
                    Err(_) => println!("✗ Whitespace test {} - timeout", i + 1),
                }
            }
            Err(e) => println!("✗ Whitespace test {} failed: {}", i + 1, e),
        }
    }
}

async fn test_very_long_prompt() {
    // Create a prompt with 15000 characters
    let long_text: String = (0..750)
        .map(|i| format!("This is sentence number {i} with some padding text. "))
        .collect();

    let prompt = format!(
        "I'm sending you a very long message with approximately 15000 characters. \
         Please just reply 'OK'. Here's the text: {long_text}"
    );

    println!("Prompt length: {} chars", prompt.len());

    let result = query(&prompt, QueryOptions::new().max_turns(1));

    match result {
        Ok(mut stream) => {
            while let Some(msg) = stream.next().await {
                match msg {
                    Ok(Message::Result(r)) => {
                        println!("✓ Long prompt handled: success={}", r.is_success());
                        return;
                    }
                    Err(e) => {
                        println!("✗ Error: {e}");
                        return;
                    }
                    _ => {}
                }
            }
        }
        Err(e) => println!("✗ Long prompt failed: {e}"),
    }
}

async fn test_unicode_emojis() {
    let prompts = [
        "What is 2+2? Reply with just the number. 😀🎉🚀",
        "🔥🔥🔥 Just say 'OK' 🔥🔥🔥",
        "Test: 👨‍👩‍👧‍👦 (family emoji)", // Multi-codepoint emoji
        "🇺🇸🇬🇧🇫🇷 (flags)",          // Flag emojis
    ];

    for (i, prompt) in prompts.iter().enumerate() {
        let result = query(prompt, QueryOptions::new().max_turns(1));
        match result {
            Ok(mut stream) => {
                while let Some(msg) = stream.next().await {
                    if let Ok(Message::Result(r)) = msg {
                        println!(
                            "✓ Emoji test {} completed: success={}",
                            i + 1,
                            r.is_success()
                        );
                        break;
                    }
                }
            }
            Err(e) => println!("✗ Emoji test {} failed: {}", i + 1, e),
        }
    }
}

async fn test_rtl_text() {
    let prompts = [
        "مرحبا (Arabic: Hello) - just say 'OK'",
        "שלום (Hebrew: Hello) - just say 'OK'",
        "Mix: Hello שלום مرحبا - just say 'OK'",
    ];

    for (i, prompt) in prompts.iter().enumerate() {
        let result = query(prompt, QueryOptions::new().max_turns(1));
        match result {
            Ok(mut stream) => {
                while let Some(msg) = stream.next().await {
                    if let Ok(Message::Result(r)) = msg {
                        println!("✓ RTL test {} completed: success={}", i + 1, r.is_success());
                        break;
                    }
                }
            }
            Err(e) => println!("✗ RTL test {} failed: {}", i + 1, e),
        }
    }
}

async fn test_json_breaking_chars() {
    let prompts = [
        r#"Say "OK" with quotes"#,
        r#"Backslash test: \\ \n \t - just say "OK""#,
        r#"Quote test: "nested "quotes" here" - say "OK""#,
        r#"Both: \"escaped\" and normal - say "OK""#,
    ];

    for (i, prompt) in prompts.iter().enumerate() {
        println!(
            "Testing JSON-breaking chars {}: {}",
            i + 1,
            &prompt[..prompt.len().min(40)]
        );
        let result = query(prompt, QueryOptions::new().max_turns(1));
        match result {
            Ok(mut stream) => {
                while let Some(msg) = stream.next().await {
                    match msg {
                        Ok(Message::Result(r)) => {
                            println!(
                                "✓ JSON test {} completed: success={}",
                                i + 1,
                                r.is_success()
                            );
                            break;
                        }
                        Err(e) => {
                            println!("✗ JSON test {} error: {}", i + 1, e);
                            break;
                        }
                        _ => {}
                    }
                }
            }
            Err(e) => println!("✗ JSON test {} failed to start: {}", i + 1, e),
        }
    }
}

async fn test_embedded_whitespace() {
    let prompt = "Line 1\nLine 2\nLine 3\n\nDouble newline\n\tTabbed\n\r\nCRLF - just say 'OK'";

    println!("Testing embedded whitespace...");
    let result = query(prompt, QueryOptions::new().max_turns(1));

    match result {
        Ok(mut stream) => {
            while let Some(msg) = stream.next().await {
                if let Ok(Message::Result(r)) = msg {
                    println!("✓ Whitespace test completed: success={}", r.is_success());
                    return;
                }
            }
        }
        Err(e) => println!("✗ Whitespace test failed: {e}"),
    }
}

async fn test_null_bytes() {
    // Test control characters (skipping actual null bytes as they're tricky)
    let prompts = [
        "Control chars: \x01\x02\x03 - say 'OK'",
        "Bell: \x07 - say 'OK'",
        "DEL: \x7F - say 'OK'",
    ];

    for (i, prompt) in prompts.iter().enumerate() {
        println!("Testing control character {}", i + 1);
        let result = query(prompt, QueryOptions::new().max_turns(1));
        match result {
            Ok(mut stream) => {
                while let Some(msg) = stream.next().await {
                    if let Ok(Message::Result(r)) = msg {
                        println!(
                            "✓ Control char test {} completed: success={}",
                            i + 1,
                            r.is_success()
                        );
                        break;
                    }
                }
            }
            Err(e) => println!("✗ Control char test {} failed: {}", i + 1, e),
        }
    }
}

async fn test_recv_before_send() {
    println!("Testing recv() before send_message()...");

    let mut q = match start_query(QueryOptions::new().max_turns(1)) {
        Ok(q) => q,
        Err(e) => {
            println!("✗ Failed to start query: {e}");
            return;
        }
    };

    // Try to receive before sending anything
    println!("Calling recv() without sending message first...");
    match tokio::time::timeout(std::time::Duration::from_secs(2), q.recv()).await {
        Ok(Some(Ok(msg))) => {
            println!(
                "✓ Received message (system message expected): session_id={:?}",
                msg.session_id()
            );
        }
        Ok(Some(Err(e))) => {
            println!("✗ Received error: {e}");
        }
        Ok(None) => {
            println!("✓ Stream ended (expected behavior)");
        }
        Err(_) => {
            println!("✓ Timeout (expected - no messages without input)");
        }
    }

    // Now send a message and see if it still works
    if let Err(e) = q.send_message("Say 'OK'").await {
        println!("✗ Failed to send message after recv: {e}");
        return;
    }

    if let Err(e) = q.finish_input() {
        println!("✗ Failed to finish input: {e}");
        return;
    }

    // Collect remaining messages
    let mut got_result = false;
    while let Some(msg) = q.recv().await {
        if let Ok(Message::Result(r)) = msg {
            println!(
                "✓ Got result after recv-before-send: success={}",
                r.is_success()
            );
            got_result = true;
            break;
        }
    }

    if !got_result {
        println!("✗ No result received");
    }
}

async fn test_send_after_finish() {
    println!("Testing send_message() after finish_input()...");

    let mut q = match start_query(QueryOptions::new().max_turns(2)) {
        Ok(q) => q,
        Err(e) => {
            println!("✗ Failed to start query: {e}");
            return;
        }
    };

    // Send a message
    if let Err(e) = q.send_message("First message").await {
        println!("✗ Failed to send first message: {e}");
        return;
    }

    // Finish input
    if let Err(e) = q.finish_input() {
        println!("✗ Failed to finish input: {e}");
        return;
    }
    println!("Finished input, now trying to send another message...");

    // Try to send another message after finish
    match q.send_message("Message after finish").await {
        Ok(_) => {
            println!("✗ send_message() succeeded after finish (unexpected)");
        }
        Err(e) => {
            println!("✓ send_message() failed after finish (expected): {e}");
        }
    }

    // Drain remaining messages
    while q.recv().await.is_some() {}
}

async fn test_double_finish() {
    println!("Testing double finish_input() calls...");

    let mut q = match start_query(QueryOptions::new().max_turns(1)) {
        Ok(q) => q,
        Err(e) => {
            println!("✗ Failed to start query: {e}");
            return;
        }
    };

    // Send a message
    if let Err(e) = q.send_message("Test message").await {
        println!("✗ Failed to send message: {e}");
        return;
    }

    // First finish
    match q.finish_input() {
        Ok(_) => println!("✓ First finish_input() succeeded"),
        Err(e) => {
            println!("✗ First finish_input() failed: {e}");
            return;
        }
    }

    // Second finish
    match q.finish_input() {
        Ok(_) => println!("✓ Second finish_input() succeeded (may be no-op)"),
        Err(e) => println!("✓ Second finish_input() failed (expected): {e}"),
    }

    // Drain messages
    while q.recv().await.is_some() {}
}

async fn test_invalid_session_id() {
    println!("Testing invalid session IDs...");

    let long_id = "a".repeat(1000);
    let invalid_ids = [
        "",                     // Empty
        "invalid-session-id",   // Non-existent
        "../../etc/passwd",     // Path traversal attempt
        "session-\x00-null",    // Null byte
        long_id.as_str(),       // Very long
        "session with spaces",  // Spaces
        "session/with/slashes", // Slashes
    ];

    for (i, id) in invalid_ids.iter().enumerate() {
        let display_id = if id.len() > 40 {
            format!("{}... ({} chars)", &id[..40], id.len())
        } else {
            id.to_string()
        };

        println!("Testing invalid session ID {}: {:?}", i + 1, display_id);

        match resume_session(id, QueryOptions::new().max_turns(1)) {
            Ok(mut q) => {
                // Try to send a message and see what happens
                match q.send_message("Test").await {
                    Ok(_) => {
                        if let Err(e) = q.finish_input() {
                            println!("✓ finish_input failed: {e}");
                        }

                        // Check for errors in the stream
                        let mut got_error = false;
                        while let Some(msg) = q.recv().await {
                            match msg {
                                Ok(Message::Result(r)) => {
                                    if r.is_error.unwrap_or(false) {
                                        println!(
                                            "✓ Got error result for invalid session {}",
                                            i + 1
                                        );
                                        got_error = true;
                                    }
                                    break;
                                }
                                Err(e) => {
                                    println!("✓ Stream error for invalid session {}: {}", i + 1, e);
                                    got_error = true;
                                    break;
                                }
                                _ => {}
                            }
                        }
                        if !got_error {
                            println!("✗ No error for invalid session {} (unexpected)", i + 1);
                        }
                    }
                    Err(e) => {
                        println!("✓ send_message failed for invalid session {}: {}", i + 1, e);
                    }
                }
            }
            Err(e) => {
                println!(
                    "✓ resume_session failed immediately for invalid ID {}: {}",
                    i + 1,
                    e
                );
            }
        }
    }
}

async fn test_mixed_unicode_special() {
    let prompt = r#"Mix everything: 😀 "quotes" \backslash מרחבא newline→
tab→	end. Say "OK""#;

    println!("Testing mixed unicode and special characters...");
    let result = query(prompt, QueryOptions::new().max_turns(1));

    match result {
        Ok(mut stream) => {
            while let Some(msg) = stream.next().await {
                match msg {
                    Ok(Message::Result(r)) => {
                        println!("✓ Mixed test completed: success={}", r.is_success());
                        return;
                    }
                    Err(e) => {
                        println!("✗ Error: {e}");
                        return;
                    }
                    _ => {}
                }
            }
        }
        Err(e) => println!("✗ Mixed test failed: {e}"),
    }
}

async fn test_nested_quotes() {
    let prompt = r#"Say this: "He said "she said "they said "OK"""" - exactly like that"#;

    println!("Testing nested quotes...");
    let result = query(prompt, QueryOptions::new().max_turns(1));

    match result {
        Ok(mut stream) => {
            while let Some(msg) = stream.next().await {
                match msg {
                    Ok(Message::Result(r)) => {
                        println!("✓ Nested quotes test completed: success={}", r.is_success());
                        return;
                    }
                    Err(e) => {
                        println!("✗ Error: {e}");
                        return;
                    }
                    _ => {}
                }
            }
        }
        Err(e) => println!("✗ Nested quotes test failed: {e}"),
    }
}

async fn test_combining_characters() {
    // Unicode combining characters that modify the previous character
    let prompts = [
        "Combining: é (e + ́) vs é (single char) - say 'OK'",
        "Zero-width: Hello\u{200B}World (zero-width space) - say 'OK'",
        "Zalgo: H̸̡̪̯ͨ͊̽̅̾̎Ȩ̬̩̾͛ͪ̈́̀́͘ ̶̧̨̱̹̭̯ͧ̾ͬC̷̙̲̝͖ͭ̏ͥͮ͟Oͮ͏̮̪̝͍M̲̖͊̒ͪͩͬ̚̚͜Ȇ̴̟̟͙̞ͩ͌͝S̨̥̫͎̭ͯ̿̔̀ͅ - say 'OK'",
    ];

    for (i, prompt) in prompts.iter().enumerate() {
        println!("Testing combining characters {}", i + 1);
        let result = query(prompt, QueryOptions::new().max_turns(1));
        match result {
            Ok(mut stream) => {
                while let Some(msg) = stream.next().await {
                    if let Ok(Message::Result(r)) = msg {
                        println!(
                            "✓ Combining char test {} completed: success={}",
                            i + 1,
                            r.is_success()
                        );
                        break;
                    }
                }
            }
            Err(e) => println!("✗ Combining char test {} failed: {}", i + 1, e),
        }
    }
}
