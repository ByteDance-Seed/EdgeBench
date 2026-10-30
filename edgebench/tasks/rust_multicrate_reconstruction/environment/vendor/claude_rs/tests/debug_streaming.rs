//! Debug test for streaming input mode.

use claude_rs::cli::{Cli, CommandBuilder};
use claude_rs::message::Message;
use claude_rs::options::QueryOptions;
use serde_json::json;

#[tokio::test]
#[ignore]
async fn test_debug_streaming_input() {
    // Build command with streaming input AND max-turns
    let _options = QueryOptions::new().max_turns(1);
    let mut builder = CommandBuilder::streaming_input();
    // Add max-turns option
    builder.arg("--max-turns", "1");
    let args = builder.build();

    eprintln!("Args: {args:?}");

    // Spawn CLI using piped mode (required for streaming input)
    let mut cli = Cli::spawn_piped(args).expect("Should spawn CLI");

    eprintln!("CLI spawned, sending message...");

    // Send a user message in stream-json format
    let msg = json!({
        "type": "user",
        "message": {
            "role": "user",
            "content": [{"type": "text", "text": "Say just 'test'"}]
        }
    });

    cli.write(&format!("{msg}\n"))
        .expect("Should write message");
    eprintln!("Message sent: {msg}");

    // DON'T send EOF yet - wait for response first
    // The CLI will process the message and respond

    // Try to receive messages
    let mut count = 0;
    let mut got_result = false;
    loop {
        tokio::select! {
            msg = cli.recv() => {
                match msg {
                    Some(Ok(m)) => {
                        count += 1;
                        eprintln!("Message {}: {:?}", count, std::mem::discriminant(&m));
                        match &m {
                            Message::System(s) => eprintln!("  System: {:?}", s.subtype),
                            Message::Assistant(a) => eprintln!("  Assistant: {}", a.text()),
                            Message::User(u) => eprintln!("  User (replay={}): {}", u.is_replay(), u.text()),
                            Message::Result(r) => {
                                eprintln!("  Result: success={}, text={}", r.is_success(), r.text());
                                got_result = true;
                                break;
                            }
                            _ => eprintln!("  Other message type"),
                        }
                    }
                    Some(Err(e)) => {
                        eprintln!("Error: {e}");
                        break;
                    }
                    None => {
                        eprintln!("Stream ended after {count} messages");
                        break;
                    }
                }
            }
            _ = tokio::time::sleep(tokio::time::Duration::from_secs(60)) => {
                eprintln!("Timeout after {count} messages");
                break;
            }
        }
    }

    assert!(got_result, "Expected to receive a result message");
}
