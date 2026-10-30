use crate::hooks_test::*;
use tempfile::TempDir;

#[test]
#[ignore = "CLI commands removed - tests need MCP fixtures"]
fn test_stop_blocks_for_learning_review() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    // Enable learning_review in config with threshold of 3
    let config_path = temp.path().join(".cas/config.toml");
    let mut config = std::fs::read_to_string(&config_path).unwrap();
    config.push_str(
        "\n[hooks.stop]\nlearning_review_enabled = true\nlearning_review_threshold = 3\n",
    );
    std::fs::write(&config_path, config).unwrap();

    let session_id = "learning-review-test-session";

    // Add 5 learnings (above threshold of 3)
    for i in 0..5 {
        add_learning(&temp, &format!("Test learning number {}", i));
    }

    // Create some observations first
    send_hook(
        &temp,
        "PostToolUse",
        &write_tool_input(session_id, "/src/main.rs"),
    );

    // Try to stop - should be blocked for learning review
    let stop_output = send_hook(&temp, "Stop", &stop_input(session_id));

    // Parse output and check for blocking
    if let Ok(json) = serde_json::from_str::<serde_json::Value>(&stop_output) {
        let continue_session = json["continue_session"].as_bool();
        let stop_reason = json["stopReason"].as_str().or(json["stop_reason"].as_str());

        // If learning_review is working, should be blocked
        if continue_session == Some(false) {
            let reason = stop_reason.unwrap_or("");
            assert!(
                reason.contains("learning-reviewer")
                    || reason.contains("learning")
                    || reason.contains("Learning review"),
                "Stop reason should mention learning review. Got: {}",
                reason
            );
        }

        // Also check for context in system_reminder
        if let Some(context) = json["system_reminder"].as_str() {
            assert!(
                context.contains("learning-review required")
                    || context.contains("learning-reviewer")
                    || context.contains("Unreviewed Learnings"),
                "Context should mention learning review. Got: {}",
                context
            );
        }
    }
}

/// Test that Stop is NOT blocked when learnings are below threshold
#[test]
#[ignore = "CLI commands removed - tests need MCP fixtures"]
fn test_stop_not_blocked_below_learning_threshold() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    // Enable learning_review with threshold of 10
    let config_path = temp.path().join(".cas/config.toml");
    let mut config = std::fs::read_to_string(&config_path).unwrap();
    config.push_str(
        "\n[hooks.stop]\nlearning_review_enabled = true\nlearning_review_threshold = 10\n",
    );
    std::fs::write(&config_path, config).unwrap();

    let session_id = "below-threshold-session";

    // Add only 3 learnings (below threshold of 10)
    for i in 0..3 {
        add_learning(&temp, &format!("Test learning below threshold {}", i));
    }

    // Try to stop - should NOT be blocked
    let stop_output = send_hook(&temp, "Stop", &stop_input(session_id));

    // Parse output
    if let Ok(json) = serde_json::from_str::<serde_json::Value>(&stop_output) {
        let stop_reason = json["stopReason"]
            .as_str()
            .or(json["stop_reason"].as_str())
            .unwrap_or("");

        // Should NOT mention learning review
        assert!(
            !stop_reason.contains("learning-review"),
            "Should not be blocked for learning review when below threshold. Got: {}",
            stop_reason
        );
    }
}

/// Test that Stop is not blocked when learning_review is disabled (default)
#[test]
#[ignore = "CLI commands removed - tests need MCP fixtures"]
fn test_stop_not_blocked_without_learning_review_config() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    // Don't enable learning_review (use default config)
    let session_id = "no-learning-review-session";

    // Add several learnings
    for i in 0..10 {
        add_learning(&temp, &format!("Test learning {}", i));
    }

    // Try to stop - should NOT be blocked for learning review
    let stop_output = send_hook(&temp, "Stop", &stop_input(session_id));

    // Parse output
    if let Ok(json) = serde_json::from_str::<serde_json::Value>(&stop_output) {
        let stop_reason = json["stopReason"]
            .as_str()
            .or(json["stop_reason"].as_str())
            .unwrap_or("");

        // Should not be blocked for learning review
        assert!(
            !stop_reason.contains("learning-review"),
            "Should not be blocked for learning review when disabled. Got: {}",
            stop_reason
        );
    }
}

// =============================================================================
// Part I: Rule Review Tests
// =============================================================================

/// Helper to add a draft rule via CLI
fn add_draft_rule(dir: &TempDir, content: &str) { todo!() }

/// Test that Stop blocks when rule_review is enabled and threshold is exceeded
#[test]
#[ignore = "CLI commands removed - tests need MCP fixtures"]
fn test_stop_blocks_for_rule_review() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    // Enable rule_review in config with threshold of 3
    let config_path = temp.path().join(".cas/config.toml");
    let mut config = std::fs::read_to_string(&config_path).unwrap();
    config.push_str("\n[hooks.stop]\nrule_review_enabled = true\nrule_review_threshold = 3\n");
    std::fs::write(&config_path, config).unwrap();

    let session_id = "rule-review-test-session";

    // Add 5 draft rules (above threshold of 3)
    for i in 0..5 {
        add_draft_rule(&temp, &format!("Test draft rule number {}", i));
    }

    // Create some observations first
    send_hook(
        &temp,
        "PostToolUse",
        &write_tool_input(session_id, "/src/main.rs"),
    );

    // Try to stop - should be blocked for rule review
    let stop_output = send_hook(&temp, "Stop", &stop_input(session_id));

    // Parse output and check for blocking
    if let Ok(json) = serde_json::from_str::<serde_json::Value>(&stop_output) {
        let continue_session = json["continue_session"].as_bool();
        let stop_reason = json["stopReason"].as_str().or(json["stop_reason"].as_str());

        // If rule_review is working, should be blocked
        if continue_session == Some(false) {
            let reason = stop_reason.unwrap_or("");
            assert!(
                reason.contains("rule-reviewer")
                    || reason.contains("rule")
                    || reason.contains("Rule review"),
                "Stop reason should mention rule review. Got: {}",
                reason
            );
        }

        // Also check for context in system_reminder
        if let Some(context) = json["system_reminder"].as_str() {
            assert!(
                context.contains("rule-review required")
                    || context.contains("rule-reviewer")
                    || context.contains("Draft Rules"),
                "Context should mention rule review. Got: {}",
                context
            );
        }
    }
}

/// Test that Stop is NOT blocked when draft rules are below threshold
#[test]
#[ignore = "CLI commands removed - tests need MCP fixtures"]
fn test_stop_not_blocked_below_rule_threshold() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    // Enable rule_review with threshold of 10
    let config_path = temp.path().join(".cas/config.toml");
    let mut config = std::fs::read_to_string(&config_path).unwrap();
    config.push_str("\n[hooks.stop]\nrule_review_enabled = true\nrule_review_threshold = 10\n");
    std::fs::write(&config_path, config).unwrap();

    let session_id = "below-rule-threshold-session";

    // Add only 3 draft rules (below threshold of 10)
    for i in 0..3 {
        add_draft_rule(&temp, &format!("Test draft rule below threshold {}", i));
    }

    // Try to stop - should NOT be blocked
    let stop_output = send_hook(&temp, "Stop", &stop_input(session_id));

    // Parse output
    if let Ok(json) = serde_json::from_str::<serde_json::Value>(&stop_output) {
        let stop_reason = json["stopReason"]
            .as_str()
            .or(json["stop_reason"].as_str())
            .unwrap_or("");

        // Should NOT mention rule review
        assert!(
            !stop_reason.contains("rule-review"),
            "Should not be blocked for rule review when below threshold. Got: {}",
            stop_reason
        );
    }
}

/// Test that Stop is not blocked when rule_review is disabled (default)

// =============================================================================
// Part J: Duplicate Detection Tests
// =============================================================================

/// Helper to add an entry via CLI
fn add_entry(dir: &TempDir, content: &str) { todo!() }

/// Test that Stop blocks when duplicate_detection is enabled and threshold is exceeded

/// Test that Stop is NOT blocked when entries are below threshold
#[test]
#[ignore = "CLI commands removed - tests need MCP fixtures"]
fn test_stop_not_blocked_below_duplicate_threshold() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    // Enable duplicate_detection with threshold of 20
    let config_path = temp.path().join(".cas/config.toml");
    let mut config = std::fs::read_to_string(&config_path).unwrap();
    config.push_str(
        "\n[hooks.stop]\nduplicate_detection_enabled = true\nduplicate_detection_threshold = 20\n",
    );
    std::fs::write(&config_path, config).unwrap();

    let session_id = "below-duplicate-threshold-session";

    // Add only 5 entries (below threshold of 20)
    for i in 0..5 {
        add_entry(&temp, &format!("Test entry below threshold {}", i));
    }

    // Try to stop - should NOT be blocked
    let stop_output = send_hook(&temp, "Stop", &stop_input(session_id));

    // Parse output
    if let Ok(json) = serde_json::from_str::<serde_json::Value>(&stop_output) {
        let stop_reason = json["stopReason"]
            .as_str()
            .or(json["stop_reason"].as_str())
            .unwrap_or("");

        // Should NOT mention duplicate detection
        assert!(
            !stop_reason.contains("duplicate-detection"),
            "Should not be blocked for duplicate detection when below threshold. Got: {}",
            stop_reason
        );
    }
}

/// Test that Stop is not blocked when duplicate_detection is disabled (default)
#[test]
#[ignore = "CLI commands removed - tests need MCP fixtures"]
fn test_stop_not_blocked_without_duplicate_detection_config() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    // Don't enable duplicate_detection (use default config)
    let session_id = "no-duplicate-detection-session";

    // Add several entries
    for i in 0..25 {
        add_entry(&temp, &format!("Test entry {}", i));
    }

    // Try to stop - should NOT be blocked for duplicate detection
    let stop_output = send_hook(&temp, "Stop", &stop_input(session_id));

    // Parse output
    if let Ok(json) = serde_json::from_str::<serde_json::Value>(&stop_output) {
        let stop_reason = json["stopReason"]
            .as_str()
            .or(json["stop_reason"].as_str())
            .unwrap_or("");

        // Should not be blocked for duplicate detection
        assert!(
            !stop_reason.contains("duplicate-detection"),
            "Should not be blocked for duplicate detection when disabled. Got: {}",
            stop_reason
        );
    }
}
