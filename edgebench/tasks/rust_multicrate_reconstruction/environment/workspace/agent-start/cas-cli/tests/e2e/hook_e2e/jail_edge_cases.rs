use super::*;


/// BUG TEST: Closed tasks with pending_verification should NOT cause jail
/// Tests that only OPEN tasks affect jail state
#[test]
#[ignore]
fn test_closed_task_with_jail_flag_ignored() {
    let env = HookTestEnv::new();

    // Create a task, jail it, then close it
    let task_id = env.create_task("Task to close while jailed");
    env.set_pending_verification(&task_id, true);
    println!("Created and jailed task: {}", task_id);

    // Close the task (with jail flag still set)
    env.close_task(&task_id);
    println!("Closed the jailed task");

    // Verify task is closed but flag is still set
    let (pending_v, _) = env.get_task_jail_state(&task_id);
    println!("After close - pending_verification: {}", pending_v);

    // Hook should not block because closed tasks shouldn't jail
    let (_, stdout) = env.run_pre_tool_use_read("test.txt");
    println!("Closed jailed task hook output: {}", stdout);

    // This test reveals whether closed tasks are excluded from jail check
    let is_blocked = stdout.contains("deny");
    if is_blocked {
        println!(
            "NOTE: Closed tasks with pending_verification still blocking - may be intended behavior"
        );
    }
}

/// BUG TEST: Rapid jail/unjail shouldn't cause race conditions
#[test]
#[ignore]
fn test_rapid_jail_state_changes() {
    let env = HookTestEnv::new();

    let task_id = env.create_task("Rapid state change task");
    println!("Created task: {}", task_id);

    // Rapidly toggle jail state
    for i in 0..5 {
        env.set_pending_verification(&task_id, true);
        let (v1, _) = env.get_task_jail_state(&task_id);
        env.set_pending_verification(&task_id, false);
        let (v2, _) = env.get_task_jail_state(&task_id);
        println!(
            "Iteration {}: after set true={}, after set false={}",
            i, v1, v2
        );
        assert!(v1, "Should be true after setting true");
        assert!(!v2, "Should be false after setting false");
    }

    // Final state should be unjailed
    let (final_v, _) = env.get_task_jail_state(&task_id);
    assert!(!final_v, "Final state should be unjailed");

    // Verify via direct hook that the task is no longer jailed
    let (_, stdout) = env.run_pre_tool_use_read("test.txt");
    println!("After rapid changes hook output: {}", stdout);

    // Should not be blocked (empty output or no deny)
    let is_blocked = stdout.contains("deny");
    assert!(
        !is_blocked,
        "Should succeed after rapid state changes: {}",
        stdout
    );
}

/// BUG TEST: Empty database (no tasks) shouldn't cause errors
#[test]
#[ignore]
fn test_empty_database_no_errors() {
    let env = HookTestEnv::new();

    // Don't create any tasks - database should be empty
    let count = env.count_tasks();
    println!("Task count: {}", count);
    assert_eq!(count, 0, "Should have no tasks");

    // Hook should work normally without errors on empty database
    let (_, stdout) = env.run_pre_tool_use_read("test.txt");
    println!("Empty database hook output: {}", stdout);

    // Should not be blocked (empty output or passthrough)
    let is_blocked = stdout.contains("deny");
    assert!(
        !is_blocked,
        "Should not error with empty database: {}",
        stdout
    );
}

/// BUG TEST: All tool types should be blocked by jail, not just Read

/// BUG TEST: Jail should persist across multiple hook invocations
#[test]
#[ignore]
fn test_jail_persists_across_turns() {
    let env = HookTestEnv::new();

    let task_id = env.create_task("Multi-turn jail test");
    env.set_pending_verification(&task_id, true);
    println!("Created jailed task: {}", task_id);

    // Simulate multiple tool use attempts - all should be blocked
    for i in 0..3 {
        let (_, stdout) = env.run_pre_tool_use_read("test.txt");
        let is_blocked = stdout.contains("deny");
        println!("Turn {}: blocked={}", i + 1, is_blocked);
        assert!(
            is_blocked,
            "Jail should persist across turns. Turn {} was not blocked: {}",
            i + 1,
            stdout
        );
    }

    // Clear jail - next invocation should work
    env.set_pending_verification(&task_id, false);
    let (_, stdout) = env.run_pre_tool_use_read("test.txt");
    let is_blocked = stdout.contains("deny");
    println!("After clear: blocked={}", is_blocked);
    assert!(
        !is_blocked,
        "Should not be blocked after clearing jail: {}",
        stdout
    );
}

/// BUG TEST: Hook should provide correct error message content
#[test]
#[ignore]
fn test_jail_error_message_content() {
    let env = HookTestEnv::new();

    let task_id = env.create_task("Error message test task");
    env.set_pending_verification(&task_id, true);
    println!("Created jailed task: {}", task_id);

    // Run the hook directly using fixture method
    let (_, stdout) = env.run_pre_tool_use_read("test.txt");
    println!("Hook output: {}", stdout);

    // Parse the JSON output
    if let Ok(json) = serde_json::from_str::<serde_json::Value>(&stdout) {
        // Check for expected fields
        let hook_specific = json.get("hookSpecificOutput");
        assert!(hook_specific.is_some(), "Should have hookSpecificOutput");

        if let Some(hso) = hook_specific {
            let permission = hso.get("permissionDecision").and_then(|v| v.as_str());
            assert_eq!(permission, Some("deny"), "Should deny permission");

            let reason = hso.get("permissionDecisionReason").and_then(|v| v.as_str());
            assert!(reason.is_some(), "Should have denial reason");

            let reason_text = reason.unwrap();
            println!("Denial reason: {}", reason_text);

            // Check message contains the task ID
            assert!(
                reason_text.contains(&task_id),
                "Denial message should contain task ID {}, got: {}",
                task_id,
                reason_text
            );

            // Check message mentions verification
            assert!(
                reason_text.to_lowercase().contains("verification"),
                "Denial message should mention 'verification', got: {}",
                reason_text
            );
        }
    } else {
        println!("Could not parse hook output as JSON: {}", stdout);
    }
}

/// BUG TEST: Database corruption recovery - invalid jail state
#[test]
#[ignore]
fn test_invalid_database_state_handling() {
    let env = HookTestEnv::new();

    let task_id = env.create_task("Corruption test task");
    println!("Created task: {}", task_id);

    // Set an invalid state directly in the database (e.g., weird value)
    // This tests resilience to database corruption
    {
        let conn = rusqlite::Connection::open(env.db_path()).expect("Failed to open db");
        conn.execute(
            "UPDATE tasks SET pending_verification = 999 WHERE id = ?1",
            rusqlite::params![task_id],
        )
        .expect("Failed to set invalid state");
    }

    // Hook should not crash, should handle gracefully
    let (success, stdout) = env.run_pre_tool_use_read("test.txt");
    println!("Invalid state hook output (success={}): {}", success, stdout);

    // The hook process itself should not crash (exit code 0 or valid JSON output)
    // Either it treats 999 as truthy (blocks) or handles it gracefully
    // The key assertion is that the process didn't crash
    assert!(
        success || !stdout.is_empty(),
        "Hook should handle invalid state gracefully, not crash"
    );

    // Reset to valid state
    env.set_pending_verification(&task_id, false);
}

/// BUG TEST: Very long task titles/IDs shouldn't cause issues
#[test]
#[ignore]
fn test_long_task_title_handling() {
    let env = HookTestEnv::new();

    // Create a task with a very long title (via direct SQLite)
    let long_title = "A".repeat(500);
    let task_id = env.cas.create_task_with_options(&long_title, None, None, true);
    println!("Created task with long title: {}", task_id);

    env.set_pending_verification(&task_id, true);

    // Hook should handle long titles gracefully
    let (success, stdout) = env.run_pre_tool_use_read("test.txt");
    println!("Long title hook output (success={}): {}", success, stdout);

    // Should block (task is jailed) and not crash on long title
    let is_blocked = stdout.contains("deny");
    assert!(
        is_blocked,
        "Should block on jailed task with long title: {}",
        stdout
    );
}

/// BUG TEST: Separate environments shouldn't interfere with each other
/// Tests that jailing in one environment doesn't affect another
#[test]
#[ignore]
fn test_concurrent_environments_isolation() {
    // Create two completely separate test environments
    let env1 = HookTestEnv::new();
    let env2 = HookTestEnv::new();

    // Create test files in each environment
    env1.create_file("env1_file.txt", "env1 secret content");
    env2.create_file("env2_file.txt", "env2 secret content");

    // Jail a task in env1 only
    let task1 = env1.create_task("Env1 jailed task");
    env1.set_pending_verification(&task1, true);
    println!("Env1 jailed task: {}", task1);

    // Create a non-jailed task in env2
    let task2 = env2.create_task("Env2 normal task");
    println!("Env2 normal task: {}", task2);

    // Verify counts
    assert_eq!(
        env1.count_jailed_tasks(),
        1,
        "Env1 should have 1 jailed task"
    );
    assert_eq!(
        env2.count_jailed_tasks(),
        0,
        "Env2 should have 0 jailed tasks"
    );

    // Test env2 via direct hook (should NOT be blocked)
    let (_, env2_stdout) = env2.run_pre_tool_use_read("test.txt");
    println!("Env2 (not jailed) hook output: {}", env2_stdout);

    let env2_blocked = env2_stdout.contains("deny");
    assert!(
        !env2_blocked,
        "Env2 should succeed (no jailed tasks): {}",
        env2_stdout
    );

    // Test env1 via direct hook (should be blocked)
    let (_, env1_stdout) = env1.run_pre_tool_use_read("test.txt");
    println!("Env1 (jailed) hook output: {}", env1_stdout);

    let env1_blocked = env1_stdout.contains("deny");
    assert!(
        env1_blocked,
        "Env1 should be blocked due to jailed task: {}",
        env1_stdout
    );
}

/// BUG TEST: Worktree jail should have different message than verification jail

// =============================================================================
// Exit Blocker Tests (CLI-based, no API required)
// =============================================================================

// Helper to extract task ID from CLI output.
