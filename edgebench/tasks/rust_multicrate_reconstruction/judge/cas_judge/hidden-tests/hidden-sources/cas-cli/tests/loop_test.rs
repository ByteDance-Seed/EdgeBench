#[test]
#[ignore = "loop CLI command removed - tests need MCP fixtures"]
fn test_loop_start_with_promise_and_max_iterations() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    // Start a loop with options
    cas_cmd(&temp)
        .args([
            "loop",
            "start",
            "Build the thing",
            "--session",
            "test-session-002",
            "--promise",
            "DONE",
            "--max-iterations",
            "5",
            "--json",
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains("\"max_iterations\": 5"));

    // Verify options are set
    let status = get_loop_status(&temp, "test-session-002");
    assert_eq!(
        status.get("max_iterations").and_then(|v| v.as_i64()),
        Some(5)
    );
    assert_eq!(status.get("promise").and_then(|v| v.as_str()), Some("DONE"));
}

#[test]
#[ignore = "loop CLI command removed - tests need MCP fixtures"]
fn test_loop_prevents_duplicate_for_session() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    // Start first loop
    cas_cmd(&temp)
        .args(["loop", "start", "First task", "--session", "same-session"])
        .assert()
        .success();

    // Try to start another for same session (should fail)
    cas_cmd(&temp)
        .args([
            "loop",
            "start",
            "Second task",
            "--session",
            "same-session",
            "--json",
        ])
        .assert()
        .failure()
        .stdout(predicate::str::contains("\"error\""));
}

#[test]
#[ignore = "loop CLI command removed - tests need MCP fixtures"]
fn test_stop_hook_respects_max_iterations() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    // Start a loop with max 2 iterations
    cas_cmd(&temp)
        .args([
            "loop",
            "start",
            "Limited iterations",
            "--session",
            "max-iter-session",
            "--max-iterations",
            "2",
        ])
        .assert()
        .success();

    // First Stop - should block (iteration 1 -> 2)
    let output1 = send_hook(&temp, "Stop", &stop_input("max-iter-session"));
    let response1: serde_json::Value = serde_json::from_str(&output1).unwrap_or_default();
    assert_eq!(
        response1.get("decision").and_then(|v| v.as_str()),
        Some("block"),
        "First Stop should block exit"
    );

    // Second Stop - should allow exit (max reached)
    let output2 = send_hook(&temp, "Stop", &stop_input("max-iter-session"));
    let response2: serde_json::Value = serde_json::from_str(&output2).unwrap_or_default();
    // When max is reached, we return empty output (allow exit)
    assert!(
        response2.get("decision").is_none()
            || response2.get("decision").and_then(|v| v.as_str()) != Some("block"),
        "Second Stop should allow exit after max iterations"
    );

    // Verify loop is no longer active
    let status = get_loop_status(&temp, "max-iter-session");
    assert_eq!(status.get("active").and_then(|v| v.as_bool()), Some(false));
}

#[test]
#[ignore = "loop CLI command removed - tests need MCP fixtures"]
fn test_completion_promise_in_transcript() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    // Create a mock transcript file with the promise
    let transcript_path = temp.path().join("test_transcript.jsonl");
    let transcript_content = r#"{"type":"assistant","message":{"content":[{"type":"text","text":"I have completed the task. <promise>DONE</promise>"}]}}
"#;
    std::fs::write(&transcript_path, transcript_content).unwrap();

    // Start a loop with promise
    cas_cmd(&temp)
        .args([
            "loop",
            "start",
            "Work until done",
            "--session",
            "promise-test-session",
            "--promise",
            "DONE",
        ])
        .assert()
        .success();

    // Send Stop hook with transcript path
    let input =
        stop_input_with_transcript("promise-test-session", transcript_path.to_str().unwrap());
    let output = send_hook(&temp, "Stop", &input);

    // Should allow exit (promise detected)
    let response: serde_json::Value = serde_json::from_str(&output).unwrap_or_default();
    assert!(
        response.get("decision").is_none()
            || response.get("decision").and_then(|v| v.as_str()) != Some("block"),
        "Stop hook should allow exit when promise is detected"
    );

    // Verify loop is completed
    let status = get_loop_status(&temp, "promise-test-session");
    assert_eq!(status.get("active").and_then(|v| v.as_bool()), Some(false));
}

#[test]
#[ignore = "loop CLI command removed - tests need MCP fixtures"]
fn test_loop_continues_without_promise() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    // Create a transcript without the promise
    let transcript_path = temp.path().join("test_transcript2.jsonl");
    let transcript_content = r#"{"type":"assistant","message":{"content":[{"type":"text","text":"Still working on it..."}]}}
"#;
    std::fs::write(&transcript_path, transcript_content).unwrap();

    // Start a loop with promise
    cas_cmd(&temp)
        .args([
            "loop",
            "start",
            "Work until DONE",
            "--session",
            "no-promise-session",
            "--promise",
            "DONE",
        ])
        .assert()
        .success();

    // Send Stop hook with transcript path
    let input = stop_input_with_transcript("no-promise-session", transcript_path.to_str().unwrap());
    let output = send_hook(&temp, "Stop", &input);

    // Should block exit (promise not found)
    let response: serde_json::Value = serde_json::from_str(&output).unwrap_or_default();
    assert_eq!(
        response.get("decision").and_then(|v| v.as_str()),
        Some("block"),
        "Stop hook should block exit when promise is not found"
    );

    // Verify loop is still active
    let status = get_loop_status(&temp, "no-promise-session");
    assert_eq!(
        status.get("status").and_then(|v| v.as_str()),
        Some("active")
    );
}

#[test]
#[ignore = "loop CLI command removed - tests need MCP fixtures"]
fn test_loop_with_empty_prompt() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    // Start a loop with minimal prompt
    cas_cmd(&temp)
        .args(["loop", "start", "x", "--session", "minimal-session"])
        .assert()
        .success();

    // Should work
    let status = get_loop_status(&temp, "minimal-session");
    assert_eq!(
        status.get("status").and_then(|v| v.as_str()),
        Some("active")
    );
}
