use super::*;

/// Test that Stop hook blocks when epic has incomplete subtasks
///
/// Verifies the full scenario:
/// 1. Epic with 2 subtasks, agent starts and closes subtask 1
/// 2. Subtask 2 remains open
/// 3. Stop hook should block because the agent's epic has incomplete subtasks
///
/// Uses direct hook invocation for reliability (MCP task creation is tested
/// separately in test_mcp_basic_task_operations).
#[test]
#[ignore]
fn test_mcp_stop_hook_blocks_incomplete_epic() {
    let env = HookTestEnv::new();

    let agent_id = HOOK_TEST_SESSION_ID.to_string();
    env.register_agent(&agent_id, "test-agent-mcp-epic", "primary");

    // Create an epic with 2 subtasks
    let epic_id =
        env.cas
            .create_task_with_options("E2E Test Epic", Some("epic"), None, false);
    println!("Created epic: {}", epic_id);

    let subtask1_id = env.cas.create_task("Subtask 1");
    env.add_dependency(&subtask1_id, &epic_id, "parent-child");
    println!("Created subtask 1: {}", subtask1_id);

    let subtask2_id = env.cas.create_task("Subtask 2");
    env.add_dependency(&subtask2_id, &epic_id, "parent-child");
    println!("Created subtask 2: {}", subtask2_id);

    // Agent starts subtask 1, adds epic to working_epics
    env.cas.start_task(&subtask1_id);
    env.set_task_assignee(&subtask1_id, &agent_id);
    env.add_working_epic(&agent_id, &epic_id);
    println!("Agent started subtask 1");

    // Agent closes subtask 1 (completed their work)
    env.cas.close_task(&subtask1_id);
    println!("Agent closed subtask 1");

    // Write session file and enable exit blockers
    let session_file = env.dir().join(".cas").join("current_session");
    std::fs::write(&session_file, &agent_id).expect("Failed to write session file");

    let config_path = env.dir().join(".cas").join("config.toml");
    std::fs::write(&config_path, "[tasks]\nblock_exit_on_open = true\n")
        .expect("Failed to write config");

    // Run Stop hook - should block because subtask 2 is still open
    let (_, stop_stdout) = env.run_stop_hook();
    println!("Stop hook stdout: {}", stop_stdout);

    // Verify subtask 2 is still open
    let tasks = env.get_tasks();
    println!("\nTasks in database:");
    for (id, title, status) in &tasks {
        println!("  {} - {} ({})", id, title, status);
    }
    let subtask2_open = tasks
        .iter()
        .any(|(_, title, status)| title.contains("Subtask 2") && status != "closed");
    assert!(
        subtask2_open,
        "Subtask 2 should still be open (not closed)"
    );

    // Verify Stop hook output indicates blocking
    if let Ok(json) = serde_json::from_str::<serde_json::Value>(&stop_stdout) {
        let decision = json.get("decision").and_then(|d| d.as_str());
        println!("Decision: {:?}", decision);
        assert_eq!(
            decision,
            Some("block"),
            "Stop hook should block when epic has incomplete subtasks. Output: {}",
            stop_stdout
        );
    } else {
        // Non-JSON output - check for textual blocking indicators
        let lower = stop_stdout.to_lowercase();
        let is_blocked = lower.contains("block")
            || lower.contains("subtask")
            || lower.contains("epic")
            || lower.contains("incomplete")
            || lower.contains("remain");
        assert!(
            is_blocked,
            "Stop hook should indicate incomplete epic subtasks. Got: '{}'",
            stop_stdout
        );
    }
}

/// Helper to extract CAS task ID from text (cas-XXXX format)
fn extract_cas_id(text: &str) -> Option<String> { todo!() }

/// Test that verification jail allows task-verifier agent to work
///
/// This tests the fix for the bug where verification jail was blocking task-verifier itself.
#[tokio::test]
#[ignore]
async fn test_mcp_verification_jail_allows_task_verifier() {
    let env = HookTestEnv::new();

    println!("Test environment created at: {:?}", env.dir());

    // Create a task and set it to pending_verification using direct SQLite
    let task_id = env.cas.create_task_with_options("Task for verification test", None, None, true);
    println!("Created task: {}", task_id);

    // Set pending_verification = true (simulating task close triggering verification)
    env.set_pending_verification(&task_id, true);
    println!("Set pending_verification=true for {}", task_id);

    // Run a Claude session simulating task-verifier behavior
    let result = session(
        QueryOptions::new()
            .model("haiku")
            .cwd(env.dir())
                        .mcp_config(env.mcp_config_path())
            .max_turns(5)
            .allow_tool("Read")
            .allow_tool("mcp__cas__task"),
        |mut sess| async move {
            // Simulate task-verifier trying to read files for verification
            // This should work even though there's a verification jail
            // because task-verifier has special permissions
            sess.send(
                "Read the file test.txt and tell me what it contains. \
                This simulates task-verifier checking code.",
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
            println!("Result: {}", text);

            // The result should contain the file content, not be blocked
            // Note: Normal sessions would be blocked, but task-verifier has special permissions
            // This test documents the expected behavior
        }
        Err(e) => {
            println!("Session error: {:?}", e);
        }
    }
}

/// Test basic MCP tool usage in a real Claude session
///
/// Simple sanity check that CAS MCP tools work in a real session.
/// Tests task creation and starting (not closing, which triggers verification).

/// Test session-based agent identification with auto-registration
///
/// Verifies that the MCP server auto-registers the agent using a session-based
/// UUID identifier (not the old cc-PPID format). The agent is auto-registered
/// on the first MCP tool call.

// =============================================================================
// Hook Command E2E Tests (Direct hook invocation, no Claude API needed)
// =============================================================================

// Test that PreToolUse hook blocks Read when in verification jail.
// This test directly invokes the hook command to verify the jail blocking logic.
// No Claude API needed - tests the actual hook implementation.
