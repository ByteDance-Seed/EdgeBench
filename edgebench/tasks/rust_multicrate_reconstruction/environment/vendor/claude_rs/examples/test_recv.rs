use claude_rs::{Message, QueryOptions, start_query};

#[tokio::main]
async fn main() -> claude_rs::Result<()> {
    println!("Starting query...");
    let mut q = start_query(QueryOptions::new().max_turns(1))?;

    println!("Sending message...");
    q.send_message("Say just 'Hello'").await?;
    println!("Message sent, calling recv()...");

    let mut count = 0;
    while let Some(msg) = q.recv().await {
        count += 1;
        println!("[{}] Got: {:?}", count, std::mem::discriminant(&msg));
        match msg {
            Ok(Message::Assistant(a)) => println!("  Text: {}", a.text()),
            Ok(Message::Result(r)) => {
                println!("  Result: {:?}", r.result);
                break;
            }
            Ok(_) => {}
            Err(e) => {
                println!("  Error: {e}");
                break;
            }
        }
    }
    println!("Done, received {count} messages");
    Ok(())
}
