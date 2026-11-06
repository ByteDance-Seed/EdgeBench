//! Tool filtering example.
//!
//! Run with: cargo run --example with_tools
//!
//! This example shows how to:
//! - Allow specific built-in tools
//! - Disallow specific built-in tools
//! - Define custom tools (shown but requires MCP setup to execute)

use claude_rs::{QueryOptions, Tool, prompt};
use serde_json::json;

#[tokio::main]
async fn main() -> claude_rs::Result<()> {
    // Example 1: Restrict to only read-only tools
    println!("=== Query with restricted tools ===\n");

    let options = QueryOptions::new()
        .disallow_tool("Bash") // No shell commands
        .disallow_tool("Write") // No file writing
        .disallow_tool("Edit") // No file editing
        .max_turns(1);

    println!("[You] What files are in the current directory?");
    let result = prompt(
        "List the files in the current directory. Use the Read or Glob tools only.",
        options,
    )
    .await?;

    println!("[Claude] {}", result.text());
    println!("[Cost: ${:.6}]\n", result.total_cost_usd.unwrap_or(0.0));

    // Example 2: Show how to define a custom tool
    // Note: Custom tools require MCP bridge setup to actually execute
    println!("=== Custom Tool Definition (demo) ===\n");

    let weather_tool = Tool::builder("get_weather")
        .description("Get the current weather for a city")
        .schema(json!({
            "type": "object",
            "properties": {
                "city": {
                    "type": "string",
                    "description": "The city name"
                }
            },
            "required": ["city"]
        }))
        .handler_fn(|input| async move {
            let city = input["city"].as_str().unwrap_or("unknown");
            Ok(json!({
                "temperature": 72,
                "city": city,
                "conditions": "sunny"
            }))
        });

    println!("Defined custom tool: {}", weather_tool.name);
    println!("Description: {}", weather_tool.description);
    println!(
        "Schema: {}",
        serde_json::to_string_pretty(&weather_tool.schema)?
    );

    // To use custom tools with Claude, you would:
    // 1. Start McpBridge::start(vec![weather_tool]).await?
    // 2. Generate config: generate_mcp_config(bridge.port())
    // 3. Pass config to QueryOptions::new().mcp_config(config_path)
    // See the MCP module documentation for details.

    println!("\nDone!");
    Ok(())
}
