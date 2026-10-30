#[test]
#[ignore]
fn test_verification_jail_blocks_tools() {
    let env = HookTestEnv::new();

    // Create a task
    let task_id = env.create_task("Test task for verification jail");
    println!("Created task: {}", task_id);

    // Set pending_verification to true
    env.set_pending_verification(&task_id, true);
    println!("Set pending_verification=true for {}", task_id);

    // Run hook directly - should be blocked
    let (_, stdout) = env.run_pre_tool_use_read("test.txt");
    println!("Verification jail hook output: {}", stdout);

    let is_blocked = stdout.contains("deny");
    assert!(
        is_blocked,
        "Expected verification jail to block tool use, got: {}",
        stdout
    );

    // Verify the message mentions verification
    assert!(
        stdout.to_lowercase().contains("verification"),
        "Jail message should mention verification: {}",
        stdout
    );
}

#[test]
#[ignore]
fn test_worktree_merge_jail_blocks_tools() {
    let env = HookTestEnv::new();

    // Enable worktrees (required for worktree merge jail)
    env.enable_worktrees();

    // Create a task (simulating an epic that would have a worktree)
    let task_id = env.create_task("Epic for worktree merge jail");
    println!("Created task: {}", task_id);

    // Set pending_worktree_merge to true
    env.set_pending_worktree_merge(&task_id, true);
    println!("Set pending_worktree_merge=true for {}", task_id);

    // Verify the flag was set
    let (_, pending_merge) = env.get_task_jail_state(&task_id);
    assert!(
        pending_merge,
        "pending_worktree_merge should be true after setting"
    );

    // Run hook directly - should be blocked by worktree merge jail
    let (_, stdout) = env.run_pre_tool_use_read("README.md");
    println!("Worktree merge jail hook output: {}", stdout);

    let is_blocked = stdout.contains("deny");
    assert!(
        is_blocked,
        "Expected worktree merge jail to block tool use: {}",
        stdout
    );

    // Verify message mentions worktree
    assert!(
        stdout.to_lowercase().contains("worktree"),
        "Worktree jail message should mention 'worktree': {}",
        stdout
    );
}

#[test]
#[ignore]
fn test_worktree_merge_jail_release() {
    let env = HookTestEnv::new();

    env.enable_worktrees();

    // Create a task and set it to worktree merge jail
    let task_id = env.create_task("Task for worktree merge release test");
    env.set_pending_worktree_merge(&task_id, true);
    println!("Created worktree-jailed task: {}", task_id);

    // Verify blocked
    let (_, stdout1) = env.run_pre_tool_use_read("test.txt");
    let was_blocked = stdout1.contains("deny");
    println!("Before release: blocked={}", was_blocked);
    assert!(was_blocked, "Should be blocked while worktree-jailed: {}", stdout1);

    // Clear the jail
    env.set_pending_worktree_merge(&task_id, false);
    println!("Cleared worktree merge jail for {}", task_id);

    // Tools should work now
    let (_, stdout2) = env.run_pre_tool_use_read("test.txt");
    let still_blocked = stdout2.contains("deny");
    println!("After worktree jail release: blocked={}", still_blocked);
    assert!(
        !still_blocked,
        "Should not be blocked after worktree jail release: {}",
        stdout2
    );
}

#[test]
#[ignore]
fn test_both_jails_block_tools() {
    let env = HookTestEnv::new();

    env.enable_worktrees();

    // Create two tasks with different jail types
    let task1 = env.create_task("Task with verification jail");
    let task2 = env.create_task("Task with worktree jail");

    env.set_pending_verification(&task1, true);
    env.set_pending_worktree_merge(&task2, true);
    println!("Created tasks with both jail types: {}, {}", task1, task2);

    // Should be blocked
    let (_, stdout) = env.run_pre_tool_use_read("test.txt");
    println!("Both jails hook output: {}", stdout);

    let is_blocked = stdout.contains("deny");
    assert!(
        is_blocked,
        "Expected jail to block tool use, got: {}",
        stdout
    );

    // Clear verification jail only - should still be blocked by worktree jail
    env.set_pending_verification(&task1, false);
    let (_, stdout2) = env.run_pre_tool_use_read("test.txt");
    let still_blocked = stdout2.contains("deny");
    println!("After clearing verification jail: blocked={}", still_blocked);
    assert!(
        still_blocked,
        "Should still be blocked by worktree jail: {}",
        stdout2
    );

    // Clear worktree jail too - should work now
    env.set_pending_worktree_merge(&task2, false);
    let (_, stdout3) = env.run_pre_tool_use_read("test.txt");
    let final_blocked = stdout3.contains("deny");
    println!("After clearing both jails: blocked={}", final_blocked);
    assert!(
        !final_blocked,
        "Should not be blocked after clearing both jails: {}",
        stdout3
    );
}
