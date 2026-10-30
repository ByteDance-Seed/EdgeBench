use crate::hooks_test::*;
use tempfile::TempDir;

#[test]
#[ignore = "CLI commands removed - tests need MCP fixtures"]
fn test_post_tool_use_stores_observation_without_dev_mode() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp); // dev_mode=false (default)

    // Send Write tool event (always captured per should_buffer_observation)
    let input = write_tool_input("test-session-001", "/project/src/main.rs");
    send_hook(&temp, "PostToolUse", &input);

    // Verify observation was stored
    let count = count_entries(&temp);
    assert!(
        count > 0,
        "Observation should be stored even without dev_mode. Got {} entries",
        count
    );
}


#[test]
#[ignore = "CLI commands removed - tests need MCP fixtures"]
fn test_post_tool_use_captures_errors() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    // Send failed Bash command
    let input = bash_tool_input("test-session-err", "cargo test", 1);
    send_hook(&temp, "PostToolUse", &input);

    // Errors should always be captured
    let count = count_entries(&temp);
    assert!(
        count > 0,
        "Errors should always be captured. Got {} entries",
        count
    );
}

#[test]
#[ignore = "CLI commands removed - tests need MCP fixtures"]
fn test_post_tool_use_captures_significant_edits() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    // Send significant edit (15 lines changed)
    let input = edit_tool_input("test-session-edit", "/project/big_change.rs", 5, 20);
    send_hook(&temp, "PostToolUse", &input);

    // Significant edits (10+ line diff) should be captured
    let count = count_entries(&temp);
    assert!(
        count > 0,
        "Significant edits should be captured. Got {} entries",
        count
    );
}

#[test]
fn test_post_tool_use_ignores_small_edits() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    // Send small edit (2 lines changed)
    let input = edit_tool_input("test-session-small", "/project/small.rs", 3, 5);
    send_hook(&temp, "PostToolUse", &input);

    // Small edits should be ignored (less than 10 line diff, less than 50 total)
    let count = count_entries(&temp);
    assert_eq!(
        count, 0,
        "Small edits should be ignored. Got {} entries",
        count
    );
}

#[test]
#[ignore = "CLI commands removed - tests need MCP fixtures"]
fn test_post_tool_use_captures_writes() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    // Send Write tool event (new file creation)
    let input = write_tool_input("test-session-write", "/project/new_file.rs");
    send_hook(&temp, "PostToolUse", &input);

    // All Write operations should be captured
    let count = count_entries(&temp);
    assert!(
        count > 0,
        "Write operations should be captured. Got {} entries",
        count
    );
}

#[test]
#[ignore = "CLI commands removed - tests need MCP fixtures"]
fn test_post_tool_use_captures_significant_bash() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    // Send significant bash commands
    send_hook(
        &temp,
        "PostToolUse",
        &bash_tool_input("test-session", "cargo build", 0),
    );
    send_hook(
        &temp,
        "PostToolUse",
        &bash_tool_input("test-session", "cargo test", 0),
    );
    send_hook(
        &temp,
        "PostToolUse",
        &bash_tool_input("test-session", "git commit -m 'test'", 0),
    );

    // Significant commands should be captured
    let count = count_entries(&temp);
    assert!(
        count > 0,
        "Significant bash commands should be captured. Got {} entries",
        count
    );
}

// =============================================================================
// Part B: Stop Hook Synthesis Tests
// =============================================================================

#[test]
fn test_stop_handles_empty_session() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    // Send stop without any prior observations
    let input = stop_input("empty-session");
    let output = send_hook(&temp, "Stop", &input);

    // Should succeed without error
    assert!(
        !output.contains("error"),
        "Stop should handle empty sessions gracefully"
    );
}

#[test]
#[ignore = "CLI commands removed - tests need MCP fixtures"]
fn test_stop_creates_session_summary() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    let session_id = "summary-session";

    // Create some observations
    send_hook(
        &temp,
        "PostToolUse",
        &write_tool_input(session_id, "/src/main.rs"),
    );
    send_hook(
        &temp,
        "PostToolUse",
        &bash_tool_input(session_id, "cargo build", 0),
    );

    // End session
    send_hook(&temp, "Stop", &stop_input(session_id));

    // Should have created entries (observations or summary)
    let count = count_entries(&temp);
    assert!(
        count > 0,
        "Stop should create session entries. Got {} entries",
        count
    );
}

// =============================================================================
// Part C: SessionStart Context Injection Tests
// =============================================================================


#[test]
#[ignore = "CLI commands removed - tests need MCP fixtures"]
fn test_session_start_includes_tasks() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    // Create a task
    cas_cmd(&temp)
        .args(["task", "create", "Test task for context"])
        .assert()
        .success();

    // Send SessionStart
    let input = session_start_input("task-context-session");
    let output = send_hook(&temp, "SessionStart", &input);

    // Should include task info (may be in context or systemReminder)
    // The context should at least be non-empty if tasks exist
    assert!(
        !output.is_empty(),
        "SessionStart should return context with tasks"
    );
}


// =============================================================================
// Part D: End-to-End Flow Tests
// =============================================================================

#[test]
#[ignore = "CLI commands removed - tests need MCP fixtures"]
fn test_e2e_tool_use_to_entry() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    let session_id = "e2e-session";

    // Simulate session with tool uses
    send_hook(
        &temp,
        "PostToolUse",
        &write_tool_input(session_id, "/src/main.rs"),
    );
    send_hook(
        &temp,
        "PostToolUse",
        &bash_tool_input(session_id, "cargo build", 0),
    );
    send_hook(
        &temp,
        "PostToolUse",
        &bash_tool_input(session_id, "cargo test", 1),
    ); // error

    // End session
    send_hook(&temp, "Stop", &stop_input(session_id));

    // Verify entries were created
    let count = count_entries(&temp);
    assert!(
        count > 0,
        "E2E session should produce entries. Got {} entries",
        count
    );
}

#[test]
#[ignore = "CLI commands removed - tests need MCP fixtures"]
fn test_e2e_multiple_sessions() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    // Session 1
    send_hook(
        &temp,
        "PostToolUse",
        &write_tool_input("session-1", "/src/a.rs"),
    );
    send_hook(&temp, "Stop", &stop_input("session-1"));

    let count_after_s1 = count_entries(&temp);

    // Session 2
    send_hook(
        &temp,
        "PostToolUse",
        &write_tool_input("session-2", "/src/b.rs"),
    );
    send_hook(&temp, "Stop", &stop_input("session-2"));

    let count_after_s2 = count_entries(&temp);

    // Both sessions should create entries
    assert!(
        count_after_s1 > 0,
        "Session 1 should produce entries. Got {}",
        count_after_s1
    );
    assert!(
        count_after_s2 >= count_after_s1,
        "Session 2 should add entries. S1: {}, S2: {}",
        count_after_s1,
        count_after_s2
    );
}

#[test]
#[ignore = "CLI commands removed - tests need MCP fixtures"]
fn test_e2e_error_observation_captured() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    let session_id = "error-session";

    // Send only an error
    send_hook(
        &temp,
        "PostToolUse",
        &bash_tool_input(session_id, "cargo test", 1),
    );
    send_hook(&temp, "Stop", &stop_input(session_id));

    // Error should be captured
    let count = count_entries(&temp);
    assert!(
        count > 0,
        "Error observation should be captured. Got {} entries",
        count
    );
}

// =============================================================================
// Part E: Hook Configuration Tests
// =============================================================================

#[test]
fn test_hook_status_command() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    // Configure hooks
    cas_cmd(&temp)
        .args(["hook", "configure"])
        .assert()
        .success();

    // Check status
    cas_cmd(&temp)
        .args(["hook", "status"])
        .assert()
        .success()
        .stdout(
            predicate::str::contains("SessionStart").or(predicate::str::contains("configured")),
        );
}

#[test]
fn test_hook_configure_creates_settings() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    // Configure hooks
    cas_cmd(&temp)
        .args(["hook", "configure"])
        .assert()
        .success();

    // Verify settings file exists
    let settings_path = temp.path().join(".claude/settings.json");
    assert!(
        settings_path.exists(),
        "hook configure should create .claude/settings.json"
    );
}

// =============================================================================
// Part F: Exit Blocking Tests
// =============================================================================

/// Helper to register an agent via CLI, returns agent ID
