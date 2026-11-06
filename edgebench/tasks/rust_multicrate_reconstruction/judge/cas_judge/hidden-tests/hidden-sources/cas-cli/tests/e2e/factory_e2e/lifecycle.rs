#[tokio::test]
#[ignore]
async fn test_supervisor_shutdown_workers() {
    let env = HookTestEnv::new();

    // Pre-register supervisor and workers
    env.register_agent_with_role("sup-id-4", "boss-fox", "supervisor");
    env.register_agent_with_role("wrk-id-4a", "alpha", "worker");
    env.register_agent_with_role("wrk-id-4b", "beta", "worker");

    println!("Test environment: {:?}", env.dir());

    let result = session(
        QueryOptions::new()
            .model("haiku")
            .cwd(env.dir())
            .mcp_config(env.mcp_config_path())
            .max_turns(4)
            .allow_tool("mcp__cas__coordination"),
        |mut sess| async move {
            sess.send(
                "Use mcp__cas__coordination with action='shutdown_workers', \
                worker_names='alpha'. Report what happened.",
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

            // Verify spawn queue has shutdown entry
            let entries = peek_spawn_requests(&env);
            println!("Spawn queue entries: {}", entries.len());
            for entry in &entries {
                println!(
                    "  action={:?} workers={:?}",
                    entry.action, entry.worker_names
                );
            }
            assert!(!entries.is_empty(), "Should have a shutdown queue entry");
            assert_eq!(
                entries[0].action,
                cas_store::SpawnAction::Shutdown,
                "Should be a shutdown action"
            );
            assert!(
                entries[0].worker_names.contains(&"alpha".to_string()),
                "Should target alpha: {:?}",
                entries[0].worker_names
            );
        }
        Err(e) => panic!("Session failed: {:?}", e),
    }
}
