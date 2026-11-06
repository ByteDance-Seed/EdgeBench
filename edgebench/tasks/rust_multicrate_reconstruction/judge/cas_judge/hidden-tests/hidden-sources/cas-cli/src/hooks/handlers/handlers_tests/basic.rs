#[test]
fn test_format_file_change() {
    let input = HookInput {
        session_id: "test".to_string(),
        cwd: "/test".to_string(),
        hook_event_name: "PostToolUse".to_string(),
        tool_name: Some("Write".to_string()),
        tool_input: Some(serde_json::json!({"file_path": "/test/main.rs"})),
        tool_response: None,
        transcript_path: None,
        permission_mode: None,
        tool_use_id: None,
        user_prompt: None,
        source: None,
        reason: None,
        subagent_type: None,
        subagent_prompt: None,
    };

    let observation = format_observation(&input, None);
    assert_eq!(observation, "Write: /test/main.rs");
}

#[test]
fn test_format_bash_skips_simple() {
    let input = HookInput {
        session_id: "test".to_string(),
        cwd: "/test".to_string(),
        hook_event_name: "PostToolUse".to_string(),
        tool_name: Some("Bash".to_string()),
        tool_input: Some(serde_json::json!({"command": "ls -la"})),
        tool_response: None,
        transcript_path: None,
        permission_mode: None,
        tool_use_id: None,
        user_prompt: None,
        source: None,
        reason: None,
        subagent_type: None,
        subagent_prompt: None,
    };

    let observation = format_observation(&input, None);
    assert!(observation.is_empty());
}

#[test]
fn test_format_bash_captures_cargo() {
    let input = HookInput {
        session_id: "test".to_string(),
        cwd: "/test".to_string(),
        hook_event_name: "PostToolUse".to_string(),
        tool_name: Some("Bash".to_string()),
        tool_input: Some(serde_json::json!({"command": "cargo test"})),
        tool_response: None,
        transcript_path: None,
        permission_mode: None,
        tool_use_id: None,
        user_prompt: None,
        source: None,
        reason: None,
        subagent_type: None,
        subagent_prompt: None,
    };

    let observation = format_observation(&input, None);
    assert_eq!(observation, "Bash: cargo test");
}

#[test]
fn test_extracted_learning_deserialize() {
    let json = r#"{
        "content": "Use generated types from @/types/ instead of manual interfaces",
        "path_pattern": "**/*.tsx",
        "confidence": 0.9,
        "tags": ["react", "typescript"]
    }"#;

    let learning: ExtractedLearning = serde_json::from_str(json).unwrap();
    assert_eq!(
        learning.content,
        "Use generated types from @/types/ instead of manual interfaces"
    );
    assert_eq!(learning.path_pattern, Some("**/*.tsx".to_string()));
    assert_eq!(learning.confidence, 0.9);
    assert_eq!(learning.tags, vec!["react", "typescript"]);
}

#[test]
fn test_extracted_learning_null_path() {
    let json = r#"{
        "content": "Always run mix nb_ts.gen after changing serializers",
        "path_pattern": null,
        "confidence": 0.85,
        "tags": ["elixir", "phoenix"]
    }"#;

    let learning: ExtractedLearning = serde_json::from_str(json).unwrap();
    assert_eq!(learning.path_pattern, None);
}

#[test]
fn test_should_buffer_bash_success_build() {
    let input = make_hook_input(
        "Bash",
        serde_json::json!({"command": "cargo build"}),
        Some(serde_json::json!({"exitCode": 0})),
    );
    assert!(should_buffer_observation(&input, "Bash"));
}

#[test]
fn test_should_buffer_bash_success_test() {
    let input = make_hook_input(
        "Bash",
        serde_json::json!({"command": "cargo test"}),
        Some(serde_json::json!({"exitCode": 0})),
    );
    assert!(should_buffer_observation(&input, "Bash"));
}

#[test]
fn test_should_not_buffer_bash_simple_cmd() {
    let input = make_hook_input(
        "Bash",
        serde_json::json!({"command": "echo hello"}),
        Some(serde_json::json!({"exitCode": 0})),
    );
    assert!(!should_buffer_observation(&input, "Bash"));
}

#[test]
fn test_should_buffer_edit_large() {
    // Edit with 15 lines difference (>= 10 threshold)
    let old_string = "line1\nline2\nline3\nline4\nline5";
    let new_string = "new1\nnew2\nnew3\nnew4\nnew5\nnew6\nnew7\nnew8\nnew9\nnew10\nnew11\nnew12\nnew13\nnew14\nnew15\nnew16\nnew17\nnew18\nnew19\nnew20";
    let input = make_hook_input(
        "Edit",
        serde_json::json!({"file_path": "/test/file.rs", "old_string": old_string, "new_string": new_string}),
        None,
    );
    assert!(should_buffer_observation(&input, "Edit"));
}

#[test]
fn test_should_not_buffer_read() {
    let input = make_hook_input(
        "Read",
        serde_json::json!({"file_path": "/test/file.rs"}),
        None,
    );
    assert!(!should_buffer_observation(&input, "Read"));
}

#[test]
fn test_is_important_prompt_questions() {
    assert!(is_important_prompt("how does this work?"));
    assert!(is_important_prompt("what is the purpose of this file?"));
    assert!(is_important_prompt("why is this test failing?"));
    assert!(is_important_prompt("where is the config located?"));
    assert!(is_important_prompt("should I use async here?"));
    assert!(is_important_prompt("is there a better approach?"));
}

#[test]
fn test_format_bash_skips_navigation() {
    let skip_commands = vec![
        "cd /tmp",
        "pwd",
        "ls",
        "cat file.txt",
        "head -10 file",
        "tail -f log",
    ];
    for cmd in skip_commands {
        let input = make_hook_input("Bash", serde_json::json!({"command": cmd}), None);
        let obs = format_observation(&input, None);
        assert!(obs.is_empty(), "Should skip command: {cmd}");
    }
}

#[test]
fn test_format_bash_skips_cas_commands() {
    let input = make_hook_input(
        "Bash",
        serde_json::json!({"command": "cas search test"}),
        None,
    );
    let obs = format_observation(&input, None);
    assert!(obs.is_empty());
}

#[test]
fn test_estimate_tokens() {
    assert_eq!(estimate_tokens(""), 0);
    assert_eq!(estimate_tokens("test"), 1); // 4 chars / 4 = 1
    assert_eq!(estimate_tokens("12345678"), 2); // 8 chars / 4 = 2
    assert_eq!(estimate_tokens("a".repeat(100).as_str()), 25); // 100 chars / 4 = 25
}

#[test]
fn test_format_observation_no_tool_input() {
    let input = HookInput {
        session_id: "test".to_string(),
        cwd: "/test".to_string(),
        hook_event_name: "PostToolUse".to_string(),
        tool_name: Some("Write".to_string()),
        tool_input: None,
        tool_response: None,
        transcript_path: None,
        permission_mode: None,
        tool_use_id: None,
        user_prompt: None,
        source: None,
        reason: None,
        subagent_type: None,
        subagent_prompt: None,
    };
    let obs = format_observation(&input, None);
    assert!(obs.is_empty());
}

#[test]
fn test_is_preference_prompt_never_pattern() {
    assert!(is_preference_prompt("never add TODOs to the code"));
    assert!(is_preference_prompt(
        "Never add TODO comments, implement fully"
    ));
    assert!(is_preference_prompt("don't ever add placeholder code"));
}

#[test]
fn test_is_preference_prompt_negative_cases() {
    // Regular task requests should not be detected as preferences
    assert!(!is_preference_prompt("fix the bug in login"));
    assert!(!is_preference_prompt("add a new button to the header"));
    assert!(!is_preference_prompt("what does this function do?"));
    assert!(!is_preference_prompt("run the tests"));
    assert!(!is_preference_prompt("yes")); // Too short
    assert!(!is_preference_prompt("ok go ahead")); // Acknowledgment
}
