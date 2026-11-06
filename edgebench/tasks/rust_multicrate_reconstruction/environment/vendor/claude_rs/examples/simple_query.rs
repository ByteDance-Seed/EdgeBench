//! Simple query example demonstrating basic claude_rs usage.
//!
//! Run with: cargo run --example simple_query
//!
//! This example shows how to:
//! - Execute a one-shot query with streaming
//! - Process different message types as they arrive
//! - Configure query options

use claude_rs::{Message, QueryOptions, query};
use futures::StreamExt;

#[tokio::main]
async fn main() -> claude_rs::Result<()> {
    // Configure query options
    let options = QueryOptions::new().max_turns(1); // Limit to a single turn for this example

    // Start a streaming query
    let mut stream = query("What is the capital of France? Reply briefly.", options)?;

    println!("Querying Claude...\n");

    // Process messages as they arrive
    while let Some(result) = stream.next().await {
        match result? {
            Message::System(sys) => {
                if let Some(model) = &sys.model {
                    println!("[System] Using model: {model}");
                }
            }
            Message::Assistant(assistant) => {
                let text = assistant.text();
                if !text.is_empty() {
                    println!("[Assistant] {text}");
                }
            }
            Message::Result(result) => {
                println!("\n[Result] Success: {}", result.is_success());
                if let Some(cost) = result.total_cost_usd {
                    println!("[Result] Cost: ${cost:.6}");
                }
            }
            Message::ToolProgress(progress) => {
                if let Some(name) = &progress.tool_name {
                    println!("[Tool] {name}");
                }
            }
            _ => {}
        }
    }

    Ok(())
}
