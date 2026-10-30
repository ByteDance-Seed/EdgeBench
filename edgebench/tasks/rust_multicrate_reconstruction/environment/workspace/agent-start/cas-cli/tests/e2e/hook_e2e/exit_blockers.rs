use super::*;

/// Compute the session-based agent ID that hooks will use in tests
fn compute_test_agent_id() -> String { todo!() }

/// Test that Stop hook blocks agent when working on a subtask with incomplete epic siblings
///
/// Scenario:
/// 1. Create an epic
/// 2. Create multiple subtasks under the epic
/// 3. Agent starts/claims ONE subtask
/// 4. Agent tries to stop
/// 5. Stop hook should block because other subtasks are incomplete
#[test]
#[ignore]
fn test_stop_hook_blocks_on_incomplete_epic_subtasks() {
    let env = HookTestEnv::new();

    // 1. Use session-based agent ID for hook scoping
    let agent_id = compute_test_agent_id();
    println!("Computed agent ID: {}", agent_id);

    // Register agent via direct SQLite
    env.register_agent(&agent_id, "test-agent-epic", "primary");

    // 2. Create an epic
    let epic_id = env.cas.create_task_with_options("Test Epic for Exit Blocker", Some("epic"), None, false);
    println!("Created epic: {}", epic_id);

    // 3. Create subtasks under the epic (with ParentChild dependency)
    let subtask1_id = env.cas.create_task("Subtask 1");
    env.add_dependency(&subtask1_id, &epic_id, "parent-child");
    println!("Created subtask 1: {}", subtask1_id);

    let subtask2_id = env.cas.create_task("Subtask 2");
    env.add_dependency(&subtask2_id, &epic_id, "parent-child");
    println!("Created subtask 2: {}", subtask2_id);

    // 4. Agent starts/claims subtask 1 and adds epic to working_epics
    env.cas.start_task(&subtask1_id);
    env.set_task_assignee(&subtask1_id, &agent_id);
    env.add_working_epic(&agent_id, &epic_id);
    println!("Agent started subtask 1");

    // 5. Write the session_id to current_session file (simulating SessionStart)
    let session_file = env.dir().join(".cas").join("current_session");
    std::fs::write(&session_file, &agent_id).expect("Failed to write session file");
    println!("Wrote session_id to current_session: {}", agent_id);

    // 6. Enable exit blockers in config
    let config_path = env.dir().join(".cas").join("config.toml");
    std::fs::write(&config_path, "[tasks]\nblock_exit_on_open = true\n")
        .expect("Failed to write config");
    println!("Enabled block_exit_on_open in config");

    // 7. Call Stop hook
    let (_, stop_stdout) = env.run_stop_hook();
    println!("Stop hook stdout: {}", stop_stdout);

    // 8. Verify the Stop hook output indicates blocking due to incomplete epic subtasks
    let combined_output = stop_stdout.to_lowercase();

    // Should mention blocking or tasks or epic
    let is_blocked = combined_output.contains("block")
        || combined_output.contains("subtask")
        || combined_output.contains("epic")
        || combined_output.contains("task")
        || combined_output.contains("complete")
        || combined_output.contains("finish")
        || combined_output.contains("remain");

    // The hook output should indicate there are tasks to complete
    assert!(
        is_blocked || stop_stdout.contains(&subtask2_id),
        "Stop hook should indicate incomplete epic subtasks. Got stdout: '{}'",
        stop_stdout,
    );

    // 9. Now close subtask 1 and subtask 2
    env.cas.close_task(&subtask1_id);
    env.cas.close_task(&subtask2_id);
    println!("Closed both subtasks");

    // 10. Call Stop hook again - should NOT block now
    let (_, stop_stdout2) = env.run_stop_hook();
    println!("Stop hook after closing subtasks: {}", stop_stdout2);

    // Should succeed or at least not mention incomplete tasks
    let combined_output2 = stop_stdout2.to_lowercase();
    let still_blocked = combined_output2.contains("subtask 2")
        || (combined_output2.contains("block") && combined_output2.contains("task"));

    assert!(
        !still_blocked,
        "Stop hook should not block after all subtasks are closed. Got: '{}'",
        stop_stdout2
    );
}

/// Test that agent is blocked even after closing their subtask if epic has other incomplete subtasks

/// Test that Stop hook does NOT block when working on standalone task (no epic)
#[test]
#[ignore]
fn test_stop_hook_allows_standalone_task() {
    let env = HookTestEnv::new();

    // Register an agent
    let agent_id = compute_test_agent_id();
    env.register_agent(&agent_id, "test-agent-standalone", "primary");

    // Create a standalone task (no epic)
    let task_id = env.cas.create_task("Standalone Task");

    // Start/claim the task
    env.cas.start_task(&task_id);
    env.set_task_assignee(&task_id, &agent_id);

    // Close the task
    env.cas.close_task(&task_id);

    // Write session file
    let session_file = env.dir().join(".cas").join("current_session");
    std::fs::write(&session_file, &agent_id).expect("Failed to write session file");

    // Enable exit blockers
    let config_path = env.dir().join(".cas").join("config.toml");
    std::fs::write(&config_path, "[tasks]\nblock_exit_on_open = true\n")
        .expect("Failed to write config");

    // Call Stop hook using env fixture method
    let (_, stop_stdout) = env.run_stop_hook();
    println!("Stop hook for standalone task: {}", stop_stdout);

    // Should NOT block - task is closed and no epic involvement
    let combined_output = stop_stdout.to_lowercase();
    let is_blocked = combined_output.contains("block")
        && (combined_output.contains("task") || combined_output.contains("epic"));

    assert!(
        !is_blocked,
        "Stop hook should not block for closed standalone task. Got: '{}'",
        stop_stdout
    );
}

/// Test that session-based agent ID is used for working_epics
#[test]
#[ignore]
fn test_session_agent_id_and_working_epics() {
    let env = HookTestEnv::new();

    // 1. Create an epic
    let epic_id = env.cas.create_task_with_options("Epic for Session ID Test", Some("epic"), None, false);
    println!("Created epic: {}", epic_id);

    // 2. Create a subtask under the epic
    let subtask_id = env.cas.create_task("Subtask A");
    env.add_dependency(&subtask_id, &epic_id, "parent-child");
    println!("Created subtask: {}", subtask_id);

    // 3. Register agent with session ID
    env.register_agent(HOOK_TEST_SESSION_ID, "session-agent", "primary");
    println!("Registered agent with session ID: {}", HOOK_TEST_SESSION_ID);

    // 4. Start subtask with the session-based agent ID
    env.cas.start_task(&subtask_id);
    env.set_task_assignee(&subtask_id, HOOK_TEST_SESSION_ID);
    env.add_working_epic(HOOK_TEST_SESSION_ID, &epic_id);
    println!("Started subtask with session-based agent ID");

    // 5. Verify working_epics was populated correctly
    let working_epics = env.get_working_epics();
    println!("Working epics in DB: {:?}", working_epics);

    assert!(
        !working_epics.is_empty(),
        "working_epics should have entries"
    );
    assert!(
        working_epics
            .iter()
            .any(|(aid, eid)| aid == HOOK_TEST_SESSION_ID && eid == &epic_id),
        "working_epics should contain agent_id={} with epic_id={}",
        HOOK_TEST_SESSION_ID,
        epic_id
    );

    println!("SUCCESS: Session-based agent ID and working_epics verified");
}

// =============================================================================
// Real Claude Session E2E Tests (using claude_rs with CAS MCP)
// =============================================================================

// Test that Stop hook blocks when epic has incomplete subtasks using a real Claude session.
// This test uses claude_rs to run a real Claude Code session with CAS MCP server and verifies:
// 1. CAS MCP server responds to tool calls
// 2. Session ID is correctly propagated
// 3. working_epics is populated when starting epic subtasks
// 4. Stop hook correctly blocks when epic has incomplete subtasks
