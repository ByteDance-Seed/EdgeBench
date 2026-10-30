#[tokio::test]
#[ignore]
async fn test_mcp_basic_task_operations() {
    let env = HookTestEnv::new();

    println!("Test environment: {:?}", env.dir());

    let result = session(
        QueryOptions::new()
            .model("haiku")
            .cwd(env.dir())
                        .mcp_config(env.mcp_config_path())
            .max_turns(6)
            .allow_tool("mcp__cas__task")
            .allow_tool("mcp__cas__memory")
            .allow_tool("mcp__cas__search"),
        |mut sess| async move {
            // Create a task
            println!("\n=== Creating task via MCP ===");
            sess.send(
                "Use the mcp__cas__task tool with action='create' and title='MCP Test Task'. \
                Tell me the task ID that was created.",
            )
            .await?;

            let mut task_id = String::new();
            loop {
                let msg = sess.await_response(None).await?;
                if let Message::Assistant(ref a) = msg {
                    let text = a.text();
                    println!("Assistant: {}", text);
                    if let Some(id) = extract_cas_id(&text) {
                        task_id = id;
                    }
                }
                if matches!(msg, Message::Result(_)) {
                    break;
                }
            }

            assert!(!task_id.is_empty(), "Should have created a task");
            println!("Created task: {}", task_id);

            // Start the task
            println!("\n=== Starting task via MCP ===");
            sess.send(&format!(
                "Use mcp__cas__task tool with action='start' and id='{}'. Confirm it started.",
                task_id
            ))
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
            println!("\n=== Test passed ===");
            println!("Final result: {:?}", r.result);

            // Verify task was created and started
            let tasks = env.get_tasks();
            println!("\nTasks in database:");
            for (id, title, status) in &tasks {
                println!("  {} - {} ({})", id, title, status);
            }

            let test_task = tasks
                .iter()
                .find(|(_, title, _)| title.contains("MCP Test Task"));
            assert!(test_task.is_some(), "Test task should exist in database");

            let (_, _, status) = test_task.unwrap();
            assert_eq!(status, "in_progress", "Test task should be in_progress");
        }
        Err(e) => {
            panic!("Session failed: {:?}", e);
        }
    }
}

#[tokio::test]
#[ignore]
async fn test_session_based_agent_identification() {
    let env = HookTestEnv::new();

    println!("Test environment created at: {:?}", env.dir());

    // Run a minimal Claude session - just call whoami to trigger auto-registration
    let result = session(
        QueryOptions::new()
            .model("haiku")
            .cwd(env.dir())
            .mcp_config(env.mcp_config_path())
            .max_turns(3)
            .allow_tool("mcp__cas__coordination"),
        |mut sess| async move {
            sess.send(
                "Use mcp__cas__coordination with action='whoami'. Report the full agent ID.",
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
        Ok(_r) => {
            println!("\n=== Session completed, verifying session-based agent ID ===");

            // Check agents in database
            let db_path = env.dir().join(".cas").join("cas.db");
            let conn = rusqlite::Connection::open(&db_path).expect("Failed to open database");

            let agents: Vec<(String, Option<u32>)> = {
                let mut stmt = conn
                    .prepare("SELECT id, ppid FROM agents")
                    .unwrap();
                stmt.query_map([], |row| Ok((row.get(0)?, row.get(1)?)))
                    .unwrap()
                    .collect::<Result<Vec<_>, _>>()
                    .unwrap()
            };

            println!("\nAgents in database:");
            for (id, ppid) in &agents {
                println!("  ID: {} (PPID: {:?})", id, ppid);
            }

            assert!(
                !agents.is_empty(),
                "Should have at least one agent registered"
            );

            let agent_id = &agents[0].0;

            // Agent ID should be UUID format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
            let parts: Vec<&str> = agent_id.split('-').collect();
            assert!(
                parts.len() >= 4,
                "Agent ID should be UUID format (session_id), got: {}",
                agent_id
            );

            assert!(
                agent_id.chars().all(|c| c.is_ascii_hexdigit() || c == '-'),
                "Agent ID should be hex/hyphen UUID format, got: {}",
                agent_id
            );

            // Should NOT use old cc-PPID format
            assert!(
                !agent_id.starts_with("cc-"),
                "Agent ID should be session_id (UUID), not PPID-based, got: {}",
                agent_id
            );

            println!("\n=== SUCCESS: Session-based agent identification verified ===");
            println!("Agent ID (session_id): {}", agent_id);
        }
        Err(e) => {
            panic!("Session failed: {:?}", e);
        }
    }
}
