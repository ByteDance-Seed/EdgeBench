//! Verbose session abuse test - captures detailed error information.
//!
//! Run with: cargo run --example session_abuse_verbose

use claude_rs::{Message, QueryOptions, start_query};
use tokio::time::{Duration, timeout};

#[tokio::main]
async fn main() -> claude_rs::Result<()> {
    println!("=== Verbose Session Abuse Test ===\n");

    println!("--- Testing Malformed Session IDs ---\n");

    let bad_ids = vec![
        ("not-a-uuid", "Invalid format"),
        ("12345", "Too short"),
        ("", "Empty string"),
        ("null", "Reserved keyword"),
        ("undefined", "JavaScript-ism"),
        ("../../../etc/passwd", "Path traversal"),
    ];

    for (bad_id, description) in bad_ids {
        println!("Testing: '{bad_id}' ({description})");
        match start_query(QueryOptions::new().resume_session(bad_id).max_turns(1)) {
            Ok(mut q) => {
                println!("  ✓ Query started (CLI spawned)");
                match q.send_message("Hello?").await {
                    Ok(_) => {
                        println!("  ✓ Message sent via stdin");

                        let mut got_response = false;
                        let mut error_msg = None;

                        // Add timeout to prevent hanging
                        let recv_future = async {
                            while let Some(msg) = q.recv().await {
                                match msg {
                                    Ok(Message::System(sys)) => {
                                        println!("  📋 System message: {:?}", sys.subtype);
                                    }
                                    Ok(Message::Assistant(a)) => {
                                        got_response = true;
                                        println!("  ✓ Assistant response: {}", a.text());
                                    }
                                    Ok(Message::Result(r)) => {
                                        println!(
                                            "  📊 Result: success={}, is_error={:?}, subtype={:?}",
                                            r.is_success(),
                                            r.is_error,
                                            r.subtype
                                        );
                                        if let Some(ref result_text) = r.result
                                            && (result_text.contains("error")
                                                || result_text.contains("Error"))
                                        {
                                            println!(
                                                "  ❌ Result text contains error: {result_text}"
                                            );
                                        }
                                        break;
                                    }
                                    Err(e) => {
                                        println!("  ❌ Error during receive: {e}");
                                        error_msg = Some(format!("{e}"));
                                        break;
                                    }
                                    _ => {}
                                }
                            }
                        };

                        match timeout(Duration::from_secs(10), recv_future).await {
                            Ok(_) => {
                                // Completed normally
                            }
                            Err(_) => {
                                println!("  ⏱️  Timeout waiting for response (10s)");
                                error_msg = Some("Timeout".to_string());
                            }
                        }

                        if got_response {
                            println!(
                                "  ⚠️  UNEXPECTED: Got valid response from invalid session ID!"
                            );
                        } else if let Some(err) = error_msg {
                            println!("  ✓ EXPECTED: Error occurred: {err}");
                        }
                    }
                    Err(e) => {
                        println!("  ✓ EXPECTED: Failed to send message: {e}");
                    }
                }
            }
            Err(e) => {
                println!("  ✓ EXPECTED: Failed to start query: {e}");
            }
        }
        println!();
    }

    Ok(())
}
