#[test]
fn test_generate_file_change_id_format() {
    let id = generate_file_change_id();
    assert!(id.starts_with("fc-"));
    assert!(id.len() > 10); // Should have timestamp and random parts
}

#[test]
fn test_compute_content_hash_consistency() {
    let hash1 = compute_content_hash("test content");
    let hash2 = compute_content_hash("test content");
    let hash3 = compute_content_hash("different content");

    assert_eq!(hash1, hash2); // Same content = same hash
    assert_ne!(hash1, hash3); // Different content = different hash
}

#[test]
fn test_is_git_commit_command_simple() {
    assert!(is_git_commit_command("git commit -m \"message\""));
    assert!(is_git_commit_command("git commit -am \"message\""));
    assert!(is_git_commit_command("git commit --message=\"message\""));
}

#[test]
fn test_is_git_commit_command_dry_run_excluded() {
    assert!(!is_git_commit_command("git commit --dry-run -m \"test\""));
    assert!(!is_git_commit_command("git commit -m \"test\" --dry-run"));
}

#[test]
fn test_extract_commit_hash_full_hash() {
    let stdout = "abcdef1234567890abcdef1234567890abcdef12";
    assert_eq!(
        extract_commit_hash(stdout),
        Some("abcdef1234567890abcdef1234567890abcdef12".to_string())
    );
}

#[test]
fn test_build_session_summary_context_disabled() {
    use crate::store::mock::MockStore;

    let store = MockStore::new();
    let config = Config::default();

    // Default config has generate_summary = false
    let result = build_session_summary_context(&store, &config, "test-session");
    assert!(result.is_none());
}

#[test]
fn test_build_session_summary_context_enabled() {
    use crate::store::mock::MockStore;

    let store = MockStore::new();
    let mut config = Config::default();

    // Enable generate_summary by creating a HookConfig with it enabled
    let mut hook_config = crate::config::HookConfig::default();
    hook_config.stop.generate_summary = true;
    config.hooks = Some(hook_config);

    let result = build_session_summary_context(&store, &config, "test-session");
    assert!(result.is_some());
    let context = result.unwrap();
    assert!(context.contains("session-summary required=\"true\""));
    assert!(context.contains("session-summarizer"));
}

#[test]
fn test_build_session_summary_context_different_session() {
    use crate::store::mock::MockStore;

    // Create a store with a summary for a different session
    let mut entry = Entry::new("entry-001".to_string(), "Other session summary".to_string());
    entry.session_id = Some("other-session".to_string());
    entry.tags = vec!["session-summary".to_string()];
    let store = MockStore::with_entries(vec![entry]);

    let mut config = Config::default();
    let mut hook_config = crate::config::HookConfig::default();
    hook_config.stop.generate_summary = true;
    config.hooks = Some(hook_config);

    // Should return Some since no summary exists for "test-session"
    let result = build_session_summary_context(&store, &config, "test-session");
    assert!(result.is_some());
}

#[test]
fn test_build_session_summary_context_has_summary_tag() {
    use crate::store::mock::MockStore;

    // Create a store with an entry that has just the "summary" tag
    let mut entry = Entry::new("entry-001".to_string(), "Summary entry".to_string());
    entry.session_id = Some("test-session".to_string());
    entry.tags = vec!["summary".to_string()];
    let store = MockStore::with_entries(vec![entry]);

    let mut config = Config::default();
    let mut hook_config = crate::config::HookConfig::default();
    hook_config.stop.generate_summary = true;
    config.hooks = Some(hook_config);

    // Should return None since a summary (with "summary" tag) already exists
    let result = build_session_summary_context(&store, &config, "test-session");
    assert!(result.is_none());
}

#[test]
fn test_build_session_summary_context_store_error() {
    use crate::store::mock::MockStore;
    use cas_store::StoreError;

    // Create a store and inject an error
    let store = MockStore::new();
    store.inject_error(StoreError::Other("Test store error".to_string()));

    let mut config = Config::default();
    let mut hook_config = crate::config::HookConfig::default();
    hook_config.stop.generate_summary = true;
    config.hooks = Some(hook_config);

    // Should return Some with error context (not None - fail explicitly, don't skip)
    let result = build_session_summary_context(&store, &config, "test-session");
    assert!(
        result.is_some(),
        "Store error should return error context, not None"
    );
    let context = result.unwrap();
    assert!(
        context.contains("session-summary-error"),
        "Error context should indicate error: {context}"
    );
    assert!(
        context.contains("Failed to check"),
        "Error context should explain the failure: {context}"
    );
}
