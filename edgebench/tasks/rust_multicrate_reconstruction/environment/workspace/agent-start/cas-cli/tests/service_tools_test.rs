//! Tests for MCP service tools
//!
//! Verifies that the 8 meta-tools correctly delegate to underlying implementations

use cas::mcp::tools::service::*;
use serde_json::json;

// ============================================================================
// Request Type Tests
// ============================================================================

#[test]
fn test_memory_request_deserialization() {
    let json = json!({
        "action": "remember",
        "content": "Test content",
        "entry_type": "learning",
        "importance": 0.8
    });

    let req: MemoryRequest = serde_json::from_value(json).unwrap();
    assert_eq!(req.action, "remember");
    assert_eq!(req.content, Some("Test content".to_string()));
    assert_eq!(req.entry_type, Some("learning".to_string()));
    assert_eq!(req.importance, Some(0.8));
}

#[test]
fn test_memory_request_minimal() {
    let json = json!({
        "action": "get",
        "id": "2024-01-01-001"
    });

    let req: MemoryRequest = serde_json::from_value(json).unwrap();
    assert_eq!(req.action, "get");
    assert_eq!(req.id, Some("2024-01-01-001".to_string()));
    assert!(req.content.is_none());
}

#[test]
fn test_task_request_create() {
    let json = json!({
        "action": "create",
        "title": "Fix bug",
        "priority": 1,
        "task_type": "bug"
    });

    let req: TaskRequest = serde_json::from_value(json).unwrap();
    assert_eq!(req.action, "create");
    assert_eq!(req.title, Some("Fix bug".to_string()));
    assert_eq!(req.priority, Some(1));
    assert_eq!(req.task_type, Some("bug".to_string()));
}

#[test]
fn test_task_request_notes() {
    let json = json!({
        "action": "notes",
        "id": "cas-1234",
        "notes": "Made progress on implementation",
        "note_type": "progress"
    });

    let req: TaskRequest = serde_json::from_value(json).unwrap();
    assert_eq!(req.action, "notes");
    assert_eq!(req.id, Some("cas-1234".to_string()));
    assert_eq!(
        req.notes,
        Some("Made progress on implementation".to_string())
    );
    assert_eq!(req.note_type, Some("progress".to_string()));
}

#[test]
fn test_task_request_dependency() {
    let json = json!({
        "action": "dep_add",
        "id": "cas-1234",
        "to_id": "cas-5678",
        "dep_type": "blocks"
    });

    let req: TaskRequest = serde_json::from_value(json).unwrap();
    assert_eq!(req.action, "dep_add");
    assert_eq!(req.id, Some("cas-1234".to_string()));
    assert_eq!(req.to_id, Some("cas-5678".to_string()));
    assert_eq!(req.dep_type, Some("blocks".to_string()));
}

#[test]
fn test_rule_request_create() {
    let json = json!({
        "action": "create",
        "content": "Always use async/await",
        "paths": "src/**/*.rs",
        "tags": "rust,async"
    });

    let req: RuleRequest = serde_json::from_value(json).unwrap();
    assert_eq!(req.action, "create");
    assert_eq!(req.content, Some("Always use async/await".to_string()));
    assert_eq!(req.paths, Some("src/**/*.rs".to_string()));
    assert_eq!(req.tags, Some("rust,async".to_string()));
}


#[test]
fn test_agent_request_register() {
    let json = json!({
        "action": "register",
        "name": "Test Agent",
        "agent_type": "primary",
        "session_id": "session-123"
    });

    let req: AgentRequest = serde_json::from_value(json).unwrap();
    assert_eq!(req.action, "register");
    assert_eq!(req.name, Some("Test Agent".to_string()));
    assert_eq!(req.agent_type, Some("primary".to_string()));
    assert_eq!(req.session_id, Some("session-123".to_string()));
}

#[test]
fn test_agent_request_loop_start() {
    let json = json!({
        "action": "loop_start",
        "prompt": "Run tests until green",
        "completion_promise": "All tests pass",
        "max_iterations": 10,
        "session_id": "session-123"
    });

    let req: AgentRequest = serde_json::from_value(json).unwrap();
    assert_eq!(req.action, "loop_start");
    assert_eq!(req.prompt, Some("Run tests until green".to_string()));
    assert_eq!(req.completion_promise, Some("All tests pass".to_string()));
    assert_eq!(req.max_iterations, Some(10));
}

#[test]
fn test_search_context_request_search() {
    let json = json!({
        "action": "search",
        "query": "authentication",
        "doc_type": "entry",
        "limit": 20
    });

    let req: SearchContextRequest = serde_json::from_value(json).unwrap();
    assert_eq!(req.action, "search");
    assert_eq!(req.query, Some("authentication".to_string()));
    assert_eq!(req.doc_type, Some("entry".to_string()));
    assert_eq!(req.limit, Some(20));
}

#[test]
fn test_search_context_request_observe() {
    let json = json!({
        "action": "observe",
        "content": "Fixed the parser bug",
        "observation_type": "bugfix",
        "tags": "parser,fix"
    });

    let req: SearchContextRequest = serde_json::from_value(json).unwrap();
    assert_eq!(req.action, "observe");
    assert_eq!(req.content, Some("Fixed the parser bug".to_string()));
    assert_eq!(req.observation_type, Some("bugfix".to_string()));
    assert_eq!(req.tags, Some("parser,fix".to_string()));
}

#[test]
fn test_system_request_reindex() {
    let json = json!({
        "action": "reindex",
        "bm25": true,
        "embeddings": true,
        "missing_only": false
    });

    let req: SystemRequest = serde_json::from_value(json).unwrap();
    assert_eq!(req.action, "reindex");
    assert_eq!(req.bm25, Some(true));
    assert_eq!(req.embeddings, Some(true));
    assert_eq!(req.missing_only, Some(false));
}

#[test]
fn test_system_request_defaults() {
    let json = json!({
        "action": "doctor"
    });

    let req: SystemRequest = serde_json::from_value(json).unwrap();
    assert_eq!(req.action, "doctor");
    assert!(req.bm25.is_none());
    assert!(req.embeddings.is_none());
    assert!(req.force.is_none());
}

// ============================================================================
// Action Validation Tests
// ============================================================================

#[test]
fn test_all_memory_actions_recognized() {
    let actions = vec![
        "remember",
        "get",
        "list",
        "update",
        "delete",
        "archive",
        "unarchive",
        "helpful",
        "harmful",
        "recent",
        "set_tier",
        "opinion_reinforce",
        "opinion_weaken",
        "opinion_contradict",
    ];

    for action in actions {
        let json = json!({ "action": action });
        let req: MemoryRequest = serde_json::from_value(json).unwrap();
        assert_eq!(req.action, action);
    }
}

#[test]
fn test_all_task_actions_recognized() {
    let actions = vec![
        "create",
        "show",
        "update",
        "start",
        "close",
        "reopen",
        "delete",
        "list",
        "ready",
        "blocked",
        "notes",
        "dep_add",
        "dep_remove",
        "dep_list",
        "claim",
        "release",
        "transfer",
        "available",
        "mine",
    ];

    for action in actions {
        let json = json!({ "action": action });
        let req: TaskRequest = serde_json::from_value(json).unwrap();
        assert_eq!(req.action, action);
    }
}




#[test]
fn test_all_search_actions_recognized() {
    let actions = vec![
        "search",
        "context",
        "context_for_subagent",
        "observe",
        "entity_list",
        "entity_show",
        "entity_extract",
    ];

    for action in actions {
        let json = json!({ "action": action });
        let req: SearchContextRequest = serde_json::from_value(json).unwrap();
        assert_eq!(req.action, action);
    }
}

#[test]
fn test_all_system_actions_recognized() {
    let actions = vec![
        "doctor",
        "stats",
        "info",
        "reindex",
        "maintenance_run",
        "maintenance_status",
    ];

    for action in actions {
        let json = json!({ "action": action });
        let req: SystemRequest = serde_json::from_value(json).unwrap();
        assert_eq!(req.action, action);
    }
}

// ============================================================================
// Edge Case Tests
// ============================================================================

#[test]
fn test_empty_optional_fields() {
    let json = json!({
        "action": "remember",
        "content": "Test"
    });

    let req: MemoryRequest = serde_json::from_value(json).unwrap();
    assert!(req.tags.is_none());
    assert!(req.title.is_none());
    assert!(req.importance.is_none());
    assert!(req.tier.is_none());
    assert!(req.scope.is_none());
}

#[test]
fn test_task_claim_with_duration() {
    let json = json!({
        "action": "claim",
        "id": "cas-1234",
        "duration_secs": 1800,
        "reason": "Working on implementation"
    });

    let req: TaskRequest = serde_json::from_value(json).unwrap();
    assert_eq!(req.duration_secs, Some(1800));
    assert_eq!(req.reason, Some("Working on implementation".to_string()));
}

#[test]
fn test_task_transfer() {
    let json = json!({
        "action": "transfer",
        "id": "cas-1234",
        "to_agent": "agent-5678",
        "notes": "Handoff notes here"
    });

    let req: TaskRequest = serde_json::from_value(json).unwrap();
    assert_eq!(req.to_agent, Some("agent-5678".to_string()));
    assert_eq!(req.notes, Some("Handoff notes here".to_string()));
}

