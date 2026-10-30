//! Debug test for CLI spawning.

use claude_rs::cli::{Cli, CommandBuilder, find_executable};
use claude_rs::message::Message;

#[tokio::test]
#[ignore]
async fn test_debug_cli() {
    use claude_rs::options::QueryOptions;

    let options = QueryOptions::new().max_turns(1);

    // First, test that we can find the executable
    let exe = find_executable().expect("Should find claude executable");
    println!("Found CLI at: {exe:?}");

    // Build command args
    let mut builder = CommandBuilder::from_options(&options);
    builder.prompt("Say just 'test'");
    let args = builder.build();
    println!("Args: {args:?}");

    // Try spawning
    let cli = Cli::spawn(args);
    match cli {
        Ok(mut cli) => {
            println!("CLI spawned successfully");

            // Try to receive messages
            let mut count = 0;
            loop {
                tokio::select! {
                    msg = cli.recv() => {
                        match msg {
                            Some(Ok(m)) => {
                                count += 1;
                                println!("Message {}: {:?}", count, std::mem::discriminant(&m));
                                match &m {
                                    Message::System(s) => println!("  System: {:?}", s.subtype),
                                    Message::Assistant(a) => println!("  Assistant: {}", a.text()),
                                    Message::Result(r) => {
                                        println!("  Result: success={}", r.is_success());
                                        break;
                                    }
                                    _ => {}
                                }
                            }
                            Some(Err(e)) => {
                                println!("Error: {e}");
                                break;
                            }
                            None => {
                                println!("Stream ended after {count} messages");
                                break;
                            }
                        }
                    }
                    _ = tokio::time::sleep(tokio::time::Duration::from_secs(30)) => {
                        println!("Timeout after {count} messages");
                        break;
                    }
                }
            }

            assert!(count > 0, "Expected at least one message");
        }
        Err(e) => {
            panic!("Failed to spawn CLI: {e}");
        }
    }
}
