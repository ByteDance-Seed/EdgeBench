use super::*;

/// Test that verification jail blocks tool use when task has pending_verification

/// Test that SubagentStart unjails only tasks owned by the current agent
#[test]
#[ignore]
fn test_subagent_start_unjails_scoped_tasks() {
    let env = HookTestEnv::new();

    let task_owned = env.create_task("Owned jailed task");
    let task_other = env.create_task("Other jailed task");

    env.set_task_assignee(&task_owned, HOOK_TEST_SESSION_ID);
    env.set_task_assignee(&task_other, "other-session");

    env.set_pending_verification(&task_owned, true);
    env.set_pending_verification(&task_other, true);

    // Run SubagentStart (task-verifier)
    let (success, output) = env.run_subagent_start_task_verifier();
    assert!(success, "SubagentStart should succeed: {}", output);

    // Only the owned task should be unjailed
    assert!(
        !env.get_pending_verification(&task_owned),
        "Owned task should be unjailed"
    );
    assert!(
        env.get_pending_verification(&task_other),
        "Other agent task should remain jailed"
    );
}

/// Test that tools work normally when NOT in verification jail
#[test]
#[ignore]
fn test_no_jail_allows_tools() {
    let env = HookTestEnv::new();

    // Create a task but DON'T set pending_verification
    let task_id = env.create_task("Normal task without jail");
    println!("Created task (no jail): {}", task_id);

    // Run hook directly - should NOT be blocked
    let (_, stdout) = env.run_pre_tool_use_read("test.txt");
    println!("Non-jailed hook output: {}", stdout);

    let is_blocked = stdout.contains("deny");
    assert!(
        !is_blocked,
        "Tools should not be blocked when not jailed: {}",
        stdout
    );
}

/// Test that verification jail is released when pending_verification is cleared
#[test]
#[ignore]
fn test_verification_jail_release() {
    let env = HookTestEnv::new();

    // Create a task and set it to jailed
    let task_id = env.create_task("Task for jail release test");
    env.set_pending_verification(&task_id, true);
    println!("Created jailed task: {}", task_id);

    // First verify tools are blocked
    let (_, stdout1) = env.run_pre_tool_use_read("test.txt");
    let was_blocked = stdout1.contains("deny");
    println!("First attempt blocked: {}", was_blocked);
    assert!(was_blocked, "Should be blocked while jailed: {}", stdout1);

    // Now clear the jail
    env.set_pending_verification(&task_id, false);
    println!("Cleared jail for {}", task_id);

    // Tools should work now
    let (_, stdout2) = env.run_pre_tool_use_read("test.txt");
    let still_blocked = stdout2.contains("deny");
    println!("After jail release: blocked={}", still_blocked);
    assert!(
        !still_blocked,
        "Should not be blocked after jail release: {}",
        stdout2
    );
}

// =============================================================================
// Worktree Merge Jail Tests
// =============================================================================

/// Test that worktree merge jail blocks tool use when task has pending_worktree_merge

/// Test that worktree merge jail is released when pending_worktree_merge is cleared

// =============================================================================
// Agent Isolation Tests
// =============================================================================

/// Test that verification jail for one agent doesn't affect other agents
#[test]
#[ignore]
fn test_jail_agent_isolation() {
    let env = HookTestEnv::new();

    // Create a task jailed for a DIFFERENT agent
    let task_id = env.create_task("Task jailed for other agent");
    env.set_task_assignee(&task_id, "other-agent-session-id");
    env.set_pending_verification(&task_id, true);
    println!("Created task jailed for other agent: {}", task_id);

    // Our agent (HOOK_TEST_SESSION_ID) should NOT be affected
    let (_, stdout) = env.run_pre_tool_use_read("test.txt");
    println!("Agent isolation hook output: {}", stdout);

    let is_blocked = stdout.contains("deny");
    assert!(
        !is_blocked,
        "Our agent should not be blocked by another agent's jailed task: {}",
        stdout
    );
}

// =============================================================================
// Combined Jail Tests
// =============================================================================

/// Test both verification and worktree jails together

// =============================================================================
// Bug-Finding Tests: Edge Cases and Race Conditions
// =============================================================================

// BUG TEST: Multiple tasks jailed - clearing ONE should NOT release jail.
// This tests that jail is global across ALL tasks with pending_verification.
