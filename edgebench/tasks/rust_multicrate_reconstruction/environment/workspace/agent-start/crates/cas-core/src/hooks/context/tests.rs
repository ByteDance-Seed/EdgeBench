use crate::hooks::context::{
    BasicContextScorer, ContextQuery, ContextScorer, RuleMatchCache, estimate_tokens,
    is_factory_participant, rule_matches_path, token_display, truncate,
};
use cas_types::{AgentRole, Entry, EntryType, Rule};

#[test]
fn test_estimate_tokens() {
    assert_eq!(estimate_tokens("test"), 1);
    assert_eq!(estimate_tokens("12345678"), 2);
    assert_eq!(estimate_tokens(""), 0);
}

#[test]
fn test_token_display() {
    assert_eq!(token_display(50), "~50tk");
    assert_eq!(token_display(150), "~150tk");
    assert_eq!(token_display(1500), "~1.5k tk");
}

#[test]
fn test_truncate() {
    assert_eq!(truncate("short", 10), "short");
    assert_eq!(truncate("this is a long string", 10), "this is...");
}


#[test]
fn test_rule_matches_path() {
    let mut rule = Rule {
        paths: String::new(),
        ..Default::default()
    };
    assert!(rule_matches_path(&rule, "/any/path"));

    rule.paths = "src/**".to_string();
    assert!(rule_matches_path(&rule, "/project/src/main.rs"));

    rule.paths = "lib/cas_cloud/**".to_string();
    assert!(rule_matches_path(&rule, "/project/lib/cas_cloud/web"));
}

#[test]
fn test_basic_context_scorer() {
    let entry = Entry {
        entry_type: EntryType::Learning,
        created: chrono::Utc::now(),
        ..Default::default()
    };

    let score = BasicContextScorer::calculate_score(&entry);
    assert!(score > 0.0);

    // Learning should score higher than Observation
    let obs = Entry {
        entry_type: EntryType::Observation,
        created: chrono::Utc::now(),
        ..Default::default()
    };

    assert!(
        BasicContextScorer::calculate_score(&entry) > BasicContextScorer::calculate_score(&obs)
    );
}

#[test]
fn test_context_query_to_string() {
    let query = ContextQuery {
        task_titles: vec!["Fix bug in parser".to_string()],
        cwd: "/home/user/my-project".to_string(),
        user_prompt: Some("help me debug".to_string()),
        recent_files: vec![],
    };

    let query_str = query.to_query_string();
    assert!(query_str.contains("Fix bug in parser"));
    assert!(query_str.contains("help me debug"));
    assert!(query_str.contains("my-project"));
}



#[test]
fn test_rule_match_cache() {
    let rule1 = Rule {
        id: "rule-1".to_string(),
        paths: "src/**".to_string(),
        ..Default::default()
    };

    let rule2 = Rule {
        id: "rule-2".to_string(),
        paths: "lib/**".to_string(),
        ..Default::default()
    };

    let rule3 = Rule {
        id: "rule-3".to_string(),
        paths: String::new(), // Matches everywhere
        ..Default::default()
    };

    let rules = vec![rule1.clone(), rule2.clone(), rule3.clone()];
    let cache = RuleMatchCache::build(&rules, "/project/src/main.rs");

    // Rule1 should match (src/**)
    assert!(cache.matches(&rule1, "/project/src/main.rs"));
    // Rule2 should not match (lib/**)
    assert!(!cache.matches(&rule2, "/project/src/main.rs"));
    // Rule3 should match (no path restriction)
    assert!(cache.matches(&rule3, "/project/src/main.rs"));

    // Cache should be valid for same cwd
    assert!(cache.is_valid_for("/project/src/main.rs"));
    // Cache should not be valid for different cwd
    assert!(!cache.is_valid_for("/other/path"));

    // Cache should have 3 entries
    assert_eq!(cache.len(), 3);
}

#[test]
fn test_rule_match_cache_fallback() {
    let rule = Rule {
        id: "rule-1".to_string(),
        paths: "src/**".to_string(),
        ..Default::default()
    };

    // Empty cache
    let cache = RuleMatchCache::new();
    assert!(cache.is_empty());

    // Should fall back to direct matching when cwd doesn't match cache
    // This also tests the behavior when the cache was built for a different cwd
    assert!(cache.matches(&rule, "/project/src/main.rs"));
}

#[test]
fn test_session_aware_access_boost() {
    let now = chrono::Utc::now();

    // Entry with recent access (within 1 hour) should get high boost
    let recent_entry = Entry {
        id: "recent".to_string(),
        entry_type: EntryType::Learning,
        created: now - chrono::Duration::days(7),
        last_accessed: Some(now - chrono::Duration::minutes(30)),
        access_count: 1,
        ..Default::default()
    };

    // Entry accessed 12 hours ago should get medium boost
    let medium_entry = Entry {
        id: "medium".to_string(),
        entry_type: EntryType::Learning,
        created: now - chrono::Duration::days(7),
        last_accessed: Some(now - chrono::Duration::hours(12)),
        access_count: 1,
        ..Default::default()
    };

    // Entry never accessed should get no boost
    let no_access_entry = Entry {
        id: "no_access".to_string(),
        entry_type: EntryType::Learning,
        created: now - chrono::Duration::days(7),
        last_accessed: None,
        access_count: 0,
        ..Default::default()
    };

    let recent_score = BasicContextScorer::calculate_score(&recent_entry);
    let medium_score = BasicContextScorer::calculate_score(&medium_entry);
    let no_access_score = BasicContextScorer::calculate_score(&no_access_entry);

    // Recent access should give highest score
    assert!(
        recent_score > medium_score,
        "Recent access should score higher than medium: {recent_score} vs {medium_score}"
    );
    assert!(
        medium_score > no_access_score,
        "Medium access should score higher than no access: {medium_score} vs {no_access_score}"
    );
}

#[test]
fn test_is_factory_participant() {
    assert!(is_factory_participant(Some(AgentRole::Worker)));
    assert!(is_factory_participant(Some(AgentRole::Supervisor)));
    assert!(!is_factory_participant(Some(AgentRole::Standard)));
    assert!(!is_factory_participant(Some(AgentRole::Director)));
    assert!(!is_factory_participant(None));
}
