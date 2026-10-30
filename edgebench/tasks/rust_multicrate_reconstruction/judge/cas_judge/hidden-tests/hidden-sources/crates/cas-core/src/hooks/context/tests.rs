#[test]
fn test_truncate_handles_unicode_boundary() {
    let input = format!("{}✅ done", "a".repeat(99));
    assert_eq!(truncate(&input, 103), format!("{}...", "a".repeat(99)));
}

#[test]
fn test_basic_scorer_trait() {
    let scorer = BasicContextScorer;
    assert_eq!(scorer.name(), "basic");

    let entries = vec![
        Entry {
            id: "1".to_string(),
            entry_type: EntryType::Learning,
            created: chrono::Utc::now(),
            ..Default::default()
        },
        Entry {
            id: "2".to_string(),
            entry_type: EntryType::Observation,
            created: chrono::Utc::now(),
            ..Default::default()
        },
    ];

    let context = ContextQuery::default();
    let scored = scorer.score_entries(&entries, &context);

    assert_eq!(scored.len(), 2);
    // Learning should be first (higher score)
    assert_eq!(scored[0].0.id, "1");
}

#[test]
fn test_context_query_has_content() {
    // Empty query has no content
    let empty = ContextQuery::default();
    assert!(!empty.has_content());

    // Query with task titles has content
    let with_task = ContextQuery {
        task_titles: vec!["Fix bug".to_string()],
        ..Default::default()
    };
    assert!(with_task.has_content());

    // Query with user prompt has content
    let with_prompt = ContextQuery {
        user_prompt: Some("help me debug".to_string()),
        ..Default::default()
    };
    assert!(with_prompt.has_content());

    // Query with only cwd doesn't have content (not semantic)
    let with_cwd = ContextQuery {
        cwd: "/project".to_string(),
        ..Default::default()
    };
    assert!(!with_cwd.has_content());
}
