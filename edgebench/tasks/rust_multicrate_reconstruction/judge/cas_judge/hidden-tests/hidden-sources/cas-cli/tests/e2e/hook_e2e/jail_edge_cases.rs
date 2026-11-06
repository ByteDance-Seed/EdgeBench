#[test]
#[ignore]
fn test_partial_jail_clear_still_blocks() {
    let env = HookTestEnv::new();

    // Create two tasks and jail both
    let task1 = env.create_task("First jailed task");
    let task2 = env.create_task("Second jailed task");
    env.set_pending_verification(&task1, true);
    env.set_pending_verification(&task2, true);
    println!("Created and jailed tasks: {}, {}", task1, task2);

    // Verify both are jailed
    assert_eq!(env.count_jailed_tasks(), 2, "Should have 2 jailed tasks");

    // Clear jail on ONE task only
    env.set_pending_verification(&task1, false);
    println!("Cleared jail on {} only", task1);
    assert_eq!(
        env.count_jailed_tasks(),
        1,
        "Should have 1 jailed task remaining"
    );

    // Should still be blocked (one jailed task remains)
    let (_, stdout) = env.run_pre_tool_use_read("partial_test.txt");
    println!("Partial clear hook output: {}", stdout);

    let is_blocked = stdout.contains("deny");
    assert!(
        is_blocked,
        "BUG: Partial jail clear should NOT release jail! Still have {} jailed. Got: {}",
        env.count_jailed_tasks(),
        stdout
    );

    // Now clear the second task - should work
    env.set_pending_verification(&task2, false);
    assert_eq!(env.count_jailed_tasks(), 0, "Should have 0 jailed tasks");

    // Should no longer be blocked
    let (_, stdout2) = env.run_pre_tool_use_read("partial_test.txt");
    println!("After full clear hook output: {}", stdout2);

    let still_blocked = stdout2.contains("deny");
    assert!(
        !still_blocked,
        "Should not be blocked after clearing all jails: {}",
        stdout2
    );
}

#[test]
#[ignore]
fn test_jail_blocks_all_tool_types() {
    let env = HookTestEnv::new();

    let task_id = env.create_task("Test all tools blocked");
    env.set_pending_verification(&task_id, true);
    println!("Created jailed task: {}", task_id);

    // Test 1: Bash should be blocked
    let (_, bash_stdout) = env.run_pre_tool_use(
        "Bash",
        serde_json::json!({"command": "echo test"}),
    );
    let bash_blocked = bash_stdout.contains("deny");
    println!("Bash blocked: {}", bash_blocked);

    // Test 2: Write should be blocked
    let (_, write_stdout) = env.run_pre_tool_use(
        "Write",
        serde_json::json!({"file_path": "newfile.txt", "content": "test"}),
    );
    let write_blocked = write_stdout.contains("deny");
    println!("Write blocked: {}", write_blocked);

    // Test 3: Glob should be blocked
    let (_, glob_stdout) = env.run_pre_tool_use(
        "Glob",
        serde_json::json!({"pattern": "*.txt"}),
    );
    let glob_blocked = glob_stdout.contains("deny");
    println!("Glob blocked: {}", glob_blocked);

    // All tool types should be blocked by jail
    println!(
        "Tool blocking summary: Bash={}, Write={}, Glob={}",
        bash_blocked, write_blocked, glob_blocked
    );

    assert!(bash_blocked, "Bash should be blocked by jail");
    assert!(write_blocked, "Write should be blocked by jail");
    assert!(glob_blocked, "Glob should be blocked by jail");
}

#[test]
#[ignore]
fn test_different_jail_messages() {
    let env = HookTestEnv::new();

    // Test verification jail message
    let task1 = env.create_task("Verification jail message test");
    env.set_pending_verification(&task1, true);

    let (_, verify_output) = env.run_pre_tool_use_read("test.txt");
    println!("Verification jail output: {}", verify_output);

    env.set_pending_verification(&task1, false);

    // Test worktree merge jail message
    env.enable_worktrees();
    let task2 = env.create_task("Worktree jail message test");
    env.set_pending_worktree_merge(&task2, true);
    let (_, pending_worktree) = env.get_task_jail_state(&task2);
    assert!(pending_worktree, "pending_worktree_merge should be set");

    let (_, worktree_output) = env.run_pre_tool_use_read("test.txt");
    println!("Worktree jail output: {}", worktree_output);

    // Messages should be different
    assert_ne!(
        verify_output,
        worktree_output,
        "Verification and worktree jail messages should be different"
    );

    // Check specific content
    assert!(
        verify_output.to_lowercase().contains("verification"),
        "Verification jail should mention 'verification'"
    );
    assert!(
        worktree_output.to_lowercase().contains("worktree"),
        "Worktree jail should mention 'worktree'"
    );
}
