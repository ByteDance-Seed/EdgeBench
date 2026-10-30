//! Factory Lifecycle E2E Tests (Multi-Session)
//!
//! Tests the real factory user scenarios: supervisor spawns workers, injects
//! messages, workers respond, and the test harness acts as the factory daemon
//! bridging the prompt queue between sessions.
//!
//! # Running
//! These tests require tmux (to avoid CLAUDECODE env var conflict):
//! ```bash
//! cargo test --test e2e_test factory_e2e::lifecycle \
//!     --features claude_rs_e2e -- --ignored --nocapture
//! ```

use crate::fixtures::HookTestEnv;
use claude_rs::{Message, QueryOptions, session};

// =============================================================================
// Helpers
// =============================================================================

fn peek_prompts_for(env: &HookTestEnv, target: &str) -> Vec<cas::store::QueuedPrompt> { todo!() }

fn peek_spawn_requests(env: &HookTestEnv) -> Vec<cas::store::SpawnRequest> { todo!() }

// =============================================================================
// Test 1: Supervisor creates epic and spawns workers
// =============================================================================

#[tokio::test]
#[ignore]
async fn test_supervisor_creates_epic_and_spawns_workers() {
    let env = HookTestEnv::new();
    env.disable_verification();

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
            sess.send(
                "Do two things in sequence:\n\
                1. Use mcp__cas__task with action='create', title='Lifecycle Test Epic', task_type='epic'.\n\
                2. Use mcp__cas__coordination with action='spawn_workers', count=2, worker_names='alpha,beta'.\n\
                Report the results of both operations.",
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

            // Verify spawn queue
            let entries = peek_spawn_requests(&env);
            println!("Spawn queue entries: {}", entries.len());
            for entry in &entries {
                println!(
                    "  action={:?} workers={:?}",
                    entry.action, entry.worker_names
                );
            }
            assert!(
                !entries.is_empty(),
                "Spawn queue should have at least 1 entry"
            );
            assert!(
                entries[0].worker_names.contains(&"alpha".to_string()),
                "Should contain worker alpha: {:?}",
                entries[0].worker_names
            );
            assert!(
                entries[0].worker_names.contains(&"beta".to_string()),
                "Should contain worker beta: {:?}",
                entries[0].worker_names
            );

            // Verify epic was created
            let tasks = env.get_tasks();
            let epic = tasks
                .iter()
                .find(|(_, title, _)| title.contains("Lifecycle"));
            assert!(epic.is_some(), "Epic should exist in tasks: {:?}", tasks);
        }
        Err(e) => panic!("Session failed: {:?}", e),
    }
}

// =============================================================================
// Test 2: Supervisor injects message to worker
// =============================================================================

#[tokio::test]
#[ignore]
async fn test_supervisor_injects_message_to_worker() {
    let env = HookTestEnv::new();

    // Pre-register supervisor and worker
    env.register_agent_with_role("sup-id-1", "boss-fox", "supervisor");
    env.register_agent_with_role("wrk-id-1", "alpha", "worker");

    println!("Test environment: {:?}", env.dir());

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
                "Use mcp__cas__coordination with action='message', target='alpha', \
                message='Run the test suite and report results', summary='Run tests'. Report what happened.",
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

            // Verify prompt queue
            let prompts = peek_prompts_for(&env, "alpha");
            println!("Prompts for alpha: {}", prompts.len());
            for p in &prompts {
                println!(
                    "  target={} prompt={}...",
                    p.target,
                    &p.prompt[..80.min(p.prompt.len())]
                );
            }
            assert!(!prompts.is_empty(), "Should have a queued prompt for alpha");
            assert!(
                prompts[0].prompt.contains("Run the test suite"),
                "Prompt should contain message text: {}",
                &prompts[0].prompt[..200.min(prompts[0].prompt.len())]
            );
            assert!(
                prompts[0].prompt.contains("<message from="),
                "Prompt should be XML-wrapped: {}",
                &prompts[0].prompt[..200.min(prompts[0].prompt.len())]
            );
        }
        Err(e) => panic!("Session failed: {:?}", e),
    }
}

// =============================================================================
// Test 3: Worker sends message to supervisor
// =============================================================================

#[tokio::test]
#[ignore]
async fn test_worker_sends_message_to_supervisor() {
    let env = HookTestEnv::new();

    // Pre-register supervisor and worker
    env.register_agent_with_role("sup-id-2", "boss-fox", "supervisor");
    env.register_agent_with_role("wrk-id-2", "alpha", "worker");

    println!("Test environment: {:?}", env.dir());

    let cas_root_str = env.dir().join(".cas").to_string_lossy().to_string();

    let result = session(
        QueryOptions::new()
            .model("haiku")
            .cwd(env.dir())
            .mcp_config(env.mcp_config_path())
            .max_turns(3)
            .env_var("CAS_AGENT_NAME", "alpha")
            .env_var("CAS_AGENT_ROLE", "worker")
            .env_var("CAS_SUPERVISOR_NAME", "boss-fox")
            .env_var("CAS_ROOT", &cas_root_str)
            .allow_tool("mcp__cas__coordination"),
        |mut sess| async move {
            sess.send(
                "Use mcp__cas__coordination with action='message', target='supervisor', \
                message='Task complete, all tests passing'. Report what happened.",
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

            // Verify prompt queue has message targeting the supervisor
            let prompts = peek_prompts_for(&env, "boss-fox");
            println!("Prompts for boss-fox: {}", prompts.len());
            for p in &prompts {
                println!(
                    "  source={} target={} prompt={}...",
                    p.source,
                    p.target,
                    &p.prompt[..80.min(p.prompt.len())]
                );
            }
            assert!(
                !prompts.is_empty(),
                "Should have a queued prompt for boss-fox (supervisor)"
            );
            assert!(
                prompts[0].prompt.contains("Task complete"),
                "Prompt should contain worker's message: {}",
                &prompts[0].prompt[..200.min(prompts[0].prompt.len())]
            );
        }
        Err(e) => panic!("Session failed: {:?}", e),
    }
}

// =============================================================================
// Test 4: Full message round trip (supervisor → worker → supervisor)
// =============================================================================

#[tokio::test]
#[ignore]
async fn test_full_message_round_trip() {
    let env = HookTestEnv::new();
    env.disable_verification();

    // Pre-register supervisor and worker
    env.register_agent_with_role("sup-rt-id", "boss-fox", "supervisor");
    env.register_agent_with_role("wrk-rt-id", "alpha", "worker");

    // Create epic for factory context
    let epic_id = env
        .cas
        .create_task_with_options("Round Trip Epic", Some("epic"), None, false);
    println!("Created epic: {}", epic_id);

    let token = format!("RT_TOKEN_{}", std::process::id());
    println!("Test environment: {:?}", env.dir());
    println!("Round-trip token: {}", token);

    // === Phase 1: Supervisor sends message ===
    println!("\n=== Phase 1: Supervisor injects message ===");
    let token_clone = token.clone();
    let result = session(
        QueryOptions::new()
            .model("haiku")
            .cwd(env.dir())
            .mcp_config(env.mcp_config_path())
            .max_turns(4)
            .allow_tool("mcp__cas__coordination")
            .allow_tool("mcp__cas__coordination"),
        |mut sess| async move {
            sess.send(&format!(
                "Use mcp__cas__coordination with action='message', target='alpha', \
                message='{}: please confirm receipt', summary='Confirm receipt'. Report what happened.",
                token_clone
            ))
            .await?;

            loop {
                let msg = sess.await_response(None).await?;
                if let Message::Assistant(ref a) = msg {
                    println!("Supervisor: {}", a.text());
                }
                if let Message::Result(ref r) = msg {
                    return Ok(r.clone());
                }
            }
        },
    )
    .await;
    assert!(
        result.is_ok(),
        "Supervisor session failed: {:?}",
        result.err()
    );

    // Checkpoint: verify message is in prompt queue for alpha
    let prompts_for_alpha = peek_prompts_for(&env, "alpha");
    println!("Prompts queued for alpha: {}", prompts_for_alpha.len());
    assert!(
        !prompts_for_alpha.is_empty(),
        "Supervisor should have queued a message for alpha"
    );
    let sup_message = &prompts_for_alpha[0].prompt;
    assert!(
        sup_message.contains(&token),
        "Message should contain token '{}': {}",
        token,
        &sup_message[..200.min(sup_message.len())]
    );
    println!("Checkpoint passed: message with token found in prompt queue");

    // === Phase 2: Worker receives and responds ===
    println!("\n=== Phase 2: Worker responds ===");
    let cas_root_str = env.dir().join(".cas").to_string_lossy().to_string();
    let token_clone2 = token.clone();

    let result = session(
        QueryOptions::new()
            .model("haiku")
            .cwd(env.dir())
            .mcp_config(env.mcp_config_path())
            .max_turns(4)
            .env_var("CAS_AGENT_NAME", "alpha")
            .env_var("CAS_AGENT_ROLE", "worker")
            .env_var("CAS_SUPERVISOR_NAME", "boss-fox")
            .env_var("CAS_ROOT", &cas_root_str)
            .allow_tool("mcp__cas__coordination"),
        |mut sess| async move {
            sess.send(&format!(
                "You received a message from your supervisor containing the token '{}'.\n\
                Use mcp__cas__coordination with action='message', target='supervisor', \
                message='Confirmed receipt of {}'. Report what happened.",
                token_clone2, token_clone2
            ))
            .await?;

            loop {
                let msg = sess.await_response(None).await?;
                if let Message::Assistant(ref a) = msg {
                    println!("Worker: {}", a.text());
                }
                if let Message::Result(ref r) = msg {
                    return Ok(r.clone());
                }
            }
        },
    )
    .await;
    assert!(result.is_ok(), "Worker session failed: {:?}", result.err());

    // Verify: prompt queue has worker's response targeting supervisor
    let prompts_for_sup = peek_prompts_for(&env, "boss-fox");
    println!("\nPrompts queued for boss-fox: {}", prompts_for_sup.len());
    for p in &prompts_for_sup {
        println!(
            "  source={} prompt={}...",
            p.source,
            &p.prompt[..100.min(p.prompt.len())]
        );
    }
    assert!(
        !prompts_for_sup.is_empty(),
        "Worker should have queued a response for boss-fox"
    );
    let worker_response = prompts_for_sup.iter().find(|p| p.prompt.contains(&token));
    assert!(
        worker_response.is_some(),
        "Worker's response should contain token '{}'. Prompts: {:?}",
        token,
        prompts_for_sup
            .iter()
            .map(|p| &p.prompt[..100.min(p.prompt.len())])
            .collect::<Vec<_>>()
    );

    println!("\n=== Round trip complete ===");
    println!("Supervisor → alpha (prompt queue) → Worker → boss-fox (prompt queue)");
}

// =============================================================================
// Test 5: Worker status reflects registered agents
// =============================================================================

#[tokio::test]
#[ignore]
async fn test_worker_status_reflects_registered_agents() {
    let env = HookTestEnv::new();

    // Pre-register supervisor and 2 workers
    env.register_agent_with_role("sup-id-3", "boss-fox", "supervisor");
    env.register_agent_with_role("wrk-id-3a", "alpha", "worker");
    env.register_agent_with_role("wrk-id-3b", "beta", "worker");

    println!("Test environment: {:?}", env.dir());

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
                Report exactly how many workers are listed and their names.",
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
                lower.contains("alpha"),
                "Should mention worker alpha. Got: {}",
                text
            );
            assert!(
                lower.contains("beta"),
                "Should mention worker beta. Got: {}",
                text
            );
        }
        Err(e) => panic!("Session failed: {:?}", e),
    }
}

// =============================================================================
// Test 6: Supervisor shuts down workers
// =============================================================================

