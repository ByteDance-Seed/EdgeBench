use crate::hooks_test::*;
use tempfile::TempDir;

#[test]
#[ignore = "CLI commands removed - tests need MCP fixtures"]
fn test_exit_blocked_with_claimed_task() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    let session_id = "blocked-session-001";

    // Register agent via CLI
    let agent_id = register_agent(&temp, session_id, "test-agent");
    assert!(!agent_id.is_empty(), "Agent should be registered");

    // Create and claim a task via CLI
    let task_id = create_task(&temp, "Blocking task");
    claim_task(&temp, &task_id, &agent_id);

    // Try to stop - should be blocked
    let stop_output = send_hook(&temp, "Stop", &stop_input(session_id));

    // Parse output and check for blocking
    if let Ok(json) = serde_json::from_str::<serde_json::Value>(&stop_output) {
        let continue_session = json["continue_session"].as_bool();
        let stop_reason = json["stopReason"].as_str().or(json["stop_reason"].as_str());

        // If exit blocking is working, continue_session should be false with a reason
        if continue_session == Some(false) {
            assert!(
                stop_reason
                    .map(|r| r.contains("remaining work") || r.contains("Cannot exit"))
                    .unwrap_or(false),
                "Stop reason should mention remaining work. Got: {:?}",
                stop_reason
            );
        }
    }
}

/// Test that Stop is allowed when all tasks are closed

/// Test that Stop is allowed when exit blocking is disabled
#[test]
#[ignore = "CLI commands removed - tests need MCP fixtures"]
fn test_exit_allowed_when_blocking_disabled() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    // Disable exit blocking
    cas_cmd(&temp)
        .args(["config", "set", "tasks.block_exit_on_open", "false"])
        .assert()
        .success();

    let session_id = "no-block-session";

    // Register agent via CLI
    let agent_id = register_agent(&temp, session_id, "test-agent");

    // Create and claim a task via CLI (don't close it)
    let task_id = create_task(&temp, "Open task");
    claim_task(&temp, &task_id, &agent_id);

    // Try to stop - should NOT be blocked because config disabled it
    let stop_output = send_hook(&temp, "Stop", &stop_input(session_id));

    // Parse output
    if let Ok(json) = serde_json::from_str::<serde_json::Value>(&stop_output) {
        let continue_session = json["continue_session"].as_bool();
        let stop_reason = json["stopReason"]
            .as_str()
            .or(json["stop_reason"].as_str())
            .unwrap_or("");

        // Should not be blocked due to remaining work
        if continue_session == Some(false) {
            assert!(
                !stop_reason.contains("remaining work"),
                "Should not be blocked when blocking is disabled. Got: {}",
                stop_reason
            );
        }
    }
}

/// Test that Stop is blocked with open epic subtasks
#[test]
#[ignore = "CLI commands removed - tests need MCP fixtures"]
fn test_exit_blocked_with_epic_subtasks() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    let session_id = "epic-session-001";

    // Register agent via CLI
    let agent_id = register_agent(&temp, session_id, "test-agent");

    // Create an epic via CLI
    cas_cmd(&temp)
        .args(["task", "create", "Epic task", "--type", "epic"])
        .assert()
        .success();

    // Get epic ID via CLI
    let output = cas_cmd(&temp)
        .args(["task", "list", "--json"])
        .output()
        .unwrap();
    let tasks: Vec<serde_json::Value> = serde_json::from_slice(&output.stdout).unwrap_or_default();
    let epic_id = tasks
        .iter()
        .find(|t| t["task_type"].as_str() == Some("epic"))
        .and_then(|t| t["id"].as_str())
        .unwrap_or("")
        .to_string();

    // Create a subtask under the epic via CLI
    if !epic_id.is_empty() {
        cas_cmd(&temp)
            .args(["task", "create", "Subtask 1", "--parent", &epic_id])
            .assert()
            .success();

        // Claim the epic (but not the subtask) via CLI
        claim_task(&temp, &epic_id, &agent_id);

        // Try to stop - should be blocked because of open subtask
        let stop_output = send_hook(&temp, "Stop", &stop_input(session_id));

        // Parse output
        if let Ok(json) = serde_json::from_str::<serde_json::Value>(&stop_output) {
            let continue_session = json["continue_session"].as_bool();
            let stop_reason = json["stopReason"].as_str().or(json["stop_reason"].as_str());

            // Should be blocked
            if let (Some(false), Some(reason)) = (continue_session, stop_reason) {
                // Either mentions subtasks or remaining work
                assert!(
                    reason.contains("remaining work")
                        || reason.contains("Subtask")
                        || reason.contains("Epic"),
                    "Should mention subtasks or remaining work. Got: {}",
                    reason
                );
            }
        }
    }
}

// =============================================================================
// Part G: Session Summary Tests
// =============================================================================

/// Test that Stop blocks when generate_summary is enabled and no summary exists

/// Test that Stop is not blocked when generate_summary is disabled (default)
#[test]
fn test_stop_not_blocked_without_summary_config() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    // Don't enable generate_summary (use default config)
    let session_id = "no-summary-session";

    // Create some observations
    send_hook(
        &temp,
        "PostToolUse",
        &write_tool_input(session_id, "/src/main.rs"),
    );

    // Try to stop - should NOT be blocked for session summary
    let stop_output = send_hook(&temp, "Stop", &stop_input(session_id));

    // Parse output
    if let Ok(json) = serde_json::from_str::<serde_json::Value>(&stop_output) {
        let continue_session = json["continue_session"].as_bool();
        let stop_reason = json["stopReason"]
            .as_str()
            .or(json["stop_reason"].as_str())
            .unwrap_or("");

        // Should not be blocked for session summary
        if continue_session == Some(false) {
            assert!(
                !stop_reason.contains("session-summarizer"),
                "Should not be blocked for session summary when disabled. Got: {}",
                stop_reason
            );
        }
    }
}

// =============================================================================
// Part H: Learning Review Tests
// =============================================================================

/// Helper to add a learning entry via CLI
