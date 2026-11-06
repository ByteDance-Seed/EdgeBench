//! Multi-turn conversation example using streaming input.
//!
//! Run with: cargo run --example multi_turn
//!
//! This example shows how to:
//! - Start a session for multi-turn conversations
//! - Send multiple messages and await responses
//! - Handle conversation state with streaming input

use claude_rs::{Message, QueryOptions, session};

#[tokio::main]
async fn main() -> claude_rs::Result<()> {
    // Configure options for multi-turn conversation
    let options = QueryOptions::new().max_turns(3); // Allow multiple turns

    println!("Starting multi-turn conversation...\n");

    // Use the session helper for automatic cleanup
    session(options, |mut sess| async move {
        // First message
        println!("[You] What's 10 + 5?");
        sess.send("What's 10 + 5? Reply with just the number.")
            .await?;

        // Wait for response
        loop {
            let msg = sess.await_response(None).await?;
            match &msg {
                Message::Assistant(a) => {
                    let text = a.text();
                    if !text.is_empty() {
                        println!("[Claude] {text}");
                    }
                }
                Message::Result(r) if r.is_success() || r.is_max_turns() => {
                    if let Some(cost) = r.total_cost_usd {
                        println!("[Cost so far: ${cost:.6}]\n");
                    }
                    break;
                }
                _ => {}
            }
        }

        // Second message - continue the conversation
        println!("[You] Now multiply that by 2");
        sess.send("Now multiply that by 2. Reply with just the number.")
            .await?;

        // Wait for second response
        loop {
            let msg = sess.await_response(None).await?;
            match &msg {
                Message::Assistant(a) => {
                    let text = a.text();
                    if !text.is_empty() {
                        println!("[Claude] {text}");
                    }
                }
                Message::Result(r) if r.is_success() || r.is_max_turns() => {
                    println!("\n[Session complete]");
                    if let Some(cost) = r.total_cost_usd {
                        println!("[Total cost: ${cost:.6}]");
                    }
                    break;
                }
                _ => {}
            }
        }

        Ok(())
    })
    .await?;

    println!("\nConversation ended.");
    Ok(())
}
