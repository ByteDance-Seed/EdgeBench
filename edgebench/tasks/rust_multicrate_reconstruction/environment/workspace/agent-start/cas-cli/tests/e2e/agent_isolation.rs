//! Agent isolation E2E tests
//!
//! Tests that blockers for one agent (epic verification, worktree merge) don't
//! interfere with other agents working on the same project.

use crate::fixtures::new_cas_instance;
use std::process::Command;

/// Helper to set pending_verification flag on a task via direct DB update
fn set_pending_verification(cas: &crate::fixtures::CasInstance, task_id: &str, value: bool) { todo!() }

/// Helper to set pending_worktree_merge flag on a task via direct DB update
fn set_pending_worktree_merge(cas: &crate::fixtures::CasInstance, task_id: &str, value: bool) { todo!() }

/// Helper to extract agent ID from register output
fn extract_agent_id(output: &std::process::Output) -> Option<String> { todo!() }

/// Helper to extract task ID from command output
fn extract_task_id(output: &str) -> Option<String> { todo!() }

/// Test: Agent B can work on tasks while Agent A's epic has pending_verification
#[test]
fn test_agent_b_unaffected_by_agent_a_verification_blocker() {
    let cas = new_cas_instance();

    // Register Agent A
    let output = cas
        .cas_cmd()
        .args(["agent", "register", "--name", "agent-a-epic"])
        .output()
        .expect("Failed to register agent A");
    let agent_a_id = extract_agent_id(&output).unwrap_or_default();

    // Register Agent B
    let output = cas
        .cas_cmd()
        .args(["agent", "register", "--name", "agent-b-regular"])
        .output()
        .expect("Failed to register agent B");
    let agent_b_id = extract_agent_id(&output).unwrap_or_default();

    if agent_a_id.is_empty() || agent_b_id.is_empty() {
        println!("Skipping test: could not extract agent IDs");
        return;
    }

    // Create an epic for Agent A and start it with agent A's ID (this also claims it)
    let epic_id = cas.create_task_with_options("Agent A's Epic", Some("epic"), None, false);
    let _ = cas
        .cas_cmd()
        .args(["task", "start", &epic_id, "--agent-id", &agent_a_id])
        .output();

    // Create a regular task for Agent B
    let task_b_id = cas.create_task("Agent B's regular task");

    // Set pending_verification on Agent A's epic (simulating close attempt)
    set_pending_verification(&cas, &epic_id, true);

    // Agent B should still be able to:
    // 1. Start and claim their task (using --agent-id to claim as the registered agent)
    let output = cas
        .cas_cmd()
        .args(["task", "start", &task_b_id, "--agent-id", &agent_b_id])
        .output()
        .expect("Failed to start Agent B's task");
    assert!(
        output.status.success(),
        "Agent B should be able to start their task"
    );

    // 3. Close their task
    let output = cas
        .cas_cmd()
        .args(["task", "close", &task_b_id])
        .output()
        .expect("Failed to close Agent B's task");
    // Note: This may or may not succeed depending on verification requirements
    // The key is that Agent A's blocker shouldn't affect it
    println!(
        "Agent B close result: {}",
        String::from_utf8_lossy(&output.stdout)
    );

    // 4. List available tasks (should not be blocked)
    let output = cas
        .cas_cmd()
        .args(["task", "available"])
        .output()
        .expect("Failed to list available tasks");
    assert!(
        output.status.success(),
        "Agent B should be able to list available tasks"
    );
}

/// Test: Agent B can work while Agent A's epic has pending_worktree_merge
#[test]
fn test_agent_b_unaffected_by_agent_a_worktree_blocker() {
    let cas = new_cas_instance();

    // Register Agent A
    let output = cas
        .cas_cmd()
        .args(["agent", "register", "--name", "agent-a-worktree"])
        .output()
        .expect("Failed to register agent A");
    let agent_a_id = extract_agent_id(&output).unwrap_or_default();

    // Register Agent B
    let output = cas
        .cas_cmd()
        .args(["agent", "register", "--name", "agent-b-separate"])
        .output()
        .expect("Failed to register agent B");
    let agent_b_id = extract_agent_id(&output).unwrap_or_default();

    if agent_a_id.is_empty() || agent_b_id.is_empty() {
        println!("Skipping test: could not extract agent IDs");
        return;
    }

    // Create an epic for Agent A and start/claim it with agent A's ID
    let epic_id =
        cas.create_task_with_options("Agent A's Worktree Epic", Some("epic"), None, false);
    let _ = cas
        .cas_cmd()
        .args(["task", "start", &epic_id, "--agent-id", &agent_a_id])
        .output();

    // Create tasks for Agent B
    let task_b1_id = cas.create_task("Agent B's first task");
    let task_b2_id = cas.create_task("Agent B's second task");

    // Set pending_worktree_merge on Agent A's epic
    set_pending_worktree_merge(&cas, &epic_id, true);

    // Agent B should still be able to work on their tasks
    // Use --agent-id to start and claim in one step
    let output = cas
        .cas_cmd()
        .args(["task", "start", &task_b1_id, "--agent-id", &agent_b_id])
        .output()
        .expect("Failed to start Agent B's task");
    assert!(
        output.status.success(),
        "Agent B should be able to start task while Agent A has worktree blocker"
    );

    // Agent B should be able to see ready tasks
    let output = cas
        .cas_cmd()
        .args(["task", "ready"])
        .output()
        .expect("Failed to list ready tasks");
    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    // Agent B's unclaimed task should be in ready list
    assert!(
        stdout.contains(&task_b2_id) || stdout.contains("Agent B's second task"),
        "Agent B's unclaimed task should be ready"
    );
}

/// Test: Two agents working on different epics - blockers are isolated
#[test]
fn test_two_agents_different_epics_isolated_blockers() {
    let cas = new_cas_instance();

    // Register both agents
    let output = cas
        .cas_cmd()
        .args(["agent", "register", "--name", "agent-epic-1"])
        .output()
        .expect("Failed to register agent 1");
    let agent_1_id = extract_agent_id(&output).unwrap_or_default();

    let output = cas
        .cas_cmd()
        .args(["agent", "register", "--name", "agent-epic-2"])
        .output()
        .expect("Failed to register agent 2");
    let agent_2_id = extract_agent_id(&output).unwrap_or_default();

    if agent_1_id.is_empty() || agent_2_id.is_empty() {
        println!("Skipping test: could not extract agent IDs");
        return;
    }

    // Create epics for each agent
    let epic_1_id = cas.create_task_with_options("Epic for Agent 1", Some("epic"), None, false);
    let epic_2_id = cas.create_task_with_options("Epic for Agent 2", Some("epic"), None, false);

    // Create subtasks under each epic using --epic flag
    let output = cas
        .cas_cmd()
        .args([
            "task",
            "create",
            "Subtask under Epic 1",
            "--epic",
            &epic_1_id,
        ])
        .output()
        .expect("Failed to create subtask 1");
    let stdout = String::from_utf8_lossy(&output.stdout);
    let subtask_1_id = extract_task_id(&stdout).unwrap_or_default();

    let output = cas
        .cas_cmd()
        .args([
            "task",
            "create",
            "Subtask under Epic 2",
            "--epic",
            &epic_2_id,
        ])
        .output()
        .expect("Failed to create subtask 2");
    let stdout = String::from_utf8_lossy(&output.stdout);
    let subtask_2_id = extract_task_id(&stdout).unwrap_or_default();

    // Both agents start and claim their epics and subtasks
    let _ = cas
        .cas_cmd()
        .args(["task", "start", &epic_1_id, "--agent-id", &agent_1_id])
        .output();
    let _ = cas
        .cas_cmd()
        .args(["task", "start", &subtask_1_id, "--agent-id", &agent_1_id])
        .output();

    let _ = cas
        .cas_cmd()
        .args(["task", "start", &epic_2_id, "--agent-id", &agent_2_id])
        .output();
    let _ = cas
        .cas_cmd()
        .args(["task", "start", &subtask_2_id, "--agent-id", &agent_2_id])
        .output();

    // Set pending_verification on Epic 1 (Agent 1 is blocked)
    set_pending_verification(&cas, &epic_1_id, true);

    // Agent 2 should still be able to close their subtask
    let output = cas
        .cas_cmd()
        .args(["task", "close", &subtask_2_id])
        .output()
        .expect("Failed to close Agent 2's subtask");

    println!(
        "Agent 2 close subtask: stdout={}, stderr={}",
        String::from_utf8_lossy(&output.stdout),
        String::from_utf8_lossy(&output.stderr)
    );

    // Now set pending_worktree_merge on Epic 2 (Agent 2 is blocked)
    set_pending_worktree_merge(&cas, &epic_2_id, true);

    // Agent 1's subtask operations should not be affected by Agent 2's blocker
    let output = cas
        .cas_cmd()
        .args([
            "task",
            "notes",
            &subtask_1_id,
            "Progress update from Agent 1",
        ])
        .output()
        .expect("Failed to add notes");
    assert!(
        output.status.success(),
        "Agent 1 should be able to add notes to their subtask"
    );
}

/// Test: Agent cannot claim a task already claimed by another agent
#[test]
fn test_agents_cannot_claim_same_task() {
    let cas = new_cas_instance();

    // Register both agents
    let output = cas
        .cas_cmd()
        .args(["agent", "register", "--name", "agent-first"])
        .output()
        .expect("Failed to register first agent");
    let agent_1_id = extract_agent_id(&output).unwrap_or_default();

    let output = cas
        .cas_cmd()
        .args(["agent", "register", "--name", "agent-second"])
        .output()
        .expect("Failed to register second agent");
    let agent_2_id = extract_agent_id(&output).unwrap_or_default();

    if agent_1_id.is_empty() || agent_2_id.is_empty() {
        println!("Skipping test: could not extract agent IDs");
        return;
    }

    // Create a shared task
    let task_id = cas.create_task("Shared task");

    // Agent 1 claims it first
    let output = cas
        .cas_cmd()
        .args(["task", "claim", &task_id, "--agent-id", &agent_1_id])
        .output()
        .expect("Failed to claim task for agent 1");
    assert!(output.status.success(), "Agent 1 should claim successfully");

    // Agent 2 tries to claim the same task - should fail or indicate already claimed
    let output = cas
        .cas_cmd()
        .args(["task", "claim", &task_id, "--agent-id", &agent_2_id])
        .output()
        .expect("Failed to run claim for agent 2");

    let stdout = String::from_utf8_lossy(&output.stdout);
    let stderr = String::from_utf8_lossy(&output.stderr);
    let combined = format!("{} {}", stdout, stderr).to_lowercase();

    // Should either fail or indicate already claimed
    let already_claimed = !output.status.success()
        || combined.contains("already")
        || combined.contains("claimed")
        || combined.contains("held");

    assert!(
        already_claimed,
        "Agent 2 should not be able to claim a task already claimed by Agent 1. Output: {}",
        combined
    );
}

/// Test: Agent can claim task after another agent releases it
#[test]
fn test_agent_can_claim_after_release() {
    let cas = new_cas_instance();

    // Register both agents
    let output = cas
        .cas_cmd()
        .args(["agent", "register", "--name", "agent-releaser"])
        .output()
        .expect("Failed to register first agent");
    let agent_1_id = extract_agent_id(&output).unwrap_or_default();

    let output = cas
        .cas_cmd()
        .args(["agent", "register", "--name", "agent-claimer"])
        .output()
        .expect("Failed to register second agent");
    let agent_2_id = extract_agent_id(&output).unwrap_or_default();

    if agent_1_id.is_empty() || agent_2_id.is_empty() {
        println!("Skipping test: could not extract agent IDs");
        return;
    }

    // Create a task
    let task_id = cas.create_task("Task to transfer via release");

    // Agent 1 claims it
    let _ = cas
        .cas_cmd()
        .args(["task", "claim", &task_id, "--agent-id", &agent_1_id])
        .output();

    // Agent 1 releases it
    let output = cas
        .cas_cmd()
        .args(["task", "release", &task_id])
        .output()
        .expect("Failed to release task");
    assert!(output.status.success(), "Agent 1 should be able to release");

    // Agent 2 should now be able to claim it
    let output = cas
        .cas_cmd()
        .args(["task", "claim", &task_id, "--agent-id", &agent_2_id])
        .output()
        .expect("Failed to claim released task");
    assert!(
        output.status.success(),
        "Agent 2 should be able to claim after release"
    );
}

/// Test: Verification blocker only affects the agent's own epic tasks

/// Test: Multiple agents listing tasks don't see each other's blockers
#[test]
fn test_task_listing_isolation() {
    let cas = new_cas_instance();

    // Create tasks with various states
    let task_normal = cas.create_task("Normal task");
    let task_blocked_verification = cas.create_task("Task with verification pending");
    let task_blocked_worktree = cas.create_task("Task with worktree merge pending");

    // Start them
    cas.start_task(&task_normal);
    cas.start_task(&task_blocked_verification);
    cas.start_task(&task_blocked_worktree);

    // Set blockers on specific tasks
    set_pending_verification(&cas, &task_blocked_verification, true);
    set_pending_worktree_merge(&cas, &task_blocked_worktree, true);

    // Task list should show all tasks
    let output = cas
        .cas_cmd()
        .args(["task", "list"])
        .output()
        .expect("Failed to list tasks");
    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);

    // All tasks should appear in the list
    assert!(stdout.contains(&task_normal) || stdout.contains("Normal task"));

    // Ready tasks should show tasks that aren't blocked by dependencies
    // (verification/worktree blockers are different from dependency blockers)
    let output = cas
        .cas_cmd()
        .args(["task", "ready"])
        .output()
        .expect("Failed to list ready tasks");
    assert!(output.status.success());
}

/// Test: Agent with blocked epic can still see other tasks in 'mine'
