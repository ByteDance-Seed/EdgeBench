#[test]
fn test_default_priority() {
    assert_eq!(default_priority(), 2);
}

#[test]
fn test_default_search_limit() {
    assert_eq!(default_search_limit(), 10);
}

#[test]
fn test_default_observation_type() {
    assert_eq!(default_observation_type(), "general");
}

#[test]
fn test_default_skill_type() {
    assert_eq!(default_skill_type(), "command");
}

#[test]
fn test_default_scope_all() {
    assert_eq!(default_scope_all(), "all");
}

#[test]
fn test_task_create_request_defaults() {
    let json = r#"{"title": "Fix bug"}"#;
    let req: TaskCreateRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.title, "Fix bug");
    assert_eq!(req.priority, 2);
    assert_eq!(req.task_type, "task");
    assert!(req.description.is_none());
    assert!(req.labels.is_none());
    assert!(req.notes.is_none());
    assert!(req.blocked_by.is_none());
}

#[test]
fn test_search_request_with_filter() {
    let json = r#"{"query": "database", "limit": 5, "doc_type": "task"}"#;
    let req: SearchRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.limit, 5);
    assert_eq!(req.doc_type, Some("task".to_string()));
}

#[test]
fn test_observe_request_defaults() {
    let json = r#"{"content": "Fixed the parser bug"}"#;
    let req: ObserveRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.content, "Fixed the parser bug");
    assert_eq!(req.observation_type, "general");
    assert_eq!(req.scope, "project"); // Default scope
    assert!(req.source_tool.is_none());
    assert!(req.tags.is_none());
}

#[test]
fn test_rule_create_request() {
    let json = r#"{"content": "Use async/await", "paths": "src/**/*.rs", "tags": "rust"}"#;
    let req: RuleCreateRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.content, "Use async/await");
    assert_eq!(req.paths, Some("src/**/*.rs".to_string()));
    assert_eq!(req.tags, Some("rust".to_string()));
}

#[test]
fn test_task_notes_request_with_type() {
    let json = r#"{"id": "cas-1234", "note": "API is slow", "note_type": "blocker"}"#;
    let req: TaskNotesRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.note_type, "blocker");
}

#[test]
fn test_subagent_context_request_defaults() {
    let json = r#"{"task_id": "cas-1234"}"#;
    let req: SubAgentContextRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.task_id, "cas-1234");
    assert_eq!(req.max_tokens, 2000);
    assert!(req.include_memories);
}

#[test]
fn test_reindex_request_defaults() {
    let json = r#"{}"#;
    let req: ReindexRequest = serde_json::from_str(json).unwrap();
    assert!(!req.bm25);
    assert!(!req.embeddings);
    assert!(!req.missing_only);
}

#[test]
fn test_id_request() {
    let json = r#"{"id": "2024-01-15-001"}"#;
    let req: IdRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.id, "2024-01-15-001");
}

#[test]
fn test_limit_request_defaults() {
    let json = r#"{}"#;
    let req: LimitRequest = serde_json::from_str(json).unwrap();
    assert!(req.limit.is_none());
    assert_eq!(req.scope, "all"); // Default scope for list
}

#[test]
fn test_memory_tier_request() {
    let json = r#"{"id": "2024-01-15-001", "tier": "cold"}"#;
    let req: MemoryTierRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.id, "2024-01-15-001");
    assert_eq!(req.tier, "cold");
}

#[test]
fn test_opinion_weaken_request() {
    let json = r#"{"id": "2024-01-15-001", "evidence": "Edge case found"}"#;
    let req: OpinionWeakenRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.id, "2024-01-15-001");
    assert_eq!(req.evidence, "Edge case found");
}
