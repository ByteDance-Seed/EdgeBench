use crate::mcp::tools::types::defaults::*;
use crate::mcp::tools::types::*;

// =========================================================================
// Default value tests
// =========================================================================

#[test]
fn test_default_entry_type() {
    assert_eq!(default_entry_type(), "learning");
}

#[test]
fn test_default_importance() {
    assert_eq!(default_importance(), 0.5);
}

#[test]
fn test_default_recent() {
    assert_eq!(default_recent(), 10);
}


#[test]
fn test_default_task_type() {
    assert_eq!(default_task_type(), "task");
}




#[test]
fn test_default_dep_type() {
    assert_eq!(default_dep_type(), "blocks");
}

#[test]
fn test_default_note_type() {
    assert_eq!(default_note_type(), "progress");
}

#[test]
fn test_default_subagent_tokens() {
    assert_eq!(default_subagent_tokens(), 2000);
}

#[test]
fn test_default_scope_project() {
    assert_eq!(default_scope_project(), "project");
}

#[test]
fn test_default_scope_global() {
    assert_eq!(default_scope_global(), "global");
}


// =========================================================================
// Deserialization tests with defaults
// =========================================================================

#[test]
fn test_remember_request_defaults() {
    let json = r#"{"content": "Test content"}"#;
    let req: RememberRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.content, "Test content");
    assert_eq!(req.entry_type, "learning");
    assert_eq!(req.importance, 0.5);
    assert_eq!(req.scope, "project"); // Default scope
    assert!(req.tags.is_none());
    assert!(req.title.is_none());
}

#[test]
fn test_remember_request_full() {
    let json = r#"{
        "content": "Important fact",
        "entry_type": "preference",
        "tags": "rust,cli",
        "title": "CLI Preference",
        "importance": 0.9,
        "scope": "global"
    }"#;
    let req: RememberRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.entry_type, "preference");
    assert_eq!(req.importance, 0.9);
    assert_eq!(req.scope, "global");
    assert_eq!(req.tags, Some("rust,cli".to_string()));
    assert_eq!(req.title, Some("CLI Preference".to_string()));
}


#[test]
fn test_task_create_request_full() {
    let json = r#"{
        "title": "Implement feature",
        "description": "Add new login flow",
        "priority": 1,
        "task_type": "feature",
        "labels": "auth,ui",
        "notes": "Started planning",
        "blocked_by": "cas-1234"
    }"#;
    let req: TaskCreateRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.title, "Implement feature");
    assert_eq!(req.priority, 1);
    assert_eq!(req.task_type, "feature");
    assert_eq!(req.description, Some("Add new login flow".to_string()));
    assert_eq!(req.blocked_by, Some("cas-1234".to_string()));
}

#[test]
fn test_search_request_defaults() {
    let json = r#"{"query": "rust async"}"#;
    let req: SearchRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.query, "rust async");
    assert_eq!(req.limit, 10);
    assert_eq!(req.scope, "all"); // Default scope for search
    assert!(req.doc_type.is_none());
}




#[test]
fn test_skill_create_request_defaults() {
    let json = r#"{
        "name": "Format Code",
        "description": "Run cargo fmt",
        "invocation": "cargo fmt"
    }"#;
    let req: SkillCreateRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.name, "Format Code");
    assert_eq!(req.skill_type, "command");
    assert_eq!(req.scope, "global"); // Default scope for skills
    assert!(req.tags.is_none());
}

#[test]
fn test_dependency_request_defaults() {
    let json = r#"{"from_id": "cas-1", "to_id": "cas-2"}"#;
    let req: DependencyRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.from_id, "cas-1");
    assert_eq!(req.to_id, "cas-2");
    assert_eq!(req.dep_type, "blocks");
}

#[test]
fn test_task_show_request_defaults() {
    let json = r#"{"id": "cas-1234"}"#;
    let req: TaskShowRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.id, "cas-1234");
    assert!(req.with_deps);
}

#[test]
fn test_task_notes_request_defaults() {
    let json = r#"{"id": "cas-1234", "note": "Made progress"}"#;
    let req: TaskNotesRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.id, "cas-1234");
    assert_eq!(req.note, "Made progress");
    assert_eq!(req.note_type, "progress");
}




#[test]
fn test_reindex_request_full() {
    let json = r#"{"bm25": true, "embeddings": true, "missing_only": true}"#;
    let req: ReindexRequest = serde_json::from_str(json).unwrap();
    assert!(req.bm25);
    assert!(req.embeddings);
    assert!(req.missing_only);
}

#[test]
fn test_maintenance_run_request_defaults() {
    let json = r#"{}"#;
    let req: MaintenanceRunRequest = serde_json::from_str(json).unwrap();
    assert!(!req.force);
}



#[test]
fn test_limit_request_with_value() {
    let json = r#"{"limit": 25}"#;
    let req: LimitRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.limit, Some(25));
}


#[test]
fn test_opinion_reinforce_request() {
    let json = r#"{"id": "2024-01-15-001", "evidence": "Performance tests confirmed"}"#;
    let req: OpinionReinforceRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.id, "2024-01-15-001");
    assert_eq!(req.evidence, "Performance tests confirmed");
}


#[test]
fn test_opinion_contradict_request() {
    let json = r#"{"id": "2024-01-15-001", "evidence": "Completely wrong approach"}"#;
    let req: OpinionContradictRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.id, "2024-01-15-001");
    assert_eq!(req.evidence, "Completely wrong approach");
}
