#[tokio::test]
#[ignore]
async fn test_claude_spawn_with_epic() {
    let env = HookTestEnv::new();

    println!("Test environment: {:?}", env.dir());

    let result = session(
        QueryOptions::new()
            .model("haiku")
            .cwd(env.dir())
            .mcp_config(env.mcp_config_path())
            .max_turns(6)
            .allow_tool("mcp__cas__coordination")
            .allow_tool("mcp__cas__task"),
        |mut sess| async move {
            // Step 1: Create an epic
            sess.send(
                "First, use mcp__cas__task with action='create', title='Factory Test Epic', \
                and task_type='epic'. Then use mcp__cas__coordination with action='spawn_workers', \
                count=2, and worker_names='alpha,beta'. Report the results of both operations.",
            )
            .await?;

            loop {
                let msg = sess.await_response(None).await?;
                if let Message::Assistant(ref a) = msg {
                    println!("Assistant: {}", a.text());
                }
                if let Message::Result(ref r) = msg {
                    return Ok(r.clone());
                }
            }
        },
    )
    .await;

    match result {
        Ok(r) => {
            let text = r.result.as_deref().unwrap_or("");
            println!("\nFinal result: {}", text);

            // Verify spawn queue has an entry
            let cas_root = env.dir().join(".cas");
            let queue = cas::store::open_spawn_queue_store(&cas_root).expect("open spawn queue");
            let entries = queue.peek(10).expect("peek");
            println!("Spawn queue entries: {}", entries.len());
            for entry in &entries {
                println!(
                    "  action={:?} workers={:?} isolate={}",
                    entry.action, entry.worker_names, entry.isolate
                );
            }
            assert!(
                !entries.is_empty(),
                "Spawn queue should have at least 1 entry"
            );
        }
        Err(e) => {
            panic!("Session failed: {:?}", e);
        }
    }
}

#[tokio::test]
#[ignore]
async fn test_claude_worker_status() {
    let env = HookTestEnv::new();

    // Pre-register a worker so there's something to report
    let db_path = env.db_path();
    let conn = rusqlite::Connection::open(&db_path).expect("open db");
    let now = chrono::Utc::now().to_rfc3339();
    conn.execute(
        "INSERT INTO agents (id, name, role, status, registered_at, last_heartbeat) \
         VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
        rusqlite::params!["worker-1-id", "wolf", "worker", "active", &now, &now],
    )
    .expect("insert worker");

    let result = session(
        QueryOptions::new()
            .model("haiku")
            .cwd(env.dir())
            .mcp_config(env.mcp_config_path())
            .max_turns(3)
            .allow_tool("mcp__cas__coordination"),
        |mut sess| async move {
            sess.send(
                "Use mcp__cas__coordination with action='worker_status'. \
                Report exactly what workers are listed.",
            )
            .await?;

            loop {
                let msg = sess.await_response(None).await?;
                if let Message::Assistant(ref a) = msg {
                    println!("Assistant: {}", a.text());
                }
                if let Message::Result(ref r) = msg {
                    return Ok(r.clone());
                }
            }
        },
    )
    .await;

    match result {
        Ok(r) => {
            let text = r.result.as_deref().unwrap_or("");
            println!("\nFinal result: {}", text);
            let lower = text.to_lowercase();
            assert!(
                lower.contains("wolf") || lower.contains("worker"),
                "Should mention the worker. Got: {}",
                text
            );
        }
        Err(e) => {
            panic!("Session failed: {:?}", e);
        }
    }
}

#[tokio::test]
#[ignore]
async fn test_claude_send_message() {
    let env = HookTestEnv::new();

    let result = session(
        QueryOptions::new()
            .model("haiku")
            .cwd(env.dir())
            .mcp_config(env.mcp_config_path())
            .max_turns(4)
            .allow_tool("mcp__cas__coordination")
            .allow_tool("mcp__cas__coordination"),
        |mut sess| async move {
            sess.send(
                "Use mcp__cas__coordination with action='message', \
                target='wolf', message='please check test results', \
                summary='Check test results'. Report what happened.",
            )
            .await?;

            loop {
                let msg = sess.await_response(None).await?;
                if let Message::Assistant(ref a) = msg {
                    println!("Assistant: {}", a.text());
                }
                if let Message::Result(ref r) = msg {
                    return Ok(r.clone());
                }
            }
        },
    )
    .await;

    match result {
        Ok(r) => {
            let text = r.result.as_deref().unwrap_or("");
            println!("\nFinal result: {}", text);

            // Check prompt queue for the injected message
            let cas_root = env.dir().join(".cas");
            let queue = cas::store::open_prompt_queue_store(&cas_root).expect("open prompt queue");
            let entries = queue.peek_all(10).expect("peek");
            println!("Prompt queue entries: {}", entries.len());
            for entry in &entries {
                println!(
                    "  target={} prompt={}",
                    entry.target,
                    &entry.prompt[..80.min(entry.prompt.len())]
                );
            }

            // The message should be in the queue
            if !entries.is_empty() {
                assert!(
                    entries.iter().any(|e| e.target == "wolf"),
                    "Should have message for wolf"
                );
                assert!(
                    entries
                        .iter()
                        .any(|e| e.prompt.contains("please check test results")),
                    "Should contain the message text"
                );
            }
        }
        Err(e) => {
            panic!("Session failed: {:?}", e);
        }
    }
}
