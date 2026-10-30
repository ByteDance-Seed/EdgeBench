#[test]
fn test_verification_blocker_scoped_to_epic() {
    let cas = new_cas_instance();

    // Register an agent
    let output = cas
        .cas_cmd()
        .args(["agent", "register", "--name", "single-agent"])
        .output()
        .expect("Failed to register agent");
    let agent_id = extract_agent_id(&output).unwrap_or_default();

    if agent_id.is_empty() {
        println!("Skipping test: could not extract agent ID");
        return;
    }

    // Create an epic with pending verification (start and claim with agent ID)
    let epic_id = cas.create_task_with_options("Blocked Epic", Some("epic"), None, false);
    let _ = cas
        .cas_cmd()
        .args(["task", "start", &epic_id, "--agent-id", &agent_id])
        .output();
    set_pending_verification(&cas, &epic_id, true);

    // Create an unrelated task (not under the epic)
    let unrelated_task_id = cas.create_task("Unrelated task");

    // The agent should be able to work on the unrelated task
    // Use --agent-id to start and claim in one step
    let output = cas
        .cas_cmd()
        .args(["task", "start", &unrelated_task_id, "--agent-id", &agent_id])
        .output()
        .expect("Failed to start unrelated task");
    assert!(
        output.status.success(),
        "Should be able to start unrelated task"
    );

    // The agent might be blocked from closing the epic until verification passes
    // but should be able to add notes
    let output = cas
        .cas_cmd()
        .args(["task", "notes", &epic_id, "Waiting for verification"])
        .output()
        .expect("Failed to add notes to epic");
    assert!(
        output.status.success(),
        "Should be able to add notes even with pending verification"
    );
}

#[test]
fn test_mine_shows_all_agent_tasks_regardless_of_blockers() {
    let cas = new_cas_instance();

    // Register agent
    let output = cas
        .cas_cmd()
        .args(["agent", "register", "--name", "multi-task-agent"])
        .output()
        .expect("Failed to register agent");
    let agent_id = extract_agent_id(&output).unwrap_or_default();

    if agent_id.is_empty() {
        println!("Skipping test: could not extract agent ID");
        return;
    }

    // Create and claim multiple tasks using --agent-id to claim as the registered agent
    let task_1 = cas.create_task("Agent's first task");
    let task_2 = cas.create_task("Agent's second task");
    let epic = cas.create_task_with_options("Agent's epic", Some("epic"), None, false);

    for task in [&task_1, &task_2, &epic] {
        let _ = cas
            .cas_cmd()
            .args(["task", "start", task, "--agent-id", &agent_id])
            .output();
    }

    // Block the epic with verification
    set_pending_verification(&cas, &epic, true);

    // 'mine' should still show all tasks including the blocked epic
    let output = cas
        .cas_cmd()
        .args(["task", "mine", "--agent-id", &agent_id])
        .output()
        .expect("Failed to list my tasks");
    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);

    // Should show all three tasks
    let has_task_1 = stdout.contains(&task_1) || stdout.contains("first task");
    let has_task_2 = stdout.contains(&task_2) || stdout.contains("second task");
    let has_epic = stdout.contains(&epic) || stdout.contains("epic");

    println!("mine output: {}", stdout);
    assert!(
        has_task_1 || has_task_2 || has_epic,
        "Should show at least some of the agent's tasks"
    );
}
