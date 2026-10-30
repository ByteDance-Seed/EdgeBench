#[test]
fn test_post_tool_use_filters_simple_commands() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    // Send simple commands that should be filtered
    send_hook(
        &temp,
        "PostToolUse",
        &bash_tool_input("test-session", "ls -la", 0),
    );
    send_hook(
        &temp,
        "PostToolUse",
        &bash_tool_input("test-session", "cd /tmp", 0),
    );
    send_hook(
        &temp,
        "PostToolUse",
        &bash_tool_input("test-session", "pwd", 0),
    );

    // These should be filtered out
    let count = count_entries(&temp);
    assert_eq!(
        count, 0,
        "Simple commands (ls, cd, pwd) should be filtered out. Got {} entries",
        count
    );
}

#[test]
fn test_session_start_returns_json() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    // Send SessionStart
    let input = session_start_input("context-session");
    let output = send_hook(&temp, "SessionStart", &input);

    // Should return valid JSON
    let parsed: Result<serde_json::Value, _> = serde_json::from_str(&output);
    assert!(
        parsed.is_ok(),
        "SessionStart should return valid JSON. Got: {}",
        output
    );
}

#[test]
fn test_session_start_plan_mode() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    // Send SessionStart with plan mode
    let input = serde_json::json!({
        "session_id": "plan-mode-session",
        "cwd": "/test",
        "hook_event_name": "SessionStart",
        "permission_mode": "plan"
    });
    let output = send_hook(&temp, "SessionStart", &input);

    // Should return valid JSON (plan mode may have different context)
    let parsed: Result<serde_json::Value, _> = serde_json::from_str(&output);
    assert!(
        parsed.is_ok(),
        "SessionStart plan mode should return valid JSON. Got: {}",
        output
    );
}
