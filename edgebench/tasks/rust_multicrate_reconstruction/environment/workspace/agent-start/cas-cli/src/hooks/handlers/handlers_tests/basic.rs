use crate::hooks::handlers::*;






#[test]
fn test_extracted_learning_array_parse() {
    let json = r#"[
        {"content": "Rule 1", "path_pattern": null, "confidence": 0.8, "tags": []},
        {"content": "Rule 2", "path_pattern": "**/*.rs", "confidence": 0.9, "tags": ["rust"]}
    ]"#;

    let learnings: Vec<ExtractedLearning> = serde_json::from_str(json).unwrap();
    assert_eq!(learnings.len(), 2);
    assert_eq!(learnings[0].content, "Rule 1");
    assert_eq!(learnings[1].path_pattern, Some("**/*.rs".to_string()));
}

#[test]
fn test_truncate_str() {
    assert_eq!(truncate_str("short", 10), "short");
    assert_eq!(truncate_str("this is a long string", 10), "this is...");
    assert_eq!(truncate_str("exactly10c", 10), "exactly10c");
}

#[test]
fn test_truncate_list() {
    let items = vec!["a", "b", "c"];
    assert_eq!(truncate_list(&items, 5), "a, b, c");
    assert_eq!(truncate_list(&items, 2), "a, b, ... (+1 more)");
}

#[test]
fn test_is_architectural_file() {
    assert!(is_architectural_file("Cargo.toml"));
    assert!(is_architectural_file("/path/to/package.json"));
    assert!(is_architectural_file("/project/src/main.rs")); // needs /src/main. pattern
    assert!(is_architectural_file("lib/my_app/src/store/user.ex")); // contains /src/store/
    assert!(!is_architectural_file("src/components/Button.tsx"));
    assert!(!is_architectural_file("README.md"));
}

// =========================================================================
// should_buffer_observation tests
// =========================================================================

fn make_hook_input(
    tool: &str,
    tool_input: serde_json::Value,
    tool_response: Option<serde_json::Value>,
) -> HookInput { todo!() }

#[test]
fn test_should_buffer_bash_error() {
    let input = make_hook_input(
        "Bash",
        serde_json::json!({"command": "cargo build"}),
        Some(serde_json::json!({"exitCode": 1})),
    );
    assert!(should_buffer_observation(&input, "Bash"));
}




#[test]
fn test_should_buffer_write_always() {
    let input = make_hook_input(
        "Write",
        serde_json::json!({"file_path": "/test/file.rs", "content": "fn main() {}"}),
        None,
    );
    assert!(should_buffer_observation(&input, "Write"));
}


#[test]
fn test_should_not_buffer_edit_small() {
    // Small edit (2 lines difference)
    let input = make_hook_input(
        "Edit",
        serde_json::json!({"file_path": "/test/file.rs", "old_string": "a\nb", "new_string": "c\nd\ne\nf"}),
        None,
    );
    assert!(!should_buffer_observation(&input, "Edit"));
}


#[test]
fn test_should_buffer_git_commit() {
    let input = make_hook_input(
        "Bash",
        serde_json::json!({"command": "git commit -m 'fix: bug'"}),
        Some(serde_json::json!({"exitCode": 0})),
    );
    assert!(should_buffer_observation(&input, "Bash"));
}

#[test]
fn test_should_buffer_npm_test() {
    let input = make_hook_input(
        "Bash",
        serde_json::json!({"command": "npm test"}),
        Some(serde_json::json!({"exitCode": 0})),
    );
    assert!(should_buffer_observation(&input, "Bash"));
}

#[test]
fn test_should_buffer_mix_test() {
    let input = make_hook_input(
        "Bash",
        serde_json::json!({"command": "mix test"}),
        Some(serde_json::json!({"exitCode": 0})),
    );
    assert!(should_buffer_observation(&input, "Bash"));
}

// =========================================================================
// is_important_prompt tests
// =========================================================================

#[test]
fn test_is_important_prompt_task_indicators() {
    assert!(is_important_prompt("implement a new feature"));
    assert!(is_important_prompt("create a user login page"));
    assert!(is_important_prompt("add authentication to the API"));
    assert!(is_important_prompt("fix the bug in the parser"));
    assert!(is_important_prompt("update the database schema"));
    assert!(is_important_prompt("refactor the legacy code"));
    assert!(is_important_prompt("build the Docker image"));
    assert!(is_important_prompt("write unit tests for this"));
    assert!(is_important_prompt("help me understand the code"));
    assert!(is_important_prompt("can you explain this function?"));
}


#[test]
fn test_is_important_prompt_long() {
    // Long prompts (>100 chars) are considered important
    let long_prompt = "a".repeat(101);
    assert!(is_important_prompt(&long_prompt));
}

#[test]
fn test_is_not_important_prompt_short() {
    assert!(!is_important_prompt("yes"));
    assert!(!is_important_prompt("ok"));
    assert!(!is_important_prompt("sure"));
    assert!(!is_important_prompt("thanks"));
    assert!(!is_important_prompt("no"));
}

// =========================================================================
// format_bash_command tests
// =========================================================================



#[test]
fn test_format_bash_skips_readonly_git() {
    let readonly_git = vec![
        "git status",
        "git log",
        "git diff",
        "git show",
        "git branch",
    ];
    for cmd in readonly_git {
        let input = make_hook_input("Bash", serde_json::json!({"command": cmd}), None);
        let obs = format_observation(&input, None);
        assert!(obs.is_empty(), "Should skip read-only git: {cmd}");
    }
}

#[test]
fn test_format_bash_captures_git_commit() {
    let input = make_hook_input(
        "Bash",
        serde_json::json!({"command": "git commit -m 'test'"}),
        None,
    );
    let obs = format_observation(&input, None);
    assert_eq!(obs, "Bash: git commit -m 'test'");
}

#[test]
fn test_format_bash_truncates_long() {
    let long_cmd = "a".repeat(250);
    let input = make_hook_input("Bash", serde_json::json!({"command": long_cmd}), None);
    let obs = format_observation(&input, None);
    assert!(obs.len() < 220); // "Bash: " + 200 chars + "..."
    assert!(obs.ends_with("..."));
}

// =========================================================================
// format_file_read tests
// =========================================================================

#[test]
fn test_format_file_read_skips_common() {
    let skip_extensions = vec![
        "README.md",
        "config.json",
        "settings.yaml",
        "data.yml",
        "Cargo.toml",
    ];
    for file in skip_extensions {
        let input = make_hook_input("Read", serde_json::json!({"file_path": file}), None);
        let obs = format_file_read(&input, None);
        assert!(obs.is_empty(), "Should skip: {file}");
    }
}

#[test]
fn test_format_file_read_captures_code() {
    let input = make_hook_input(
        "Read",
        serde_json::json!({"file_path": "/src/main.rs"}),
        None,
    );
    let obs = format_file_read(&input, None);
    assert_eq!(obs, "Read: /src/main.rs");
}

// =========================================================================
// estimate_tokens tests
// =========================================================================


// =========================================================================
// SessionSummary tests
// =========================================================================

#[test]
fn test_session_summary_default() {
    let summary = SessionSummary::default();
    assert!(summary.summary.is_empty());
    assert!(summary.decisions.is_empty());
    assert!(summary.tasks_completed.is_empty());
    assert!(summary.key_learnings.is_empty());
    assert!(summary.follow_up_tasks.is_empty());
}

#[test]
fn test_session_summary_serialize() {
    let summary = SessionSummary {
        summary: "Completed task".to_string(),
        decisions: vec!["Use async".to_string()],
        tasks_completed: vec!["Fix bug".to_string()],
        key_learnings: vec!["Pattern X works".to_string()],
        follow_up_tasks: vec!["Add tests".to_string()],
    };
    let json = serde_json::to_string(&summary).unwrap();
    assert!(json.contains("Completed task"));
    assert!(json.contains("Use async"));
}

#[test]
fn test_session_summary_deserialize() {
    let json = r#"{
        "summary": "Test summary",
        "decisions": ["Decision 1"],
        "tasks_completed": [],
        "key_learnings": ["Learning 1", "Learning 2"],
        "follow_up_tasks": []
    }"#;
    let summary: SessionSummary = serde_json::from_str(json).unwrap();
    assert_eq!(summary.summary, "Test summary");
    assert_eq!(summary.decisions.len(), 1);
    assert_eq!(summary.key_learnings.len(), 2);
}

// =========================================================================
// is_architectural_file additional tests
// =========================================================================

#[test]
fn test_is_architectural_file_config_files() {
    // Test all config patterns
    assert!(is_architectural_file("pyproject.toml"));
    assert!(is_architectural_file("go.mod"));
    assert!(is_architectural_file("tsconfig.json"));
    assert!(is_architectural_file("webpack.config.js"));
    assert!(is_architectural_file("vite.config.ts"));
    assert!(is_architectural_file(".eslintrc"));
    assert!(is_architectural_file(".prettierrc"));
    assert!(is_architectural_file("CMakeLists.txt"));
}

#[test]
fn test_is_architectural_file_patterns() {
    // Test architectural patterns - must contain /src/ prefix for most patterns
    assert!(is_architectural_file("/src/lib.rs"));
    assert!(is_architectural_file("/project/src/mod.rs"));
    assert!(is_architectural_file("app/src/types/user.ts"));
    assert!(is_architectural_file("src/schema.prisma"));
    assert!(is_architectural_file("db/migrations/001_create_users.sql"));
    assert!(is_architectural_file("/src/api/routes.ts"));
    assert!(is_architectural_file("/src/models/user.rs"));
    assert!(is_architectural_file("/src/handlers/auth.go"));
}

#[test]
fn test_is_not_architectural_file() {
    assert!(!is_architectural_file("test.rs"));
    assert!(!is_architectural_file("utils.js"));
    assert!(!is_architectural_file("helper.py"));
    assert!(!is_architectural_file("style.css"));
}

// =========================================================================
// truncate_str edge cases
// =========================================================================

#[test]
fn test_truncate_str_edge_cases() {
    assert_eq!(truncate_str("", 10), "");
    assert_eq!(truncate_str("a", 10), "a");
    assert_eq!(truncate_str("ab", 10), "ab");
    assert_eq!(truncate_str("abc", 3), "abc");
    assert_eq!(truncate_str("abcd", 3), "...");
    assert_eq!(truncate_str("abcde", 4), "a...");
}

#[test]
fn test_truncate_str_handles_unicode_boundary() {
    let input = format!("{}✅ done", "a".repeat(99));
    assert_eq!(truncate_str(&input, 103), format!("{}...", "a".repeat(99)));
}

// =========================================================================
// truncate_list edge cases
// =========================================================================

#[test]
fn test_truncate_list_edge_cases() {
    let empty: Vec<&str> = vec![];
    assert_eq!(truncate_list(&empty, 5), "");

    let single = vec!["one"];
    assert_eq!(truncate_list(&single, 5), "one");
    assert_eq!(truncate_list(&single, 1), "one");

    let many = vec!["a", "b", "c", "d", "e"];
    assert_eq!(truncate_list(&many, 3), "a, b, c, ... (+2 more)");
    assert_eq!(truncate_list(&many, 5), "a, b, c, d, e");
    assert_eq!(truncate_list(&many, 10), "a, b, c, d, e");
}

// =========================================================================
// format_observation edge cases
// =========================================================================

#[test]
fn test_format_observation_unknown_tool() {
    let input = make_hook_input("Unknown", serde_json::json!({}), None);
    let obs = format_observation(&input, None);
    assert!(obs.is_empty());
}


#[test]
fn test_format_observation_edit() {
    let input = make_hook_input(
        "Edit",
        serde_json::json!({"file_path": "/src/lib.rs", "old_string": "old", "new_string": "new"}),
        None,
    );
    let obs = format_observation(&input, None);
    assert_eq!(obs, "Edit: /src/lib.rs");
}

// =========================================================================
// User preference detection tests
// =========================================================================


#[test]
fn test_is_preference_prompt_always_pattern() {
    assert!(is_preference_prompt("always implement full functionality"));
    assert!(is_preference_prompt("Always use TypeScript strict mode"));
    assert!(is_preference_prompt("always run tests before committing"));
}

#[test]
fn test_is_preference_prompt_dont_pattern() {
    assert!(is_preference_prompt(
        "don't add TODOs, implement the actual code"
    ));
    assert!(is_preference_prompt("Do not use console.log for debugging"));
    assert!(is_preference_prompt("dont leave placeholder comments"));
}

#[test]
fn test_is_preference_prompt_prefer_pattern() {
    assert!(is_preference_prompt(
        "I prefer functional components over class components"
    ));
    assert!(is_preference_prompt("prefer async/await over .then()"));
}

#[test]
fn test_is_preference_prompt_instead_pattern() {
    assert!(is_preference_prompt("use Result instead of panic"));
    assert!(is_preference_prompt("use match instead of if-let chains"));
}

