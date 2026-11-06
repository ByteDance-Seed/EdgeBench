use crate::hooks::handlers::*;

#[test]
fn test_build_learning_review_context_store_error() {
    use crate::store::mock::MockStore;
    use cas_store::StoreError;

    // Create a store and inject an error
    let store = MockStore::new();
    store.inject_error(StoreError::Other("Test store error".to_string()));

    let mut config = Config::default();
    let mut hook_config = crate::config::HookConfig::default();
    hook_config.stop.learning_review_enabled = true;
    hook_config.stop.learning_review_threshold = 5;
    config.hooks = Some(hook_config);

    // Should return Some with error context (not None - fail explicitly, don't skip)
    let result = build_learning_review_context(&store, &config);
    assert!(
        result.is_some(),
        "Store error should return error context, not None"
    );
    let context = result.unwrap();
    assert!(
        context.contains("learning-review-error"),
        "Error context should indicate error: {context}"
    );
    assert!(
        context.contains("Failed to check"),
        "Error context should explain the failure: {context}"
    );
}


// =========================================================================
// build_rule_review_context tests
// =========================================================================



#[test]
fn test_build_rule_review_context_at_threshold() {
    use crate::store::mock::MockRuleStore;
    use crate::types::{Rule, RuleStatus};

    // Create 5 draft rules (at threshold of 5)
    let rules: Vec<Rule> = (0..5)
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

    // Should return Some since count (5) >= threshold (5)
    let result = build_rule_review_context(&rule_store, &config);
    assert!(result.is_some());
    let context = result.unwrap();
    assert!(context.contains("rule-review required=\"true\""));
    assert!(context.contains("rule-reviewer"));
}

#[test]
fn test_build_rule_review_context_above_threshold() {
    use crate::store::mock::MockRuleStore;
    use crate::types::{Rule, RuleStatus};

    // Create 10 draft rules (above threshold of 5)
    let rules: Vec<Rule> = (0..10)
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

    // Should return Some since count (10) >= threshold (5)
    let result = build_rule_review_context(&rule_store, &config);
    assert!(result.is_some());
    let context = result.unwrap();
    assert!(context.contains("rule-review required=\"true\""));
    assert!(context.contains("10 rules"));
}

#[test]
fn test_build_rule_review_context_threshold_zero() {
    use crate::store::mock::MockRuleStore;

    let rule_store = MockRuleStore::new();
    let mut config = Config::default();
    let mut hook_config = crate::config::HookConfig::default();
    hook_config.stop.rule_review_enabled = true;
    hook_config.stop.rule_review_threshold = 0; // Invalid threshold
    config.hooks = Some(hook_config);

    // Should return error context since threshold = 0 is invalid
    let result = build_rule_review_context(&rule_store, &config);
    assert!(
        result.is_some(),
        "threshold=0 should return error context, not None"
    );
    let context = result.unwrap();
    assert!(
        context.contains("rule-review-error"),
        "Error context should indicate error: {context}"
    );
    assert!(
        context.contains("threshold"),
        "Error context should mention threshold: {context}"
    );
}

#[test]
fn test_build_rule_review_context_store_error() {
    use crate::store::mock::MockRuleStore;
    use cas_store::StoreError;

    // Create a rule store and inject an error
    let rule_store = MockRuleStore::new();
    rule_store.inject_error(StoreError::Other("Test store error".to_string()));

    let mut config = Config::default();
    let mut hook_config = crate::config::HookConfig::default();
    hook_config.stop.rule_review_enabled = true;
    hook_config.stop.rule_review_threshold = 5;
    config.hooks = Some(hook_config);

    // Should return Some with error context (not None - fail explicitly, don't skip)
    let result = build_rule_review_context(&rule_store, &config);
    assert!(
        result.is_some(),
        "Store error should return error context, not None"
    );
    let context = result.unwrap();
    assert!(
        context.contains("rule-review-error"),
        "Error context should indicate error: {context}"
    );
    assert!(
        context.contains("Failed to check"),
        "Error context should explain the failure: {context}"
    );
}

#[test]
fn test_build_rule_review_context_only_counts_draft() {
    use crate::store::mock::MockRuleStore;
    use crate::types::{Rule, RuleStatus};

    // Create 5 rules but only 3 are draft
    let mut rules: Vec<Rule> = (0..3)
        .map(|i| {
            let mut rule = Rule::new(format!("rule-{i}"), format!("Draft rule {i}"));
            rule.status = RuleStatus::Draft;
            rule
        })
        .collect();

    // Add 2 proven rules
    for i in 3..5 {
        let mut rule = Rule::new(format!("rule-{i}"), format!("Proven rule {i}"));
        rule.status = RuleStatus::Proven;
        rules.push(rule);
    }

    let rule_store = MockRuleStore::with_rules(rules);

    let mut config = Config::default();
    let mut hook_config = crate::config::HookConfig::default();
    hook_config.stop.rule_review_enabled = true;
    hook_config.stop.rule_review_threshold = 5;
    config.hooks = Some(hook_config);

    // Should return None since only 3 draft (< threshold of 5)
    let result = build_rule_review_context(&rule_store, &config);
    assert!(result.is_none());
}

// =========================================================================
// build_duplicate_detection_context tests
// =========================================================================

#[test]
fn test_build_duplicate_detection_context_disabled() {
    use crate::store::mock::MockStore;

    let store = MockStore::new();
    let config = Config::default();

    // Default config has duplicate_detection_enabled = false
    let result = build_duplicate_detection_context(&store, &config);
    assert!(result.is_none());
}

#[test]
fn test_build_duplicate_detection_context_below_threshold() {
    use crate::store::mock::MockStore;

    // Create 10 entries (below threshold of 20)
    let entries: Vec<Entry> = (0..10)
        .map(|i| Entry::new(format!("entry-{i}"), format!("Entry content {i}")))
        .collect();
    let store = MockStore::with_entries(entries);

    let mut config = Config::default();
    let mut hook_config = crate::config::HookConfig::default();
    hook_config.stop.duplicate_detection_enabled = true;
    hook_config.stop.duplicate_detection_threshold = 20;
    config.hooks = Some(hook_config);

    // Should return None since count (10) < threshold (20)
    let result = build_duplicate_detection_context(&store, &config);
    assert!(result.is_none());
}

#[test]
fn test_build_duplicate_detection_context_at_threshold() {
    use crate::store::mock::MockStore;

    // Create 20 entries (at threshold of 20)
    let entries: Vec<Entry> = (0..20)
        .map(|i| Entry::new(format!("entry-{i}"), format!("Entry content {i}")))
        .collect();
    let store = MockStore::with_entries(entries);

    let mut config = Config::default();
    let mut hook_config = crate::config::HookConfig::default();
    hook_config.stop.duplicate_detection_enabled = true;
    hook_config.stop.duplicate_detection_threshold = 20;
    config.hooks = Some(hook_config);

    // Should return Some since count (20) >= threshold (20)
    let result = build_duplicate_detection_context(&store, &config);
    assert!(result.is_some());
    let context = result.unwrap();
    assert!(context.contains("duplicate-detection required=\"true\""));
    assert!(context.contains("duplicate-detector"));
}

#[test]
fn test_build_duplicate_detection_context_above_threshold() {
    use crate::store::mock::MockStore;

    // Create 30 entries (above threshold of 20)
    let entries: Vec<Entry> = (0..30)
        .map(|i| Entry::new(format!("entry-{i}"), format!("Entry content {i}")))
        .collect();
    let store = MockStore::with_entries(entries);

    let mut config = Config::default();
    let mut hook_config = crate::config::HookConfig::default();
    hook_config.stop.duplicate_detection_enabled = true;
    hook_config.stop.duplicate_detection_threshold = 20;
    config.hooks = Some(hook_config);

    // Should return Some since count (30) >= threshold (20)
    let result = build_duplicate_detection_context(&store, &config);
    assert!(result.is_some());
    let context = result.unwrap();
    assert!(context.contains("duplicate-detection required=\"true\""));
    assert!(context.contains("30 entries"));
}

#[test]
fn test_build_duplicate_detection_context_threshold_zero() {
    use crate::store::mock::MockStore;

    let store = MockStore::new();
    let mut config = Config::default();
    let mut hook_config = crate::config::HookConfig::default();
    hook_config.stop.duplicate_detection_enabled = true;
    hook_config.stop.duplicate_detection_threshold = 0; // Invalid threshold
    config.hooks = Some(hook_config);

    // Should return error context since threshold = 0 is invalid
    let result = build_duplicate_detection_context(&store, &config);
    assert!(
        result.is_some(),
        "threshold=0 should return error context, not None"
    );
    let context = result.unwrap();
    assert!(
        context.contains("duplicate-detection-error"),
        "Error context should indicate error: {context}"
    );
    assert!(
        context.contains("threshold"),
        "Error context should mention threshold: {context}"
    );
}

