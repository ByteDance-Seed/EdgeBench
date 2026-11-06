//! Debug raw JSON output from Claude CLI.
//!
//! Run with: cargo run --example debug_json

use claude_rs::{Message, QueryOptions, query};
use futures::StreamExt;

#[tokio::main]
async fn main() -> claude_rs::Result<()> {
    println!("=== Debug JSON Output ===\n");

    let mut stream = query(
        "Reply with only the word 'test'",
        QueryOptions::new().max_turns(1),
    )?;

    while let Some(msg) = stream.next().await {
        match msg {
            Ok(m) => {
                // Print full debug representation
                println!("{m:#?}\n");

                // Check session_id specifically
                match &m {
                    Message::System(s) => {
                        println!(">>> System message session_id: {:?}", s.session_id);
                        println!(">>> System message subtype: {:?}", s.subtype);
                    }
                    Message::Result(r) => {
                        println!(">>> Result session_id: {:?}", r.session_id);
                    }
                    _ => {}
                }
            }
            Err(e) => {
                println!("Error: {e}");
            }
        }
    }

    Ok(())
}
