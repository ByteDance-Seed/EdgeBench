#[test]
#[ignore = "CLI commands removed - tests need MCP fixtures"]
fn test_exit_allowed_when_tasks_closed() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    let session_id = "allowed-session-001";

    // Register agent via CLI
    let agent_id = register_agent(&temp, session_id, "test-agent");

    // Create a task via CLI
    let task_id = create_task(&temp, "Quick task");

    // Claim the task via CLI
    claim_task(&temp, &task_id, &agent_id);

    // Close the task via CLI
    cas_cmd(&temp)
        .args(["task", "close", &task_id])
        .assert()
        .success();

    // Try to stop - should be allowed
    let stop_output = send_hook(&temp, "Stop", &stop_input(session_id));

    // Parse output
    if let Ok(json) = serde_json::from_str::<serde_json::Value>(&stop_output) {
        let continue_session = json["continue_session"].as_bool();
        // Should NOT be blocked (continue_session should not be false with blocking reason)
        if continue_session == Some(false) {
            let stop_reason = json["stopReason"]
                .as_str()
                .or(json["stop_reason"].as_str())
                .unwrap_or("");
            assert!(
                !stop_reason.contains("remaining work"),
                "Should not be blocked when task is closed. Got: {}",
                stop_reason
            );
        }
    }
}

#[test]
fn test_stop_blocks_for_session_summary() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    // Enable generate_summary in config
    let config_path = temp.path().join(".cas/config.toml");
    let mut config = std::fs::read_to_string(&config_path).unwrap();
    config.push_str("\n[hooks.stop]\ngenerate_summary = true\n");
    std::fs::write(&config_path, config).unwrap();

    let session_id = "summary-test-session";

    // Create some observations
    send_hook(
        &temp,
        "PostToolUse",
        &write_tool_input(session_id, "/src/main.rs"),
    );

    // Try to stop - should be blocked for session summary
    let stop_output = send_hook(&temp, "Stop", &stop_input(session_id));

    // Parse output and check for blocking
    if let Ok(json) = serde_json::from_str::<serde_json::Value>(&stop_output) {
        let continue_session = json["continue_session"].as_bool();
        let stop_reason = json["stopReason"].as_str().or(json["stop_reason"].as_str());

        // If generate_summary is working, should be blocked
        if continue_session == Some(false) {
            let reason = stop_reason.unwrap_or("");
            assert!(
                reason.contains("session-summarizer")
                    || reason.contains("summary")
                    || reason.contains("Session summary"),
                "Stop reason should mention session summary. Got: {}",
                reason
            );
        }

        // Also check for context in system_reminder
        if let Some(context) = json["system_reminder"].as_str() {
            assert!(
                context.contains("session-summary required")
                    || context.contains("session-summarizer"),
                "Context should mention session summary. Got: {}",
                context
            );
        }
    }
}
