use crate::hooks::handlers::*;

#[test]
fn test_is_preference_prompt_edge_cases() {
    // Should handle mixed case
    assert!(is_preference_prompt("NEVER add TODO comments"));
    assert!(is_preference_prompt("ALWAYS use strict types"));

    // Should require meaningful content after keyword
    assert!(!is_preference_prompt("never")); // Just the keyword
    assert!(!is_preference_prompt("always")); // Just the keyword
}

// =========================================================================
// Extracted preference structure tests
// =========================================================================

#[test]
fn test_extracted_preference_deserialize() {
    let json = r#"{
        "content": "Never add TODO comments, always implement full functionality",
        "scope": "global",
        "confidence": 0.95
    }"#;

    let pref: ExtractedPreference = serde_json::from_str(json).unwrap();
    assert_eq!(
        pref.content,
        "Never add TODO comments, always implement full functionality"
    );
    assert_eq!(pref.scope, "global");
    assert_eq!(pref.confidence, 0.95);
}

#[test]
fn test_extracted_preference_with_path_pattern() {
    let json = r#"{
        "content": "Use strict TypeScript",
        "scope": "project",
        "confidence": 0.9,
        "path_pattern": "**/*.ts"
    }"#;

    let pref: ExtractedPreference = serde_json::from_str(json).unwrap();
    assert_eq!(pref.path_pattern, Some("**/*.ts".to_string()));
}



// =============================================================================
// GIT COMMIT DETECTION TESTS
// =============================================================================


#[test]
fn test_is_git_commit_command_with_heredoc() {
    let cmd = r#"git commit -m "$(cat <<'EOF'
Commit message here.
EOF
)""#;
    assert!(is_git_commit_command(cmd));
}

#[test]
fn test_is_git_commit_command_not_commit() {
    assert!(!is_git_commit_command("git status"));
    assert!(!is_git_commit_command("git push"));
    assert!(!is_git_commit_command("git add ."));
    assert!(!is_git_commit_command("git log"));
}


#[test]
fn test_extract_commit_hash_standard_output() {
    let stdout = "[main abc1234] Add new feature\n 1 file changed, 10 insertions(+)";
    assert_eq!(extract_commit_hash(stdout), Some("abc1234".to_string()));
}

#[test]
fn test_extract_commit_hash_with_branch_prefix() {
    let stdout = "[feature/auth 9f8e7d6] Implement login\n 3 files changed";
    assert_eq!(extract_commit_hash(stdout), Some("9f8e7d6".to_string()));
}


#[test]
fn test_extract_commit_hash_no_match() {
    let stdout = "nothing to commit, working tree clean";
    assert_eq!(extract_commit_hash(stdout), None);

    let stdout2 = "error: pathspec 'foo' did not match any file(s)";
    assert_eq!(extract_commit_hash(stdout2), None);
}

#[test]
fn test_extract_commit_message_simple() {
    assert_eq!(
        extract_commit_message("git commit -m \"Add new feature\""),
        Some("Add new feature".to_string())
    );
}

#[test]
fn test_extract_commit_message_single_quotes() {
    assert_eq!(
        extract_commit_message("git commit -m 'Fix bug'"),
        Some("Fix bug".to_string())
    );
}

#[test]
fn test_extract_commit_message_long_flag() {
    assert_eq!(
        extract_commit_message("git commit --message=\"Update docs\""),
        Some("Update docs".to_string())
    );
}

#[test]
fn test_extract_commit_message_heredoc() {
    let cmd = r#"git commit -m "$(cat <<'EOF'
This is a multi-line
commit message
EOF
)""#;
    let result = extract_commit_message(cmd);
    assert!(result.is_some());
    let msg = result.unwrap();
    assert!(msg.contains("multi-line"));
}

#[test]
fn test_extract_commit_message_no_message() {
    assert_eq!(extract_commit_message("git commit"), None);
    assert_eq!(extract_commit_message("git status"), None);
}

// =========================================================================
// build_session_summary_context tests
// =========================================================================



#[test]
fn test_build_session_summary_context_already_has_summary() {
    use crate::store::mock::MockStore;

    // Create a store with an existing session summary
    let mut entry = Entry::new(
        "entry-001".to_string(),
        "Previous session summary".to_string(),
    );
    entry.session_id = Some("test-session".to_string());
    entry.tags = vec!["session-summary".to_string()];
    let store = MockStore::with_entries(vec![entry]);

    let mut config = Config::default();
    let mut hook_config = crate::config::HookConfig::default();
    hook_config.stop.generate_summary = true;
    config.hooks = Some(hook_config);

    // Should return None since a summary already exists
    let result = build_session_summary_context(&store, &config, "test-session");
    assert!(result.is_none());
}




// =========================================================================
// build_learning_review_context tests
// =========================================================================

#[test]
fn test_build_learning_review_context_disabled() {
    use crate::store::mock::MockStore;

    let store = MockStore::new();
    let config = Config::default();

    // Default config has learning_review_enabled = false
    let result = build_learning_review_context(&store, &config);
    assert!(result.is_none());
}

#[test]
fn test_build_learning_review_context_below_threshold() {
    use crate::store::mock::MockStore;
    use crate::types::EntryType;

    // Create 3 unreviewed learnings (below threshold of 5)
    let entries: Vec<Entry> = (0..3)
        .map(|i| {
            let mut entry = Entry::new(format!("entry-{i}"), format!("Learning {i}"));
            entry.entry_type = EntryType::Learning;
            entry.last_reviewed = None; // Unreviewed
            entry
        })
        .collect();
    let store = MockStore::with_entries(entries);

    let mut config = Config::default();
    let mut hook_config = crate::config::HookConfig::default();
    hook_config.stop.learning_review_enabled = true;
    hook_config.stop.learning_review_threshold = 5;
    config.hooks = Some(hook_config);

    // Should return None since count (3) < threshold (5)
    let result = build_learning_review_context(&store, &config);
    assert!(result.is_none());
}

#[test]
fn test_build_learning_review_context_at_threshold() {
    use crate::store::mock::MockStore;
    use crate::types::EntryType;

    // Create 5 unreviewed learnings (at threshold of 5)
    let entries: Vec<Entry> = (0..5)
        .map(|i| {
            let mut entry = Entry::new(format!("entry-{i}"), format!("Learning {i}"));
            entry.entry_type = EntryType::Learning;
            entry.last_reviewed = None; // Unreviewed
            entry
        })
        .collect();
    let store = MockStore::with_entries(entries);

    let mut config = Config::default();
    let mut hook_config = crate::config::HookConfig::default();
    hook_config.stop.learning_review_enabled = true;
    hook_config.stop.learning_review_threshold = 5;
    config.hooks = Some(hook_config);

    // Should return Some since count (5) >= threshold (5)
    let result = build_learning_review_context(&store, &config);
    assert!(result.is_some());
    let context = result.unwrap();
    assert!(context.contains("learning-review required=\"true\""));
    assert!(context.contains("learning-reviewer"));
}

#[test]
fn test_build_learning_review_context_above_threshold() {
    use crate::store::mock::MockStore;
    use crate::types::EntryType;

    // Create 10 unreviewed learnings (above threshold of 5)
    let entries: Vec<Entry> = (0..10)
        .map(|i| {
            let mut entry = Entry::new(format!("entry-{i}"), format!("Learning {i}"));
            entry.entry_type = EntryType::Learning;
            entry.last_reviewed = None; // Unreviewed
            entry
        })
        .collect();
    let store = MockStore::with_entries(entries);

    let mut config = Config::default();
    let mut hook_config = crate::config::HookConfig::default();
    hook_config.stop.learning_review_enabled = true;
    hook_config.stop.learning_review_threshold = 5;
    config.hooks = Some(hook_config);

    // Should return Some since count (10) >= threshold (5)
    let result = build_learning_review_context(&store, &config);
    assert!(result.is_some());
    let context = result.unwrap();
    assert!(context.contains("learning-review required=\"true\""));
    assert!(context.contains("10 entries"));
}

#[test]
fn test_build_learning_review_context_threshold_zero() {
    use crate::store::mock::MockStore;

    let store = MockStore::new();
    let mut config = Config::default();
    let mut hook_config = crate::config::HookConfig::default();
    hook_config.stop.learning_review_enabled = true;
    hook_config.stop.learning_review_threshold = 0; // Invalid threshold
    config.hooks = Some(hook_config);

    // Should return error context since threshold = 0 is invalid
    let result = build_learning_review_context(&store, &config);
    assert!(
        result.is_some(),
        "threshold=0 should return error context, not None"
    );
    let context = result.unwrap();
    assert!(
        context.contains("learning-review-error"),
        "Error context should indicate error: {context}"
    );
    assert!(
        context.contains("threshold"),
        "Error context should mention threshold: {context}"
    );
}
