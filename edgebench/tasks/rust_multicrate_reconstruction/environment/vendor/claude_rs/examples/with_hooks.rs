//! Hooks example - demonstrating the hook API.
//!
//! Run with: cargo run --example with_hooks
//!
//! This example demonstrates the hook API pattern for intercepting
//! tool use events. Hooks can be used to:
//! - Log tool usage
//! - Validate tool inputs before execution
//! - Block certain tool calls
//! - Modify tool inputs
//!
//! ## Known Limitation
//!
//! As of December 2025, the CLI may not trigger SDK hooks in `--print` mode.
//! This is a known issue affecting all official SDKs.
//! See: https://github.com/anthropics/claude-code/issues/6223
//!
//! The hook API is included here to provide the correct interface.
//! Once the CLI issue is resolved, hooks will work automatically.

use claude_rs::hook::{Hook, HookEvent, HookInput, HookOutput};
use claude_rs::{Message, QueryOptions, session};

#[tokio::main]
async fn main() -> claude_rs::Result<()> {
    println!("=== Hook Example ===\n");
    println!("Note: Hooks may not trigger in --print mode (known CLI issue).\n");

    // Create a hook that logs all tool usage
    let log_hook = Hook::builder(HookEvent::PreToolUse).handler_fn(|input: HookInput| async move {
        println!("[Hook] PreToolUse event: {}", input.event);
        if let Some(tool_name) = input.tool_name() {
            println!("[Hook] Tool name: {tool_name}");
        }
        // Allow the tool to proceed
        HookOutput::approve()
    });

    // Create a hook that blocks Bash usage (example of denying)
    let block_bash_hook = Hook::builder(HookEvent::PreToolUse)
        .matcher("Bash")
        .handler_fn(|_input: HookInput| async move {
            println!("[Hook] Blocking Bash tool!");
            HookOutput::deny("Bash is not allowed in this example")
        });

    // Configure query with hooks
    // Session API uses streaming input mode which is required for hooks
    let options = QueryOptions::new()
        .hook(log_hook)
        .hook(block_bash_hook)
        .max_turns(5);

    println!("[You] List files in the current directory\n");

    // Use session API to keep the input stream open
    session(options, |mut sess| async move {
        sess.send("List the files in the current directory using Glob.")
            .await?;

        loop {
            let msg = sess.await_response(None).await?;
            match &msg {
                Message::Assistant(a) => {
                    let text = a.text();
                    if !text.is_empty() {
                        println!("[Claude] {text}");
                    }
                }
                Message::Result(r) => {
                    println!("\n[Result] Success: {}", r.is_success());
                    if let Some(cost) = r.total_cost_usd {
                        println!("[Cost: ${cost:.6}]");
                    }
                    break;
                }
                _ => {}
            }
        }

        Ok(())
    })
    .await?;

    println!("\nDone!");
    Ok(())
}
