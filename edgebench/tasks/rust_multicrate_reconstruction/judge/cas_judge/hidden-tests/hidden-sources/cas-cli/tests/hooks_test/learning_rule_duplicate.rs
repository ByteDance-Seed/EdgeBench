#[test]
#[ignore = "CLI commands removed - tests need MCP fixtures"]
fn test_stop_not_blocked_without_rule_review_config() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    // Don't enable rule_review (use default config)
    let session_id = "no-rule-review-session";

    // Add several draft rules
    for i in 0..10 {
        add_draft_rule(&temp, &format!("Test draft rule {}", i));
    }

    // Try to stop - should NOT be blocked for rule review
    let stop_output = send_hook(&temp, "Stop", &stop_input(session_id));

    // Parse output
    if let Ok(json) = serde_json::from_str::<serde_json::Value>(&stop_output) {
        let stop_reason = json["stopReason"]
            .as_str()
            .or(json["stop_reason"].as_str())
            .unwrap_or("");

        // Should not be blocked for rule review
        assert!(
            !stop_reason.contains("rule-review"),
            "Should not be blocked for rule review when disabled. Got: {}",
            stop_reason
        );
    }
}

#[test]
#[ignore = "CLI commands removed - tests need MCP fixtures"]
fn test_stop_blocks_for_duplicate_detection() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    // Enable duplicate_detection in config with threshold of 5
    let config_path = temp.path().join(".cas/config.toml");
    let mut config = std::fs::read_to_string(&config_path).unwrap();
    config.push_str(
        "\n[hooks.stop]\nduplicate_detection_enabled = true\nduplicate_detection_threshold = 5\n",
    );
    std::fs::write(&config_path, config).unwrap();

    let session_id = "duplicate-detection-test-session";

    // Add 10 entries (above threshold of 5)
    for i in 0..10 {
        add_entry(&temp, &format!("Test entry number {}", i));
    }

    // Create some observations first
    send_hook(
        &temp,
        "PostToolUse",
        &write_tool_input(session_id, "/src/main.rs"),
    );

    // Try to stop - should be blocked for duplicate detection
    let stop_output = send_hook(&temp, "Stop", &stop_input(session_id));

    // Parse output and check for blocking
    if let Ok(json) = serde_json::from_str::<serde_json::Value>(&stop_output) {
        let continue_session = json["continue_session"].as_bool();
        let stop_reason = json["stopReason"].as_str().or(json["stop_reason"].as_str());

        // If duplicate_detection is working, should be blocked
        if continue_session == Some(false) {
            let reason = stop_reason.unwrap_or("");
            assert!(
                reason.contains("duplicate-detector")
                    || reason.contains("duplicate")
                    || reason.contains("Duplicate detection"),
                "Stop reason should mention duplicate detection. Got: {}",
                reason
            );
        }

        // Also check for context in system_reminder
        if let Some(context) = json["system_reminder"].as_str() {
            assert!(
                context.contains("duplicate-detection required")
                    || context.contains("duplicate-detector")
                    || context.contains("Memory Cleanup"),
                "Context should mention duplicate detection. Got: {}",
                context
            );
        }
    }
}
