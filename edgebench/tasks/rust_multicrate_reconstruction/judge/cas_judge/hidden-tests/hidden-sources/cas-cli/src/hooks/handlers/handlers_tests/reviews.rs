#[test]
fn test_build_learning_review_context_only_counts_unreviewed() {
    use crate::store::mock::MockStore;
    use crate::types::EntryType;

    // Create 5 learnings but only 3 are unreviewed
    let mut entries: Vec<Entry> = (0..3)
        .map(|i| {
            let mut entry = Entry::new(format!("entry-{i}"), format!("Learning {i}"));
            entry.entry_type = EntryType::Learning;
            entry.last_reviewed = None; // Unreviewed
            entry
        })
        .collect();

    // Add 2 reviewed learnings
    for i in 3..5 {
        let mut entry = Entry::new(format!("entry-{i}"), format!("Learning {i}"));
        entry.entry_type = EntryType::Learning;
        entry.last_reviewed = Some(chrono::Utc::now()); // Reviewed
        entries.push(entry);
    }

    let store = MockStore::with_entries(entries);

    let mut config = Config::default();
    let mut hook_config = crate::config::HookConfig::default();
    hook_config.stop.learning_review_enabled = true;
    hook_config.stop.learning_review_threshold = 5;
    config.hooks = Some(hook_config);

    // Should return None since only 3 unreviewed (< threshold of 5)
    let result = build_learning_review_context(&store, &config);
    assert!(result.is_none());
}

#[test]
fn test_build_rule_review_context_disabled() {
    use crate::store::mock::MockRuleStore;

    let rule_store = MockRuleStore::new();
    let config = Config::default();

    // Default config has rule_review_enabled = false
    let result = build_rule_review_context(&rule_store, &config);
    assert!(result.is_none());
}

#[test]
fn test_build_rule_review_context_below_threshold() {
    use crate::store::mock::MockRuleStore;
    use crate::types::{Rule, RuleStatus};

    // Create 3 draft rules (below threshold of 5)
    let rules: Vec<Rule> = (0..3)
        .map(|i| {
            let mut rule = Rule::new(format!("rule-{i}"), format!("Rule content {i}"));
            rule.status = RuleStatus::Draft;
            rule
        })
        .collect();
    let rule_store = MockRuleStore::with_rules(rules);

    let mut config = Config::default();
    let mut hook_config = crate::config::HookConfig::default();
    hook_config.stop.rule_review_enabled = true;
    hook_config.stop.rule_review_threshold = 5;
    config.hooks = Some(hook_config);

    // Should return None since count (3) < threshold (5)
    let result = build_rule_review_context(&rule_store, &config);
    assert!(result.is_none());
}

#[test]
fn test_build_duplicate_detection_context_store_error() {
    use crate::store::mock::MockStore;
    use cas_store::StoreError;

    // Create a store and inject an error
    let store = MockStore::new();
    store.inject_error(StoreError::Other("Test store error".to_string()));

    let mut config = Config::default();
    let mut hook_config = crate::config::HookConfig::default();
    hook_config.stop.duplicate_detection_enabled = true;
    hook_config.stop.duplicate_detection_threshold = 20;
    config.hooks = Some(hook_config);

    // Should return Some with error context (not None - fail explicitly, don't skip)
    let result = build_duplicate_detection_context(&store, &config);
    assert!(
        result.is_some(),
        "Store error should return error context, not None"
    );
    let context = result.unwrap();
    assert!(
        context.contains("duplicate-detection-error"),
        "Error context should indicate error: {context}"
    );
    assert!(
        context.contains("Failed to check"),
        "Error context should explain the failure: {context}"
    );
}
