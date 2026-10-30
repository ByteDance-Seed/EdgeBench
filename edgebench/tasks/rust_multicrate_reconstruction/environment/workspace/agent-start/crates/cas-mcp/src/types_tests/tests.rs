use crate::types::*;

#[test]
fn test_team_request_default() {
    let req: TeamRequest = serde_json::from_str(r#"{"action": "list"}"#).unwrap();
    assert_eq!(req.action, "list");
    assert!(req.team_id.is_none());
    assert!(req.limit.is_none());
}



#[test]
fn test_system_request_reindex() {
    let req: SystemRequest = serde_json::from_str(
        r#"{
            "action": "reindex",
            "bm25": true,
            "embeddings": false
        }"#,
    )
    .unwrap();
    assert_eq!(req.action, "reindex");
    assert_eq!(req.bm25, Some(true));
    assert_eq!(req.embeddings, Some(false));
}

#[test]
fn test_factory_request_spawn() {
    let req: FactoryRequest = serde_json::from_str(
        r#"{
            "action": "spawn_workers",
            "count": 3
        }"#,
    )
    .unwrap();
    assert_eq!(req.action, "spawn_workers");
    assert_eq!(req.count, Some(3));
    assert!(req.worker_names.is_none());
    assert!(req.target.is_none());
    assert!(req.message.is_none());
}

#[test]
fn test_system_request_report_bug() {
    let req: SystemRequest = serde_json::from_str(
        r#"{
            "action": "report_cas_bug",
            "title": "Search fails silently",
            "description": "When search returns no results, no error is shown",
            "expected": "Should show 'no results' message",
            "actual": "Shows nothing"
        }"#,
    )
    .unwrap();
    assert_eq!(req.action, "report_cas_bug");
    assert_eq!(req.title, Some("Search fails silently".to_string()));
    assert_eq!(
        req.description,
        Some("When search returns no results, no error is shown".to_string())
    );
    assert_eq!(
        req.expected,
        Some("Should show 'no results' message".to_string())
    );
    assert_eq!(req.actual, Some("Shows nothing".to_string()));
}

#[test]
fn test_spec_request_default() {
    let req: SpecRequest = serde_json::from_str(r#"{"action": "list"}"#).unwrap();
    assert_eq!(req.action, "list");
    assert!(req.id.is_none());
    assert!(req.title.is_none());
    assert!(req.spec_type.is_none());
}

#[test]
fn test_spec_request_create() {
    let req: SpecRequest = serde_json::from_str(
        r#"{
            "action": "create",
            "title": "User Authentication Epic",
            "summary": "Add OAuth2 login flow",
            "spec_type": "epic",
            "goals": "Enable social login,Improve security",
            "acceptance_criteria": "Users can log in with Google,Users can log in with GitHub"
        }"#,
    )
    .unwrap();
    assert_eq!(req.action, "create");
    assert_eq!(req.title, Some("User Authentication Epic".to_string()));
    assert_eq!(req.summary, Some("Add OAuth2 login flow".to_string()));
    assert_eq!(req.spec_type, Some("epic".to_string()));
    assert_eq!(
        req.goals,
        Some("Enable social login,Improve security".to_string())
    );
    assert_eq!(
        req.acceptance_criteria,
        Some("Users can log in with Google,Users can log in with GitHub".to_string())
    );
}

#[test]
fn test_spec_request_supersede() {
    let req: SpecRequest = serde_json::from_str(
        r#"{
            "action": "supersede",
            "id": "spec-abc123",
            "supersedes_id": "spec-old456",
            "new_version": true
        }"#,
    )
    .unwrap();
    assert_eq!(req.action, "supersede");
    assert_eq!(req.id, Some("spec-abc123".to_string()));
    assert_eq!(req.supersedes_id, Some("spec-old456".to_string()));
    assert_eq!(req.new_version, Some(true));
}
