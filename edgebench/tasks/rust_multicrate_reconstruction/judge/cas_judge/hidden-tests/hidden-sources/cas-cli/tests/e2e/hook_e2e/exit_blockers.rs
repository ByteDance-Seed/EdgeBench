#[test]
#[ignore]
fn test_stop_hook_blocks_when_epic_has_other_incomplete_subtasks() {
    let env = HookTestEnv::new();

    // Use session-based agent ID for hook scoping
    let agent_id = compute_test_agent_id();
    println!("Computed agent ID: {}", agent_id);

    // Register agent
    env.register_agent(&agent_id, "test-agent-epic-incomplete", "primary");

    // Create an epic
    let epic_id = env.cas.create_task_with_options("Epic with Multiple Subtasks", Some("epic"), None, false);
    println!("Created epic: {}", epic_id);

    // Create two subtasks
    let subtask1_id = env.cas.create_task("First Subtask");
    env.add_dependency(&subtask1_id, &epic_id, "parent-child");
    println!("Created subtask 1: {}", subtask1_id);

    let subtask2_id = env.cas.create_task("Second Subtask");
    env.add_dependency(&subtask2_id, &epic_id, "parent-child");
    println!("Created subtask 2: {}", subtask2_id);

    // Agent starts subtask 1 and adds epic to working_epics
    env.cas.start_task(&subtask1_id);
    env.set_task_assignee(&subtask1_id, &agent_id);
    env.add_working_epic(&agent_id, &epic_id);
    println!("Agent started subtask 1");

    // Agent CLOSES subtask 1 - they completed their work
    env.cas.close_task(&subtask1_id);
    println!("Agent closed subtask 1");

    // Write session file and enable exit blockers
    let session_file = env.dir().join(".cas").join("current_session");
    std::fs::write(&session_file, &agent_id).expect("Failed to write session file");
    let config_path = env.dir().join(".cas").join("config.toml");
    std::fs::write(&config_path, "[tasks]\nblock_exit_on_open = true\n")
        .expect("Failed to write config");

    // Call Stop hook
    let (_, stop_stdout) = env.run_stop_hook();
    println!("Stop hook after closing subtask 1: {}", stop_stdout);

    // Parse the JSON output
    if let Ok(json) = serde_json::from_str::<serde_json::Value>(&stop_stdout) {
        // Should have a "block" decision because epic has incomplete subtasks
        let decision = json.get("decision").and_then(|d| d.as_str());
        let reason = json.get("reason").and_then(|r| r.as_str()).unwrap_or("");

        println!("Decision: {:?}", decision);
        println!("Reason: {}", reason);

        // The agent should be blocked because the epic has incomplete subtask 2
        let mentions_subtask2 = reason.contains(&subtask2_id) || reason.contains("Second Subtask");
        let mentions_epic = reason.to_lowercase().contains("epic");
        let is_blocked = decision == Some("block");

        assert!(
            is_blocked && (mentions_subtask2 || mentions_epic),
            "Agent should be blocked due to incomplete epic subtask 2. \
            Decision: {:?}, Reason mentions subtask2: {}, Reason mentions epic: {}. \
            Full reason: {}",
            decision,
            mentions_subtask2,
            mentions_epic,
            reason
        );
    } else {
        // Empty response means no blockers - this is the BUG we're testing for!
        panic!(
            "Stop hook should block when epic has incomplete subtasks, but got: '{}'",
            stop_stdout
        );
    }
}
